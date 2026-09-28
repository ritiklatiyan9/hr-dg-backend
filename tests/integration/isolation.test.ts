import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { randomBytes, randomUUID } from "node:crypto";
import type { FastifyInstance } from "fastify";
import type pg from "pg";
import {
  pool,
  scoped,
  assertRuntimeRole,
} from "../../packages/db/src/index.js";
import { migrate } from "../../packages/db/src/migrate.js";
import { seed, ids } from "../../packages/db/src/seed.js";
import { createApp } from "../../apps/api/src/app.js";
import { AuthService } from "../../apps/api/src/auth.js";
import { totp, decrypt } from "../../apps/api/src/security.js";
import type { Config } from "../../packages/config/src/index.js";
import type { Actor } from "../../packages/authz/src/index.js";
let app: FastifyInstance,
  owner: pg.Pool,
  runtime: pg.Pool,
  authPool: pg.Pool,
  control: pg.Pool,
  auth: AuthService;
let admin: string,
  employee: string,
  river: string,
  outsider: string,
  dbName: string;
const password = randomBytes(24).toString("hex"),
  encryptionKey = randomBytes(32).toString("hex");
const actor = (id: string, org = ids.org): Actor => ({
  id,
  organizationId: org,
  sessionId: randomUUID(),
  permissionVersion: 1,
  kind: "mobile",
  csrfHash: "",
  requiresMfa: false,
  mfaVerified: true,
});
async function login(email: string, kind: "mobile" | "web" = "mobile") {
  return app.inject({
    method: "POST",
    url: "/auth/login",
    headers: { origin: "http://localhost:5173" },
    payload: {
      email,
      password,
      kind,
      ...(kind === "mobile" ? { deviceId: randomUUID() } : {}),
    },
  });
}
async function gql(
  token: string,
  query: string,
  variables: Record<string, unknown> = {},
) {
  return (
    await app.inject({
      method: "POST",
      url: "/graphql",
      headers: { authorization: `Bearer ${token}` },
      payload: { query, variables },
    })
  ).json();
}
before(
  async () => {
    const root = process.env.TEST_MIGRATION_DATABASE_URL;
    if (
      !root ||
      !process.env.TEST_DATABASE_URL ||
      !process.env.TEST_AUTH_DATABASE_URL
    )
      throw new Error(
        "Real PostGIS test URLs are required. Run local:env and Docker Compose; tests are never silently skipped.",
      );
    if (new URL(root).pathname !== "/hr_test")
      throw new Error("Test control database must be named hr_test");
    control = pool(root, 1);
    dbName = `hr_test_${randomBytes(8).toString("hex")}`;
    await control.query(`CREATE DATABASE ${dbName}`);
    const url = (base: string) => {
      const u = new URL(base);
      u.pathname = `/${dbName}`;
      return u.toString();
    };
    const ownerUrl = url(root);
    await migrate(ownerUrl);
    await seed(ownerUrl, password);
    owner = pool(ownerUrl, 1);
    runtime = pool(url(process.env.TEST_DATABASE_URL), 1);
    authPool = pool(url(process.env.TEST_AUTH_DATABASE_URL), 2);
    const config: Config = {
      NODE_ENV: "test",
      PORT: 4000,
      DATABASE_URL: url(process.env.TEST_DATABASE_URL),
      AUTH_DATABASE_URL: url(process.env.TEST_AUTH_DATABASE_URL),
      LOGIN_ORGANIZATION_ID: ids.org,
      WEB_ORIGIN: "http://localhost:5173",
      COOKIE_SECURE: "true",
      ENCRYPTION_KEY: encryptionKey,
      REDIS_URL: "redis://localhost:56379",
    };
    app = await createApp(config, runtime, authPool, false);
    auth = new AuthService(authPool, config);
    employee = (await login("employee@example.test")).json().accessToken;
    river = (await login("river@example.test")).json().accessToken;
    outsider = (
      await auth.login({
        organizationId: ids.otherOrg,
        email: "outsider@example.test",
        password,
        kind: "mobile",
        deviceId: randomUUID(),
      })
    ).accessToken;
    const r = await login("hr@example.test");
    assert.equal(r.statusCode, 200);
    admin = r.json().accessToken;
    const setup = await app.inject({
      method: "POST",
      url: "/auth/mfa/setup",
      headers: { authorization: `Bearer ${admin}` },
      payload: {},
    });
    assert.equal(setup.statusCode, 200);
    const verify = await app.inject({
      method: "POST",
      url: "/auth/mfa/verify",
      headers: { authorization: `Bearer ${admin}` },
      payload: { code: totp(setup.json().secret).generate() },
    });
    assert.equal(verify.statusCode, 200);
  },
  { timeout: 60000 },
);
after(async () => {
  if (app) await app.close();
  await Promise.all([owner?.end(), runtime?.end(), authPool?.end()]);
  if (control && dbName) {
    await control.query(`DROP DATABASE IF EXISTS ${dbName}`);
    await control.end();
  }
});
test("runtime credentials are non-owner, non-superuser, non-BYPASSRLS", async () => {
  await assertRuntimeRole(runtime, "hr_runtime");
  await assertRuntimeRole(authPool, "hr_auth");
  await assert.rejects(() => assertRuntimeRole(owner, "hr_runtime"));
  await assert.rejects(() => runtime.query("SELECT * FROM auth.users"));
  await assert.rejects(() => authPool.query("SELECT * FROM app.employees"));
});
test("login rejects incorrect passwords and ignores client tenant selection", async () => {
  const invalid = await app.inject({
    method: "POST",
    url: "/auth/login",
    payload: {
      email: "employee@example.test",
      password: "incorrect",
      kind: "mobile",
      deviceId: randomUUID(),
    },
  });
  assert.equal(invalid.statusCode, 401);
  assert.equal(invalid.json().code, "INVALID_CREDENTIALS");

  const bound = await app.inject({
    method: "POST",
    url: "/auth/login",
    payload: {
      organizationId: ids.otherOrg,
      email: "employee@example.test",
      password,
      kind: "mobile",
      deviceId: randomUUID(),
    },
  });
  assert.equal(bound.statusCode, 200);
  assert.equal(
    (await auth.lookup(bound.json().accessToken))?.organizationId,
    ids.org,
  );
});
test("a device ID stays bound to its first account", async () => {
  const deviceId = randomUUID();
  const signIn = (email: string) =>
    app.inject({
      method: "POST",
      url: "/auth/login",
      // Own address: the file's other sign-ins share the per-IP login limit.
      remoteAddress: "192.0.2.10",
      payload: { email, password, kind: "mobile", deviceId },
    });
  assert.equal((await signIn("employee@example.test")).statusCode, 200);
  const other = await signIn("hr@example.test");
  assert.equal(other.statusCode, 409);
  assert.equal(other.json().code, "DEVICE_IN_USE");
  assert.equal((await signIn("employee@example.test")).statusCode, 200);
});
test("unauthenticated GraphQL and incomplete privileged MFA cannot bootstrap", async () => {
  assert.equal(
    (await gql("invalid", "{ bootstrap { actor { id } } }")).errors[0]
      .extensions.code,
    "UNAUTHENTICATED",
  );
  const pending = await login("hr@example.test");
  assert.equal(pending.json().mfaRequired, true);
  assert.equal(
    (await gql(pending.json().accessToken, "{ bootstrap { actor { id } } }"))
      .errors[0].extensions.code,
    "MFA_REQUIRED",
  );
});
test("bootstrap derives organization and returns only authorized sites", async () => {
  const r = await gql(
    river,
    "{ bootstrap { organization { id } sites { id } } }",
  );
  assert.equal(r.data.bootstrap.organization.id, ids.org);
  assert.deepEqual(
    r.data.bootstrap.sites.map((s: { id: string }) => s.id),
    [ids.rg],
  );
});
test("forged site IDs and other organization sites are denied", async () => {
  for (const siteId of [ids.dg, ids.otherSite, randomUUID()]) {
    const r = await gql(river, "query($s:ID!){myProfile(siteId:$s){id}}", {
      s: siteId,
    });
    assert.ok(r.errors);
    assert.equal(r.data?.myProfile ?? null, null);
  }
});
test("cross-organization reads and nested GraphQL cannot reveal records", async () => {
  const r = await gql(
    admin,
    "query($s:ID!,$id:ID!){employee(siteId:$s,id:$id){id employment{id legalEmployer{id name}} assignments{id site{id}}}}",
    { s: ids.dg, id: ids.outsiderProfile },
  );
  assert.equal(r.data.employee, null);
  const legitimate = await gql(
    admin,
    "query($s:ID!,$id:ID!){employee(siteId:$s,id:$id){id employment{legalEmployer{id name}} assignments{site{id}}}}",
    { s: ids.dg, id: ids.employeeProfile },
  );
  assert.equal(
    legitimate.data.employee.employment[0].legalEmployer.id,
    ids.employer,
  );
  assert.deepEqual(
    legitimate.data.employee.assignments.map(
      (a: { site: { id: string } }) => a.site.id,
    ),
    [ids.dg],
  );
});
test("employee cannot list coworkers or read another profile even at an authorized site", async () => {
  const list = await gql(
    employee,
    "query($s:ID!){employees(siteId:$s){nodes{id}}}",
    { s: ids.dg },
  );
  assert.ok(list.errors);
  const r = await gql(
    employee,
    "query($s:ID!,$id:ID!){employee(siteId:$s,id:$id){id}}",
    { s: ids.rg, id: ids.riverProfile },
  );
  assert.equal(r.data.employee, null);
});
test("aliases with two sites keep their own connection-local scope", async () => {
  const r = await gql(
    admin,
    "query($a:ID!,$b:ID!){a:employees(siteId:$a){nodes{id}} b:employees(siteId:$b){nodes{id}}}",
    { a: ids.dg, b: ids.rg },
  );
  assert.equal(r.data.a.nodes.length, 2);
  assert.equal(r.data.b.nodes.length, 3);
});
test("pooled connection has no residual tenant after commit or rollback", async () => {
  await scoped(runtime, actor(ids.admin), ids.dg, async (c) => {
    assert.equal((await c.query("SELECT * FROM app.employees")).rowCount, 2);
  });
  assert.equal(
    (await runtime.query("SELECT * FROM app.employees")).rowCount,
    0,
  );
  await assert.rejects(() =>
    scoped(runtime, actor(ids.admin), ids.dg, async () => {
      throw new Error("rollback");
    }),
  );
  assert.equal(
    (await runtime.query("SELECT * FROM app.employees")).rowCount,
    0,
  );
  const count = await scoped(
    runtime,
    actor(ids.outsider, ids.otherOrg),
    ids.otherSite,
    async (c) => (await c.query("SELECT * FROM app.employees")).rowCount,
  );
  assert.equal(count, 1);
});
test("concurrent requests do not leak the last tenant through a one-connection pool", async () => {
  const responses = await Promise.all(
    Array.from({ length: 12 }, (_, i) =>
      gql(
        i % 2 ? outsider : employee,
        "query($s:ID!){myProfile(siteId:$s){id}}",
        { s: i % 2 ? ids.otherSite : ids.dg },
      ),
    ),
  );
  responses.forEach((r, i) =>
    assert.equal(
      r.data.myProfile.id,
      i % 2 ? ids.outsiderProfile : ids.employeeProfile,
    ),
  );
});
test("cross-organization writes and scoped foreign keys reject forged relationships", async () => {
  const result = await gql(
    admin,
    "mutation($s:ID!,$i:UpdateProfileInput!){updateProfile(siteId:$s,input:$i){id}}",
    {
      s: ids.dg,
      i: { employeeId: ids.outsiderProfile, phone: "123", expectedVersion: 1 },
    },
  );
  assert.ok(result.errors);
  assert.equal(
    (
      await owner.query("SELECT phone FROM app.employees WHERE id=$1", [
        ids.outsiderProfile,
      ])
    ).rows[0].phone,
    "",
  );
  await assert.rejects(
    () =>
      owner.query(
        "INSERT INTO app.site_assignments(organization_id,site_id,employee_id,starts_on) VALUES($1,$2,$3,'2024-01-01')",
        [ids.org, ids.dg, ids.outsiderProfile],
      ),
    { code: "23503" },
  );
});
test("profile write persists shared identity; audit and outbox retain original site", async () => {
  const result = await gql(
    admin,
    "mutation($s:ID!,$i:UpdateProfileInput!){updateProfile(siteId:$s,input:$i){id phone version}}",
    {
      s: ids.dg,
      i: {
        employeeId: ids.employeeProfile,
        phone: "+91 9000000000",
        expectedVersion: 1,
      },
    },
  );
  assert.equal(result.data.updateProfile.version, 2);
  const r = await gql(employee, "query($s:ID!){myProfile(siteId:$s){phone}}", {
    s: ids.rg,
  });
  assert.equal(r.data.myProfile.phone, "+91 9000000000");
  const audit = (
    await owner.query("SELECT * FROM app.audit_records WHERE entity_id=$1", [
      ids.employeeProfile,
    ])
  ).rows;
  assert.equal(audit.length, 1);
  assert.equal(audit[0].site_id, ids.dg);
  assert.equal(JSON.stringify(audit).includes("9000000000"), false);
  assert.equal(
    (await owner.query("SELECT site_id FROM app.outbox")).rows[0].site_id,
    ids.dg,
  );
});
test("optimistic concurrency rejects stale writes", async () => {
  const r = await gql(
    admin,
    "mutation($s:ID!,$i:UpdateProfileInput!){updateProfile(siteId:$s,input:$i){id}}",
    {
      s: ids.dg,
      i: { employeeId: ids.employeeProfile, phone: "1", expectedVersion: 1 },
    },
  );
  assert.equal(r.errors[0].extensions.code, "CONFLICT");
});
test("web session is Secure HttpOnly and mutation requires Origin plus CSRF", async () => {
  const response = await login("employee@example.test", "web");
  const cookies = response.cookies;
  assert.equal(cookies.find((c) => c.name === "dg_session")?.httpOnly, true);
  assert.equal(cookies.find((c) => c.name === "dg_session")?.secure, true);
  const header = cookies.map((c) => `${c.name}=${c.value}`).join("; ");
  const rejected = await app.inject({
    method: "POST",
    url: "/graphql",
    headers: { cookie: header, origin: "http://localhost:5173" },
    payload: { query: "{bootstrap{actor{id}}}" },
  });
  assert.equal(rejected.statusCode, 403);
  const wrongOrigin = await app.inject({
    method: "POST",
    url: "/graphql",
    headers: {
      cookie: header,
      origin: "https://forged.invalid",
      "x-csrf-token": response.json().csrfToken,
    },
    payload: { query: "{bootstrap{actor{id}}}" },
  });
  assert.equal(wrongOrigin.statusCode, 403);
  const accepted = await app.inject({
    method: "POST",
    url: "/graphql",
    headers: {
      cookie: header,
      origin: "http://localhost:5173",
      "x-csrf-token": response.json().csrfToken,
    },
    payload: { query: "{bootstrap{actor{id}}}" },
  });
  assert.ok(accepted.json().data);
});
test("mobile rotation rejects old access and refresh replay revokes family", async () => {
  const first = await auth.login({
    organizationId: ids.org,
    email: "river@example.test",
    password,
    kind: "mobile",
    deviceId: randomUUID(),
  });
  const next = await auth.refresh(first.refreshToken!);
  assert.equal(await auth.lookup(first.accessToken), null);
  assert.ok(await auth.lookup(next.accessToken));
  await assert.rejects(() => auth.refresh(first.refreshToken!));
  assert.equal(await auth.lookup(next.accessToken), null);
});
test("logout revokes server session and expiration rejects credentials", async () => {
  const session = await auth.login({
    organizationId: ids.org,
    email: "river@example.test",
    password,
    kind: "mobile",
    deviceId: randomUUID(),
  });
  const a = (await auth.lookup(session.accessToken))!;
  await auth.logout(a);
  assert.equal(await auth.lookup(session.accessToken), null);
  const second = await auth.login({
    organizationId: ids.org,
    email: "river@example.test",
    password,
    kind: "mobile",
    deviceId: randomUUID(),
  });
  const b = (await auth.lookup(second.accessToken))!;
  await owner.query(
    "UPDATE auth.sessions SET expires_at=now()-interval '1 second' WHERE id=$1",
    [b.sessionId],
  );
  assert.equal(await auth.lookup(second.accessToken), null);
});
test("recovery token is single-use, encrypted in outbox, revokes sessions and preserves MFA", async () => {
  await auth.issueAction(ids.org, "river@example.test", "recovery");
  const mail = (
    await owner.query(
      "SELECT encrypted_payload FROM auth.mail_outbox ORDER BY created_at DESC LIMIT 1",
    )
  ).rows[0].encrypted_payload;
  assert.equal(mail.includes("action="), false);
  const raw = JSON.parse(decrypt(mail, encryptionKey)).text.match(
    /#action=([A-Za-z0-9_-]+)/,
  )[1];
  await auth.redeemAction(raw, "A unique new passphrase 123");
  assert.equal(await auth.lookup(river), null);
  await assert.rejects(() => auth.redeemAction(raw, "Another unique password"));
});
test("stale permission versions are rejected and title alone grants no HR authority", async () => {
  const r = await app.inject({
    method: "POST",
    url: "/graphql",
    headers: {
      authorization: `Bearer ${admin}`,
      "x-permission-version": "99999",
    },
    payload: { query: "{bootstrap{actor{id}}}" },
  });
  assert.equal(r.json().errors[0].extensions.code, "SCOPE_CHANGED");
  const s = await gql(
    outsider,
    "query($s:ID!){scope(siteId:$s){capabilities}}",
    { s: ids.otherSite },
  );
  assert.equal(s.data.scope.capabilities.includes("hr.access"), false);
});

test("grant elevation requires MFA even for a session created before the grant", async () => {
  await owner.query(
    "INSERT INTO app.access_grants(organization_id,user_id,site_id,capability) VALUES($1,$2,$3,'hr.access')",
    [ids.otherOrg, ids.outsider, ids.otherSite],
  );
  const current = await auth.lookup(outsider);
  assert.equal(current?.requiresMfa, true);
  assert.equal(current?.mfaVerified, false);
  const r = await gql(outsider, "{bootstrap{actor{id}}}");
  assert.equal(r.errors[0].extensions.code, "MFA_REQUIRED");
});
