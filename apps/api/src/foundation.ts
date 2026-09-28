import { randomBytes, randomInt } from "node:crypto";
import { z } from "zod";
import { Domain } from "./domain.js";
import { passwordHash } from "./security.js";
import { profilePhoto } from "./files.js";
import { type Actor, fail } from "../../../packages/authz/src/index.js";
import {
  permissionKeys,
  roles,
  scopes,
} from "../../../packages/authz/src/catalogue.js";
const uuid = z.uuid(),
  name = z.string().trim().min(1).max(100),
  version = z.number().int().positive();
const date = z.iso.date(),
  phone = z
    .string()
    .max(25)
    .regex(/^[+0-9()\s-]*$/),
  reason = z.string().trim().min(8).max(500);
const line = (max: number) => z.string().trim().min(1).max(max);
// Basic details: all optional; a request carries the complete proposed set.
export const personalDetails = z
  .object({
    dateOfBirth: date.refine(
      (v) => v >= "1900-01-01" && v <= new Date().toISOString().slice(0, 10),
    ),
    gender: z.enum(["female", "male", "other", "undisclosed"]),
    bloodGroup: z.enum(["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]),
    personalEmail: z.email().max(254),
    address: line(300),
    permanentAddress: line(300),
    emergencyName: line(100),
    emergencyRelation: line(50),
    emergencyPhone: phone.min(6),
  })
  .partial()
  .strict();
const rule = z
  .object({
    key: z.enum(permissionKeys as [string, ...string[]]),
    effect: z.enum(["inherit", "allow", "deny"]),
    scope: z.enum(scopes),
  })
  .strict();
const delegation = z
  .object({
    key: z.enum(permissionKeys as [string, ...string[]]),
    scope: z.enum(["own", "team", "site"]),
  })
  .strict();
export const accessInput = z
  .object({
    expectedVersion: version,
    role: z.enum(roles),
    active: z.boolean(),
    rules: z.array(rule).max(250),
    delegations: z.array(delegation).max(250),
    reason: reason.optional(),
  })
  .strict();
const employeeInput = z
  .object({
    employeeCode: name,
    displayName: name,
    workEmail: z.email().max(254),
    department: name,
    designation: name,
    phone: phone.default(""),
    legalEmployerId: uuid,
    startsOn: date,
  })
  .strict();
const forms: Record<string, z.ZodType> = {
  create_employee: employeeInput,
  approve_draft: z.object({ draftId: uuid, expectedVersion: version }).strict(),
  edit_employee: z
    .object({
      employeeId: uuid,
      expectedVersion: version,
      displayName: name,
      department: name,
      designation: name,
    })
    .strict(),
  request_profile: z
    .object({
      phone,
      expectedVersion: version,
      reason,
      details: personalDetails.optional(),
      // Base64 JPEG/PNG; the server stores only its re-encoded derivative.
      photo: z.base64().max(1_500_000).optional(),
    })
    .strict(),
  review_profile: z
    .object({
      id: uuid,
      expectedVersion: version,
      approve: z.boolean(),
      note: reason,
    })
    .strict(),
  assign_site: z
    .object({
      employeeId: uuid,
      expectedVersion: version,
      sourceSiteId: uuid,
      startsOn: date,
    })
    .strict(),
  end_assignment: z
    .object({
      employeeId: uuid,
      expectedVersion: version,
      assignmentId: uuid,
      endsOn: date,
    })
    .strict(),
  assign_team: z
    .object({
      employeeId: uuid,
      expectedVersion: version,
      managerId: uuid,
      startsOn: date,
    })
    .strict(),
  assign_shift: z
    .object({ employeeId: uuid, expectedVersion: version, shiftId: uuid })
    .strict(),
  reference: z
    .object({
      id: uuid.optional(),
      expectedVersion: version.optional(),
      kind: z.enum(["department", "designation", "shift", "holiday"]),
      name,
      active: z.boolean().default(true),
      startTime: z
        .string()
        .regex(/^([01]\d|2[0-3]):[0-5]\d$/)
        .optional(),
      endTime: z
        .string()
        .regex(/^([01]\d|2[0-3]):[0-5]\d$/)
        .optional(),
      date: date.optional(),
    })
    .strict(),
  site_settings: z
    .object({
      expectedVersion: version,
      name,
      timezone: z.string().refine((v) => {
        try {
          new Intl.DateTimeFormat("en", { timeZone: v });
          return true;
        } catch {
          return false;
        }
      }),
      weekStart: z.number().int().min(0).max(6),
      contactEmail: z.union([z.email(), z.literal("")]),
    })
    .strict(),
  module: z
    .object({ moduleId: name, enabled: z.boolean(), expectedVersion: version })
    .strict(),
  organization: z.object({ name }).strict(),
};
const lifecycleForms: Record<string, z.ZodType> = {
  // HR may type a password (8+) or leave it out to generate one.
  set_password: z
    .object({
      employeeId: uuid,
      expectedVersion: version,
      password: z.string().min(8).max(128).optional(),
    })
    .strict(),
  disable_login: z
    .object({ employeeId: uuid, expectedVersion: version })
    .strict(),
  enable_login: z
    .object({ employeeId: uuid, expectedVersion: version })
    .strict(),
  rehire: z
    .object({
      employeeId: uuid,
      expectedVersion: version,
      legalEmployerId: uuid,
      startsOn: date,
    })
    .strict(),
};
// 12 characters from an unambiguous 31-symbol alphabet (~59 bits), grouped
// for reading aloud or typing on a phone.
export function temporaryPassword() {
  const alphabet = "abcdefghjkmnpqrstuvwxyz23456789";
  const chars = Array.from({ length: 12 }, () => alphabet[randomInt(31)]);
  return [0, 4, 8].map((i) => chars.slice(i, i + 4).join("")).join("-");
}
export class Foundation extends Domain {
  // The temporary password is returned once and never stored or logged.
  async employeeLifecycle(
    actor: Actor,
    siteId: string,
    operation: string,
    input: Record<string, unknown>,
  ) {
    const schema = lifecycleForms[operation];
    if (!schema) fail("BAD_INPUT", "Unknown operation");
    const parsed = schema.parse(
      Object.fromEntries(Object.entries(input).filter(([, v]) => v !== null)),
    ) as Record<string, unknown>;
    const password =
      operation === "set_password"
        ? ((parsed.password as string | undefined) ?? temporaryPassword())
        : null;
    delete parsed.password; // only the hash reaches the database
    if (password) parsed.passwordHash = await passwordHash(password);
    const result = await this.site(
      actor,
      siteId,
      async (c) =>
        (
          await c.query("SELECT app.employee_lifecycle($1,$2) AS data", [
            operation,
            JSON.stringify(parsed),
          ])
        ).rows[0].data,
    );
    return { ...result, password };
  }
  /** Role defaults for the Roles & permissions page. Templates are a global,
   *  non-personal catalogue; people and changes stay in Users & access. */
  async roleMatrix(actor: Actor, siteId: string) {
    return this.site(actor, siteId, async (c) => {
      const can = (
        await c.query(
          "SELECT app.allowed('employees.view') view,app.allowed('access.view') manage",
        )
      ).rows[0];
      if (!can.view && !can.manage)
        fail("FORBIDDEN", "Roles and permissions are not available", 403);
      return {
        templates: (
          await c.query(
            "SELECT role,key,scope FROM app.role_templates ORDER BY role,key",
          )
        ).rows,
        canManage: can.manage,
      };
    });
  }
  async users(actor: Actor, siteId: string, search = "") {
    return this.site(
      actor,
      siteId,
      async (c) =>
        (
          await c.query("SELECT app.access_admin('users',NULL,$1) AS data", [
            JSON.stringify({ search: z.string().max(100).parse(search) }),
          ])
        ).rows[0].data,
    );
  }
  async access(actor: Actor, siteId: string, userId: string) {
    return this.site(actor, siteId, async (c) => {
      const data = (
        await c.query("SELECT app.access_admin('get',$1) AS data", [
          uuid.parse(userId),
        ])
      ).rows[0].data;
      data.audit = data.audit.map((r: any) => ({
        id: r.id,
        actorId: r.actorId,
        createdAt: r.createdAt,
        reason: r.metadata.reason,
        version: r.metadata.version,
        changes: r.metadata.changes,
      }));
      return data;
    });
  }
  async changeAccess(
    actor: Actor,
    siteId: string,
    userId: string,
    input: unknown,
    save = false,
  ) {
    const parsed = accessInput.parse(input);
    if (save) reason.parse(parsed.reason);
    return this.site(
      actor,
      siteId,
      async (c) =>
        (
          await c.query("SELECT app.access_admin($1,$2,$3) AS data", [
            save ? "save" : "preview",
            uuid.parse(userId),
            JSON.stringify(parsed),
          ])
        ).rows[0].data,
    );
  }
  async foundation(actor: Actor, siteId: string) {
    return this.site(actor, siteId, async (c) => {
      await this.require(c, "site_settings.view");
      const settings = (
        await c.query(
          'SELECT s.id,s.name,s.timezone,COALESCE(p.week_start,1) AS "weekStart",COALESCE(p.contact_email,\'\') AS "contactEmail",COALESCE(p.version,1) AS version FROM app.sites s LEFT JOIN app.site_preferences p ON p.site_id=s.id WHERE s.id=$1',
          [siteId],
        )
      ).rows[0];
      const references = (
        await c.query(
          "SELECT id,kind,name,active,version,details->>'startTime' AS \"startTime\",details->>'endTime' AS \"endTime\",details->>'date' AS date FROM app.site_reference_items ORDER BY kind,name LIMIT 200",
        )
      ).rows;
      const employers = (
        await c.query("SELECT id,name FROM app.legal_employers ORDER BY name")
      ).rows;
      const managers = (
        await c.query(
          "SELECT user_id AS id,display_name AS name FROM app.employees WHERE user_id IS NOT NULL ORDER BY display_name LIMIT 100",
        )
      ).rows;
      const drafts = (
        await c.query(
          'SELECT id,details,status,version,author_id AS "authorId",created_at AS "createdAt" FROM app.employee_drafts ORDER BY created_at DESC LIMIT 50',
        )
      ).rows.map((r) => ({ ...r, ...r.details }));
      return { settings, references, employers, managers, drafts };
    });
  }
  async profileRequests(actor: Actor, siteId: string) {
    return this.site(
      actor,
      siteId,
      async (c) =>
        (
          await c.query(
            `SELECT r.id,r.employee_id AS "employeeId",e.display_name AS "employeeName",r.phone,r.reason,r.status,r.version,r.created_at AS "createdAt",r.review_note AS "reviewNote",r.requester_id=app.actor_id() AS "isSelf",
   r.details,r.photo IS NOT NULL AS "hasPhoto",
   CASE WHEN r.status='pending' AND app.field_allowed('contact',r.employee_id) THEN e.phone END AS "currentPhone",
   CASE WHEN r.status='pending' AND app.field_allowed('contact',r.employee_id) THEN e.personal END AS "currentDetails"
   FROM app.profile_requests r JOIN app.employees e ON e.id=r.employee_id ORDER BY r.created_at DESC LIMIT 100`,
          )
        ).rows,
    );
  }
  // Approved photos follow employee visibility; proposed ones follow the request.
  async photo(actor: Actor, siteId: string, kind: string, id: string) {
    const sql = {
      employee: "SELECT photo FROM app.employee_photos WHERE employee_id=$1",
      request:
        "SELECT photo FROM app.profile_requests WHERE id=$1 AND photo IS NOT NULL",
    }[z.enum(["employee", "request"]).parse(kind)];
    return this.site(actor, siteId, async (c) => {
      const row = (await c.query(sql, [uuid.parse(id)])).rows[0];
      if (!row) fail("NOT_FOUND", "Photo unavailable", 404);
      return row.photo as Buffer;
    });
  }
  async employeeDetails(actor: Actor, siteId: string, employeeId: string) {
    return this.site(actor, siteId, async (c) => {
      if (
        !(
          await c.query("SELECT app.field_allowed('employment',$1) AS ok", [
            uuid.parse(employeeId),
          ])
        ).rows[0].ok
      )
        fail("FORBIDDEN", "Employment information is restricted.", 403);
      const reporting = (
        await c.query(
          `SELECT t.id,t.manager_id AS "managerId",COALESCE(e.display_name,'Assigned manager') AS "managerName",t.starts_on::text AS "startsOn",t.ends_on::text AS "endsOn" FROM app.team_assignments t LEFT JOIN app.employees e ON e.user_id=t.manager_id WHERE t.employee_id=$1 ORDER BY t.starts_on DESC LIMIT 50`,
          [employeeId],
        )
      ).rows;
      const shift =
        (
          await c.query(
            "SELECT r.id,r.name,r.details->>'startTime' AS \"startTime\",r.details->>'endTime' AS \"endTime\" FROM app.employee_site_details d JOIN app.site_reference_items r ON r.id=d.shift_id WHERE d.employee_id=$1",
            [employeeId],
          )
        ).rows[0] ?? null;
      return { reporting, shift };
    });
  }
  async foundationWrite(
    actor: Actor,
    siteId: string,
    operation: string,
    input: Record<string, unknown>,
  ) {
    const schema = forms[operation];
    if (!schema) fail("BAD_INPUT", "Unknown operation");
    // GraphQL optional fields may arrive as null; treat them as omitted before exact validation.
    let parsed = schema.parse(
      Object.fromEntries(Object.entries(input).filter(([, v]) => v !== null)),
    ) as Record<string, unknown>;
    if (operation === "reference") {
      if (parsed.id && !parsed.expectedVersion)
        fail("BAD_INPUT", "Expected version required");
      if (parsed.kind === "shift" && (!parsed.startTime || !parsed.endTime))
        fail("BAD_INPUT", "Both shift times are required");
      if (parsed.kind === "holiday" && !parsed.date)
        fail("BAD_INPUT", "Holiday date required");
      const { startTime, endTime, date, ...rest } = parsed;
      parsed = { ...rest, details: { startTime, endTime, date } };
    }
    if (operation === "request_profile" && parsed.photo)
      parsed.photo = (
        await profilePhoto(Buffer.from(parsed.photo as string, "base64"))
      ).toString("base64");
    if (operation === "create_employee" || operation === "approve_draft")
      parsed.passwordHash = await passwordHash(randomBytes(32).toString("hex"));
    return this.site(
      actor,
      siteId,
      async (c) =>
        (
          await c.query("SELECT app.employee_foundation($1,$2) AS data", [
            operation,
            JSON.stringify(parsed),
          ])
        ).rows[0].data,
    );
  }
  async report(actor: Actor, siteId: string) {
    return this.site(
      actor,
      siteId,
      async (c) =>
        (await c.query("SELECT app.organization_report() AS data")).rows[0]
          .data,
    );
  }
  async audit(actor: Actor, siteId: string) {
    return this.site(actor, siteId, async (c) => {
      await this.require(c, "audit.view");
      return (
        await c.query(
          'SELECT id,actor_id AS "actorId",action,entity_id AS "entityId",created_at AS "createdAt",metadata->>\'reason\' AS reason FROM app.audit_records ORDER BY created_at DESC LIMIT 100',
        )
      ).rows;
    });
  }
  async queueExport(actor: Actor, siteId: string, fields: string[]) {
    return this.site(actor, siteId, async (c) => {
      z.array(z.string()).min(1).max(8).parse(fields);
      return {
        id: (
          await c.query("SELECT app.queue_export($1,$2,$3) AS id", [
            actor.sessionId,
            actor.permissionVersion,
            fields,
          ])
        ).rows[0].id,
        status: "queued",
      };
    });
  }
  async exportJob(actor: Actor, siteId: string, jobId: string) {
    return this.site(actor, siteId, async (c) => {
      const job = (
        await c.query(
          'SELECT id,status,expires_at AS "expiresAt",permission_version FROM app.export_jobs WHERE id=$1',
          [uuid.parse(jobId)],
        )
      ).rows[0];
      if (!job) fail("NOT_FOUND", "Export not found", 404);
      if (job.permission_version !== actor.permissionVersion)
        fail("SCOPE_CHANGED", "Export access changed", 409);
      return job;
    });
  }
  async download(actor: Actor, siteId: string, jobId: string) {
    return this.site(actor, siteId, async (c) => {
      const job = (
        await c.query("SELECT * FROM app.export_jobs WHERE id=$1", [
          uuid.parse(jobId),
        ])
      ).rows[0];
      if (
        !job ||
        job.session_id !== actor.sessionId ||
        job.permission_version !== actor.permissionVersion ||
        job.status !== "ready" ||
        new Date(job.expires_at) <= new Date()
      )
        fail("FORBIDDEN", "This download is no longer available", 403);
      if (
        !(await c.query("SELECT app.export_authorized($1) AS ok", [job.fields]))
          .rows[0].ok
      )
        fail("FORBIDDEN", "Export permission changed", 403);
      const rows = (
        await c.query(
          `SELECT id,employee_code AS "employeeCode",display_name AS "displayName",CASE WHEN app.field_allowed('employment',id) THEN department END AS department,CASE WHEN app.field_allowed('employment',id) THEN job_title END AS "jobTitle",CASE WHEN app.field_allowed('contact',id) THEN phone END AS phone FROM app.employees WHERE app.allowed('employees.export',id) ORDER BY employee_code LIMIT 1001`,
        )
      ).rows;
      if (rows.length > 1000)
        fail("EXPORT_LIMIT", "Limit the site export to 1,000 employees");
      for (const row of rows)
        for (const f of ["salary", "bank", "identity"])
          if (job.fields.includes(f))
            row[f] =
              (
                await c.query(
                  "SELECT value FROM app.employee_sensitive_fields WHERE employee_id=$1 AND field=$2",
                  [row.id, f],
                )
              ).rows[0]?.value ?? "";
      await c.query(
        "INSERT INTO app.audit_records(organization_id,site_id,actor_id,action,entity_id,metadata) VALUES($1,$2,$3,'export.downloaded',$4,$5)",
        [
          actor.organizationId,
          siteId,
          actor.id,
          job.id,
          JSON.stringify({ fields: job.fields, count: rows.length }),
        ],
      );
      const csv = (value: unknown) =>
        '"' +
        String(value ?? "")
          .replace(/^[=+@\-\t\r]/, "'$&")
          .replaceAll('"', '""') +
        '"';
      return (
        "\ufeff" +
        [
          job.fields,
          ...rows.map((row) => job.fields.map((f: string) => row[f])),
        ]
          .map((row) => row.map(csv).join(","))
          .join("\r\n")
      );
    });
  }
}
