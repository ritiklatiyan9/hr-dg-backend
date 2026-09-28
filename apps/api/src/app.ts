import { Tracking } from "./tracking.js";
import Fastify, { type FastifyRequest } from "fastify";
import cookie from "@fastify/cookie";
import helmet from "@fastify/helmet";
import rateLimit from "@fastify/rate-limit";
import staticFiles from "@fastify/static";
import { resolve } from "node:path";
import { Redis } from "ioredis";
import { boundedQuery } from "./query-cost.js";
import mercurius from "mercurius";
import { readFile } from "node:fs/promises";
import {
  GraphQLError,
  GraphQLScalarType,
  Kind,
  type ValidationRule,
} from "graphql";
import { z, ZodError } from "zod";
import type pg from "pg";
import type { Config } from "../../../packages/config/src/index.js";
import {
  requireActor,
  fail,
  type Actor,
} from "../../../packages/authz/src/index.js";
import { AuthService, loginInput, newPassword } from "./auth.js";
import { Operations } from "./operations.js";
import { Dashboard } from "./dashboard.js";
import { analyticsTools } from "../../../packages/contracts/analytics.js";
import { decrypt, encrypt } from "./security.js";
import { uploadFile, downloadFile } from "./files.js";

declare module "fastify" {
  interface FastifyRequest {
    actor: Actor | null;
  }
}
export async function createApp(
  config: Config,
  businessPool: pg.Pool,
  authPool: pg.Pool,
  logging = true,
) {
  const app = Fastify({
    bodyLimit: 64 * 1024,
    requestTimeout: 15_000,
    // An idle socket timeout also fires while a valid handler is awaiting DB
    // results. Destroying that socket produces a proxy 502 instead of an API
    // response. Request receipt and individual DB queries remain bounded.
    connectionTimeout: 0,
    logger: logging
      ? {
          level: "info",
          redact: {
            paths: [
              "req.headers.authorization",
              "req.headers.cookie",
              'res.headers["set-cookie"]',
              "password",
              "token",
              "secret",
              "body",
            ],
            remove: true,
          },
          serializers: {
            req: (r) => ({
              method: r.method,
              url: r.url?.split("?")[0],
              id: r.id,
            }),
            res: (r) => ({ statusCode: r.statusCode }),
          },
        }
      : false,
  });
  const auth = new AuthService(authPool, config),
    domain = new Dashboard(businessPool);
  const tracking = new Tracking(businessPool);
  app.decorateRequest("actor", null);
  await app.register(cookie);
  await app.register(helmet);
  const limiter =
    config.NODE_ENV === "production"
      ? new Redis(config.REDIS_URL, {
          connectTimeout: 3000,
          commandTimeout: 3000,
          maxRetriesPerRequest: 1,
        })
      : undefined;
  limiter?.on("error", () => app.log.error("Rate-limit storage unavailable"));
  app.addHook("onClose", async () => {
    limiter?.disconnect();
  });
  await app.register(rateLimit, {
    ...(limiter ? { redis: limiter } : {}),
    skipOnError: false,
    global: true,
    hook: "preHandler",
    keyGenerator: (req) =>
      req.actor ? `${req.actor.organizationId}:${req.actor.id}` : req.ip,
    max: 120,
    timeWindow: "1 minute",
  });
  app.addHook("onRequest", async (req, reply) => {
    reply.header("Cache-Control", "no-store");
    if (req.headers.origin && req.headers.origin !== config.WEB_ORIGIN)
      fail("CSRF_INVALID", "Origin not permitted", 403);
    const bearer = req.headers.authorization?.startsWith("Bearer ")
      ? req.headers.authorization.slice(7)
      : undefined;
    const credential = bearer ?? req.cookies.dg_session;
    if (credential) req.actor = await auth.lookup(credential);
    // Cookie-authenticated writes always require origin + session-bound CSRF.
    if (
      req.method !== "GET" &&
      req.method !== "HEAD" &&
      req.cookies.dg_session &&
      !bearer
    ) {
      if (req.headers.origin !== config.WEB_ORIGIN)
        fail("CSRF_INVALID", "Origin required", 403);
      if (req.actor)
        auth.csrf(req.actor, req.headers["x-csrf-token"] as string | undefined);
    }
  });
  app.setErrorHandler((err, req, reply) => {
    if (err instanceof ZodError)
      return reply
        .code(400)
        .send({ code: "BAD_INPUT", message: "Check the submitted fields" });
    const e = err as Error & { code?: string; statusCode?: number };
    const status = e.statusCode ?? 500;
    if (status >= 500)
      req.log.error(
        { code: e.code ?? "INTERNAL_ERROR", requestId: req.id },
        "Request failed",
      );
    return reply.code(status).send({
      code: status >= 500 ? "INTERNAL_ERROR" : (e.code ?? "BAD_REQUEST"),
      message: status >= 500 ? "The request could not be completed" : e.message,
    });
  });
  const authenticated = (req: FastifyRequest) => {
    if (!req.actor) fail("UNAUTHENTICATED", "Please sign in", 401);
    const pv = req.headers["x-permission-version"];
    if (pv && pv !== String(req.actor.permissionVersion))
      fail("SCOPE_CHANGED", "Access changed. Reload.", 409);
    return req.actor;
  };
  const browserInput = (req: FastifyRequest) => {
    if (
      req.headers["x-client"] === "web" &&
      req.headers.origin !== config.WEB_ORIGIN
    )
      fail("CSRF_INVALID", "Origin required", 403);
  };
  app.get("/health/live", async () => ({
    status: "ok",
    // Public source revision lets deployment checks distinguish a healthy old
    // instance from the release that contains the fix. No configuration data.
    revision: /^[a-f0-9]{40}$/.test(process.env.RENDER_GIT_COMMIT ?? "")
      ? process.env.RENDER_GIT_COMMIT
      : undefined,
  }));
  app.post("/analytics/tools/:tool", async (req) => {
    const { tool } = z
      .object({ tool: z.enum(analyticsTools) })
      .parse(req.params);
    const { siteId, input } = z
      .object({ siteId: z.uuid(), input: z.unknown() })
      .strict()
      .parse(req.body);
    return domain.analyticsSnapshot(
      requireActor(authenticated(req)),
      siteId,
      input,
      tool,
    );
  });
  app.get("/health/ready", async () => {
    await Promise.all([
      businessPool.query("SELECT 1"),
      authPool.query("SELECT 1"),
    ]);
    return { status: "ready" };
  });
  app.post(
    "/auth/login",
    { config: { rateLimit: { max: 8, timeWindow: "1 minute" } } },
    async (req, reply) => {
      const submitted = loginInput
        .omit({ organizationId: true })
        .parse(req.body);
      const input = {
        ...submitted,
        organizationId: config.LOGIN_ORGANIZATION_ID,
      };
      if (input.kind === "web" && req.headers.origin !== config.WEB_ORIGIN)
        fail("CSRF_INVALID", "Origin required", 403);
      const result = await auth.login(input);
      if (input.kind === "web") {
        const options = {
          secure: config.COOKIE_SECURE === "true",
          sameSite: "strict" as const,
          path: "/",
          maxAge: 8 * 3600,
        };
        reply.setCookie("dg_session", result.accessToken, {
          ...options,
          httpOnly: true,
        });
        reply.setCookie("dg_csrf", result.csrfToken, {
          ...options,
          httpOnly: false,
        });
        return {
          csrfToken: result.csrfToken,
          mfaRequired: result.mfaRequired,
          enrollmentRequired: result.enrollmentRequired,
        };
      }
      return result;
    },
  );
  app.get("/auth/session", async (req) => {
    const a = authenticated(req);
    const u = (
      await authPool.query("SELECT mfa_enabled FROM auth.users WHERE id=$1", [
        a.id,
      ])
    ).rows[0];
    return {
      mfaRequired: a.requiresMfa && !a.mfaVerified,
      enrollmentRequired: a.requiresMfa && !u.mfa_enabled,
    };
  });
  app.post(
    "/auth/mfa/setup",
    { config: { rateLimit: { max: 5, timeWindow: "1 minute" } } },
    async (req) => auth.setupMfa(authenticated(req)),
  );
  app.post(
    "/auth/mfa/verify",
    { config: { rateLimit: { max: 5, timeWindow: "1 minute" } } },
    async (req) => {
      await auth.verifyMfa(
        authenticated(req),
        z.object({ code: z.string().regex(/^\d{6}$/) }).parse(req.body).code,
      );
      return { ok: true };
    },
  );
  app.post(
    "/auth/refresh",
    { config: { rateLimit: { max: 30, timeWindow: "1 minute" } } },
    async (req) =>
      auth.refresh(
        z.object({ refreshToken: z.string().min(32).max(128) }).parse(req.body)
          .refreshToken,
      ),
  );
  app.post("/auth/logout", async (req, reply) => {
    await auth.logout(authenticated(req));
    reply
      .clearCookie("dg_session", { path: "/" })
      .clearCookie("dg_csrf", { path: "/" });
    return { ok: true };
  });
  app.post("/auth/logout-all", async (req, reply) => {
    await auth.logout(requireActor(req.actor), true);
    reply
      .clearCookie("dg_session", { path: "/" })
      .clearCookie("dg_csrf", { path: "/" });
    return { ok: true };
  });
  app.post(
    "/auth/recovery",
    { config: { rateLimit: { max: 3, timeWindow: "15 minutes" } } },
    async (req, reply) => {
      browserInput(req);
      const input = z.object({ email: z.email().max(254) }).parse(req.body);
      await auth.issueAction(
        config.LOGIN_ORGANIZATION_ID,
        input.email,
        "recovery",
      );
      return reply.code(202).send({
        message: "If the account exists, a recovery email will arrive shortly.",
      });
    },
  );
  app.post(
    "/auth/redeem",
    { config: { rateLimit: { max: 5, timeWindow: "15 minutes" } } },
    async (req) => {
      browserInput(req);
      const b = z
        .object({ token: z.string().min(32).max(128), password: newPassword })
        .parse(req.body);
      await auth.redeemAction(b.token, b.password);
      return { ok: true };
    },
  );
  app.post(
    "/auth/invitations",
    { config: { rateLimit: { max: 5, timeWindow: "1 minute" } } },
    async (req) => {
      const a = requireActor(req.actor);
      const b = z
        .object({ siteId: z.uuid(), employeeId: z.uuid() })
        .parse(req.body);
      const email = await domain.site(a, b.siteId, async (c) => {
        await domain.require(c, "invitations.send");
        const row = (
          await c.query("SELECT work_email FROM app.employees WHERE id=$1", [
            b.employeeId,
          ])
        ).rows[0];
        if (!row) fail("NOT_FOUND", "Employee not found", 404);
        return row.work_email as string;
      });
      await auth.issueAction(a.organizationId, email, "invitation");
      return { ok: true };
    },
  );
  app.get("/files/exports/:id", async (req, reply) => {
    const a = requireActor(authenticated(req));
    const params = z.object({ id: z.uuid() }).parse(req.params);
    const query = z.object({ siteId: z.uuid() }).parse(req.query);
    const csv = await domain.download(a, query.siteId, params.id);
    return reply
      .header("Content-Type", "text/csv; charset=utf-8")
      .header("Content-Disposition", 'attachment; filename="employees.csv"')
      .send(csv);
  });
  app.post("/analytics/tools/employee-summary", async (req) => {
    const a = requireActor(authenticated(req));
    const { siteId } = z.object({ siteId: z.uuid() }).strict().parse(req.body);
    return domain.report(a, siteId);
  });
  app.post("/notifications/register", async (req) => {
    const a = requireActor(authenticated(req));
    const p = z
      .object({
        siteId: z.uuid(),
        token: z.string().min(20).max(4096),
        platform: z.enum(["android", "ios"]),
      })
      .strict()
      .parse(req.body);
    return domain.site(a, p.siteId, async (c) => {
      // The app re-registers on every launch; an unchanged token keeps its row.
      const current = (
        await c.query(
          "SELECT token_ciphertext FROM app.push_devices WHERE user_id=app.actor_id() AND active",
        )
      ).rows;
      if (
        current.length === 1 &&
        decrypt(current[0].token_ciphertext, config.ENCRYPTION_KEY) === p.token
      )
        return {
          registered: true,
          deliveryConfigured: Boolean(process.env.FCM_SERVICE_ACCOUNT_FILE),
        };
      await c.query(
        "UPDATE app.push_devices SET active=false WHERE user_id=app.actor_id()",
      );
      await c.query(
        "INSERT INTO app.push_devices(organization_id,site_id,user_id,token_ciphertext,platform) VALUES(app.org_id(),app.site_id(),app.actor_id(),$1,$2)",
        [encrypt(p.token, config.ENCRYPTION_KEY), p.platform],
      );
      return {
        registered: true,
        deliveryConfigured: Boolean(process.env.FCM_SERVICE_ACCOUNT_FILE),
      };
    });
  });
  app.addContentTypeParser(
    "application/octet-stream",
    { parseAs: "buffer" },
    (_req, body, done) => done(null, body),
  );
  app.post(
    "/files/intents/:id/content",
    { bodyLimit: 8 * 1024 * 1024 },
    async (req) => {
      const a = requireActor(authenticated(req));
      const { id } = z.object({ id: z.uuid() }).parse(req.params);
      const { siteId } = z.object({ siteId: z.uuid() }).parse(req.query);
      return uploadFile(domain, a, siteId, id, req.body as Buffer);
    },
  );
  app.get("/files/attachments/:id", async (req, reply) => {
    const a = requireActor(authenticated(req));
    const { id } = z.object({ id: z.uuid() }).parse(req.params);
    const { siteId, preview } = z
      .object({ siteId: z.uuid(), preview: z.literal("1").optional() })
      .parse(req.query);
    const file = await downloadFile(domain, a, siteId, id);
    return reply
      .header("Content-Type", file.type)
      .header(
        "Content-Disposition",
        preview && file.type === "image/jpeg"
          ? 'inline; filename="evidence.jpg"'
          : 'attachment; filename="attachment"',
      )
      .header("X-Content-Type-Options", "nosniff")
      .send(file.bytes);
  });
  // Media transport for profile requests: GraphQL bodies are capped at 64 KB.
  app.post("/profile/requests", { bodyLimit: 2 * 1024 * 1024 }, async (req) => {
    const a = requireActor(authenticated(req));
    const { siteId } = z.object({ siteId: z.uuid() }).parse(req.query);
    return domain.foundationWrite(
      a,
      siteId,
      "request_profile",
      z.record(z.string(), z.unknown()).parse(req.body),
    );
  });
  app.get("/profile/photos/:kind/:id", async (req, reply) => {
    const a = requireActor(authenticated(req));
    const { kind, id } = req.params as { kind: string; id: string };
    const { siteId } = z.object({ siteId: z.uuid() }).parse(req.query);
    return reply
      .header("Content-Type", "image/jpeg")
      .header("X-Content-Type-Options", "nosniff")
      .send(await domain.photo(a, siteId, kind, id));
  });
  app.get("/payroll/register/csv", async (req, reply) => {
    const a = authenticated(req);
    const { siteId, ...filters } = req.query as Record<string, unknown>;
    const body = await domain.payrollRegister(
      a,
      z.uuid().parse(siteId),
      filters,
    );
    return reply
      .header("Content-Type", "text/csv; charset=utf-8")
      .header(
        "Content-Disposition",
        'attachment; filename="payroll-register.csv"',
      )
      .send(body);
  });
  app.get("/payroll/:id/:format", async (req, reply) => {
    const a = authenticated(req),
      { id, format } = req.params as { id: string; format: string };
    const { siteId } = z.object({ siteId: z.uuid() }).parse(req.query);
    if (!["print", "csv", "json"].includes(format))
      fail("BAD_INPUT", "Unsupported format");
    const result = await domain.payrollDownload(a, siteId, id, format);
    if (format === "print")
      reply.header(
        "Content-Security-Policy",
        "default-src 'none'; style-src 'unsafe-inline'; img-src data:; frame-ancestors 'none'",
      );
    return reply
      .header("Content-Type", result.type)
      .header(
        "Content-Disposition",
        format === "csv" ? 'attachment; filename="payslip.csv"' : "inline",
      )
      .send(result.body);
  });
  app.get("/dwr/:id/print", async (req, reply) => {
    const { id } = z.object({ id: z.uuid() }).parse(req.params);
    const { siteId } = z.object({ siteId: z.uuid() }).parse(req.query);
    const a = requireActor(authenticated(req));
    const html = await domain.printDwr(a, siteId, id);
    return reply
      .header("Content-Type", "text/html; charset=utf-8")
      .header(
        "Content-Security-Policy",
        "default-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'",
      )
      .send(html);
  });
  const schema = await readFile(
    new URL("../../../packages/contracts/schema.graphql", import.meta.url),
    "utf8",
  );
  const actor = (ctx: { reply: { request: FastifyRequest } }) => {
    const a = requireActor(ctx.reply.request.actor);
    const pv = ctx.reply.request.headers["x-permission-version"];
    if (pv && pv !== String(a.permissionVersion))
      fail("SCOPE_CHANGED", "Permissions changed. Reload your workspace.", 409);
    return a;
  };
  // Request lifetime only. Aliases share an authorized profile read; nothing
  // survives a response, actor/version change, or selected-site change.
  const profileLoads = new WeakMap<
    FastifyRequest,
    Map<string, ReturnType<Dashboard["profile"]>>
  >();
  const loadProfile = (
    c: { reply: { request: FastifyRequest } },
    siteId: string,
    id: string,
  ) => {
    const a = actor(c),
      req = c.reply.request;
    let loads = profileLoads.get(req);
    if (!loads) {
      loads = new Map();
      profileLoads.set(req, loads);
    }
    const key = JSON.stringify([
      a.organizationId,
      a.id,
      a.permissionVersion,
      siteId,
      id,
    ]);
    let promise = loads.get(key);
    if (!promise) {
      promise = domain.profile(a, siteId, id);
      loads.set(key, promise);
    }
    return promise;
  };
  await app.register(mercurius, {
    schema,
    graphiql: false,
    allowBatchedQueries: false,
    queryDepth: 8,
    validationRules: [boundedQuery],
    errorFormatter(result) {
      return {
        statusCode: result.errors?.some(
          (e) => e.extensions?.code === "CSRF_INVALID",
        )
          ? 403
          : 200,
        response: {
          data: result.data ?? null,
          errors: result.errors?.map((e) => ({
            message: [
              "FORBIDDEN",
              "NOT_FOUND",
              "CONFLICT",
              "UNAUTHENTICATED",
              "MFA_REQUIRED",
              "SCOPE_CHANGED",
              "BAD_CURSOR",
              "BAD_INPUT",
              "DELEGATION_LIMIT",
              "SELF_ESCALATION",
              "PROTECTED_ACCOUNT",
              "LAST_SUPER_ADMIN",
              "REASON_REQUIRED",
              "REQUEST_PENDING",
              "ASSIGNMENT_OVERLAP",
              "REPORTING_CYCLE",
              "EXPORT_LIMIT",
              "CONFIGURATION_REQUIRED",
              "PHOTO_REQUIRED",
              "PHOTO_NOT_READY",
              "INSUFFICIENT_BALANCE",
              "FILE_NOT_READY",
              "STORAGE_UNAVAILABLE",
              "REPORT_LOCKED",
              "LAST_GROUP_ADMIN",
              "EMPLOYEE_EXITED",
              "NO_LOGIN",
            ].includes(String(e.extensions?.code))
              ? e.message
              : "Request could not be completed",
            extensions: {
              code:
                e.extensions?.code ??
                (e.originalError instanceof ZodError
                  ? "BAD_INPUT"
                  : "BAD_REQUEST"),
            },
          })),
        },
      };
    },
    resolvers: {
      JSON: new GraphQLScalarType({
        name: "JSON",
        serialize: (v) => v,
        parseValue: (v) => v,
        parseLiteral: () => {
          throw new GraphQLError("Use JSON variables");
        },
      }),
      DateTime: new GraphQLScalarType({
        name: "DateTime",
        serialize: (v) => new Date(v as string).toISOString(),
        parseValue: (v) => z.iso.datetime().parse(v),
        parseLiteral: (n) =>
          n.kind === Kind.STRING ? z.iso.datetime().parse(n.value) : null,
      }),
      Decimal: new GraphQLScalarType({
        name: "Decimal",
        serialize: (v) =>
          z
            .string()
            .regex(/^-?\d+(\.\d+)?$/)
            .parse(v),
      }),
      Query: {
        trackingContext: (_: unknown, { siteId }: any, ctx: any) =>
          tracking.trackingContext(actor(ctx), siteId),
        trackingMonitor: (_: unknown, { siteId, input }: any, ctx: any) =>
          tracking.trackingMonitor(actor(ctx), siteId, input),
        analytics: (_: unknown, { siteId, input }: any, ctx: any) =>
          domain.analyticsSnapshot(actor(ctx), siteId, input),
        approvalQueue: (_: unknown, { siteId }: any, ctx: any) =>
          domain.approvalQueue(actor(ctx), siteId),
        dashboard: (_: unknown, { siteId }: any, ctx: any) =>
          domain.dashboard(actor(ctx), siteId),
        employeeLookup: (_: unknown, { siteId, search }: any, ctx: any) =>
          domain.employeeLookup(actor(ctx), siteId, search),
        payroll: (_: unknown, { siteId, input }: any, ctx: any) =>
          domain.payrollSnapshot(actor(ctx), siteId, input),
        hrRecords: (_: unknown, { siteId, kind }: any, ctx: any) =>
          domain.hrSnapshot(actor(ctx), siteId, kind),
        dwr: (_: unknown, { siteId, workDate }: any, ctx: any) =>
          domain.dwrSnapshot(actor(ctx), siteId, workDate),
        dwrChat: (_: unknown, { siteId, input }: any, ctx: any) =>
          domain.dwrChat(actor(ctx), siteId, input),
        operations: (_: unknown, { siteId }: any, ctx: any) =>
          domain.snapshot(actor(ctx), siteId),
        attendanceDay: (
          _: unknown,
          { siteId, workDate, employeeId, offset }: any,
          ctx: any,
        ) =>
          domain.snapshot(actor(ctx), siteId, { workDate, employeeId, offset }),
        attendanceReview: (_: unknown, { siteId, workDate }: any, ctx: any) =>
          domain.attendanceReviewDay(actor(ctx), siteId, workDate),
        accessUsers: (_r, a, c) =>
          domain.users(actor(c), a.siteId, a.search ?? ""),
        roleMatrix: (_r, a, c) => domain.roleMatrix(actor(c), a.siteId),
        userAccess: (_r, a, c) => domain.access(actor(c), a.siteId, a.userId),
        foundation: (_r, a, c) => domain.foundation(actor(c), a.siteId),
        profileRequests: (_r, a, c) =>
          domain.profileRequests(actor(c), a.siteId),
        employeeDetails: (_r, a, c) =>
          domain.employeeDetails(actor(c), a.siteId, a.employeeId),
        organizationReport: (_r, a, c) => domain.report(actor(c), a.siteId),
        auditHistory: (_r, a, c) => domain.audit(actor(c), a.siteId),
        exportJob: (_r, a, c) => domain.exportJob(actor(c), a.siteId, a.id),
        bootstrap: (_r, _a, c) => domain.bootstrap(actor(c)),
        scope: (_r, a, c) => domain.scope(actor(c), a.siteId),
        employees: (_r, a, c) =>
          domain.list(
            actor(c),
            a.siteId,
            a.first ?? 20,
            a.after,
            a.search ?? "",
            a.department ?? "",
            a.status ?? "current",
          ),
        employee: (_r, a, c) => loadProfile(c, a.siteId, a.id),
        myProfile: (_r, a, c) => domain.profile(actor(c), a.siteId),
      },
      Mutation: {
        trackingCommand: (
          _: unknown,
          { siteId, operation, input }: any,
          ctx: any,
        ) => tracking.trackingCommand(actor(ctx), siteId, operation, input),
        explainAnalytics: (_: unknown, { siteId, input }: any, ctx: any) =>
          domain.explainAnalytics(actor(ctx), siteId, input),
        payrollCommand: (
          _: unknown,
          { siteId, operation, input }: any,
          ctx: any,
        ) => domain.payrollCommand(actor(ctx), siteId, operation, input),
        hrCommand: (_: unknown, { siteId, operation, input }: any, ctx: any) =>
          domain.hrCommand(actor(ctx), siteId, operation, input),
        dwrCommand: (_: unknown, { siteId, operation, input }: any, ctx: any) =>
          domain.dwrCommand(actor(ctx), siteId, operation, input),
        operate: (_: unknown, { siteId, operation, input }: any, ctx: any) =>
          domain.command(actor(ctx), siteId, operation, input),
        previewAccess: (_r, a, c) =>
          domain.changeAccess(actor(c), a.siteId, a.userId, a.input),
        saveAccess: (_r, a, c) =>
          domain.changeAccess(actor(c), a.siteId, a.userId, a.input, true),
        saveFoundation: (_r, a, c) =>
          domain.foundationWrite(actor(c), a.siteId, a.operation, a.input),
        employeeLifecycle: (_r, a, c) =>
          domain.employeeLifecycle(actor(c), a.siteId, a.operation, a.input),
        queueExport: (_r, a, c) =>
          domain.queueExport(actor(c), a.siteId, a.fields),
        updateProfile: (_r, a, c) => domain.update(actor(c), a.siteId, a.input),
      },
    },
  });
  app.addHook("preValidation", async (req) => {
    if (req.url.split("?")[0] === "/graphql" && req.method !== "POST")
      fail("METHOD_NOT_ALLOWED", "Use POST for GraphQL", 405);
  });
  if (process.env.SERVE_WEB === "true") {
    await app.register(staticFiles, {
      root: resolve(process.env.WEB_ROOT ?? "public"),
      cacheControl: false,
      index: ["index.html"],
    });
  }
  return app;
}
