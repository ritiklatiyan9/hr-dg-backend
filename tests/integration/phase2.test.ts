import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { randomBytes, randomUUID } from "node:crypto";
import type pg from "pg";
import sharp from "sharp";
import type { FastifyInstance } from "fastify";
import { pool, scoped } from "../../packages/db/src/index.js";
import { migrate } from "../../packages/db/src/migrate.js";
import { seed, ids } from "../../packages/db/src/seed.js";
import { createApp } from "../../apps/api/src/app.js";
import { AuthService } from "../../apps/api/src/auth.js";
import { totp, decrypt } from "../../apps/api/src/security.js";
import {
  catalogue,
  permissionKeys,
} from "../../packages/authz/src/catalogue.js";
let app: FastifyInstance,
  owner: pg.Pool,
  runtime: pg.Pool,
  authPool: pg.Pool,
  control: pg.Pool,
  auth: AuthService,
  dbName: string;
const password = randomBytes(24).toString("hex"),
  encryptionKey = randomBytes(32).toString("hex"),
  tokens: Record<string, string> = {};
let loginSequence = 1;
async function signIn(email: string) {
  const remoteAddress = `127.0.1.${loginSequence++}`;
  const response = await app.inject({
    remoteAddress,
    method: "POST",
    url: "/auth/login",
    payload: {
      email,
      password,
      kind: "mobile",
      deviceId: randomUUID(),
    },
  });
  assert.equal(response.statusCode, 200);
  const data = response.json();
  if (data.mfaRequired) {
    let secret: string;
    if (data.enrollmentRequired)
      secret = (
        await app.inject({
          remoteAddress,
          method: "POST",
          url: "/auth/mfa/setup",
          headers: { authorization: `Bearer ${data.accessToken}` },
          payload: {},
        })
      ).json().secret;
    else {
      const row = (
        await owner.query("SELECT mfa_secret FROM auth.users WHERE email=$1", [
          email,
        ])
      ).rows[0];
      secret = decrypt(row.mfa_secret, encryptionKey);
      await owner.query(
        "UPDATE auth.users SET last_totp_step=-1 WHERE email=$1",
        [email],
      );
    }
    const verified = await app.inject({
      remoteAddress,
      method: "POST",
      url: "/auth/mfa/verify",
      headers: { authorization: `Bearer ${data.accessToken}` },
      payload: { code: totp(secret).generate() },
    });
    assert.equal(verified.statusCode, 200);
  }
  return data.accessToken as string;
}
async function gql(
  token: string,
  query: string,
  variables: Record<string, unknown> = {},
  pv?: number,
) {
  return (
    await app.inject({
      method: "POST",
      url: "/graphql",
      headers: {
        authorization: `Bearer ${token}`,
        ...(pv ? { "x-permission-version": String(pv) } : {}),
      },
      payload: { query, variables },
    })
  ).json();
}
const accessQuery =
  "query($s:ID!,$u:ID!){userAccess(siteId:$s,userId:$u){id version role active protected rules{key effect scope} delegations{key scope} effective{key decision{allowed scope rule}} audit{id reason version}}}";
async function snapshot(
  userId: string,
  siteId = ids.dg,
  token = tokens.super_admin!,
) {
  const r = await gql(token, accessQuery, { s: siteId, u: userId });
  assert.ok(r.data?.userAccess, JSON.stringify(r.errors));
  return r.data.userAccess;
}
const accessMutation = (save = false) =>
  `mutation($s:ID!,$u:ID!,$i:AccessChangeInput!){${save ? "saveAccess" : "previewAccess"}(siteId:$s,userId:$u,input:$i){version changes{key before{allowed scope rule} after{allowed scope rule}}}}`;
const changeInput = (s: any, patch: any = {}) => ({
  expectedVersion: s.version,
  role: s.role,
  active: s.active,
  rules: s.rules,
  delegations: s.delegations,
  reason: "Reviewed synthetic test change",
  ...patch,
});
async function foundation(
  token: string,
  operation: string,
  input: Record<string, unknown>,
  siteId = ids.dg,
) {
  return gql(
    token,
    "mutation($s:ID!,$op:String!,$i:FoundationInput!){saveFoundation(siteId:$s,operation:$op,input:$i){id status version}}",
    { s: siteId, op: operation, i: input },
  );
}
before(
  async () => {
    const root = process.env.TEST_MIGRATION_DATABASE_URL!;
    if (!root || new URL(root).pathname != "/hr_test")
      throw Error("Isolated real PostgreSQL test configuration required");
    control = pool(root, 1);
    dbName = `hr_test_${randomBytes(8).toString("hex")}`;
    await control.query(`CREATE DATABASE ${dbName}`);
    const url = (base: string) => {
      const u = new URL(base);
      u.pathname = `/${dbName}`;
      return u.toString();
    };
    await migrate(url(root));
    await seed(url(root), password);
    owner = pool(url(root), 1);
    runtime = pool(url(process.env.TEST_DATABASE_URL!), 2);
    authPool = pool(url(process.env.TEST_AUTH_DATABASE_URL!), 2);
    const config = {
      NODE_ENV: "test" as const,
      PORT: 4000,
      DATABASE_URL: url(process.env.TEST_DATABASE_URL!),
      AUTH_DATABASE_URL: url(process.env.TEST_AUTH_DATABASE_URL!),
      LOGIN_ORGANIZATION_ID: ids.org,
      WEB_ORIGIN: "http://localhost:5173",
      COOKIE_SECURE: "true" as const,
      ENCRYPTION_KEY: encryptionKey,
      REDIS_URL: "redis://localhost:56379",
    };
    app = await createApp(config, runtime, authPool, false);
    auth = new AuthService(authPool, config);
    for (const [role, email] of [
      ["super_admin", "superadmin"],
      ["admin", "admin"],
      ["hr", "hr"],
      ["jr_hr", "junior"],
      ["employee", "employee"],
      ["manager", "manager"],
      ["supervisor", "supervisor"],
    ])
      tokens[role!] = await signIn(`${email}@example.test`);
  },
  { timeout: 60000 },
);
after(async () => {
  await app?.close();
  await Promise.all([owner?.end(), runtime?.end(), authPool?.end()]);
  if (control && dbName) {
    await control.query(`DROP DATABASE IF EXISTS ${dbName}`);
    await control.end();
  }
});
test("catalogue parity, complete product separation, role defaults and field filters", async () => {
  assert.equal(new Set(permissionKeys).size, permissionKeys.length);
  assert.deepEqual(
    (await owner.query("SELECT id FROM app.module_catalogue ORDER BY id")).rows
      .map((r) => r.id)
      .sort(),
    catalogue.map((m) => m.id).sort(),
  );
  for (const role of [
    "super_admin",
    "admin",
    "hr",
    "jr_hr",
    "employee",
    "manager",
    "supervisor",
  ]) {
    const r = await gql(
      tokens[role]!,
      'query($s:ID!){scope(siteId:$s){capabilities modules{id available}} employee(siteId:$s,id:"' +
        ids.employeeProfile +
        '"){id salary bank phone}}',
      { s: ids.dg },
    );
    assert.ok(r.data, JSON.stringify(r.errors));
    const caps = r.data.scope.capabilities;
    assert.ok(caps.includes("my_payroll.view"));
    // Payroll roles (2026-09-26): HR prepares and sends for approval; only
    // Admin and Super Admin give the final approval.
    assert.equal(
      caps.includes("payroll.view"),
      ["super_admin", "admin", "hr"].includes(role),
    );
    assert.equal(
      caps.includes("payroll.approve"),
      ["super_admin", "admin"].includes(role),
    );
    if (["hr", "jr_hr", "employee", "manager", "supervisor"].includes(role))
      assert.ok(!caps.includes("access.manage"));
    if (role === "jr_hr") {
      assert.ok(!caps.includes("employees.approve"));
      assert.ok(!caps.includes("employees.export"));
    }
    if (role === "super_admin") {
      assert.equal(r.data.employee.salary, "42000.00");
      assert.equal(r.data.employee.bank, "DEMO-ONLY-1234");
    } else if (r.data.employee) {
      assert.equal(r.data.employee.salary, null);
      assert.equal(r.data.employee.bank, null);
    }
    assert.equal(
      r.data.scope.modules.find((m: any) => m.id === "payroll").available,
      true,
    );
  }
});
test("own vs explicitly assigned team, field-scoped team, supervisor has no implicit authority", async () => {
  const query =
    'query($s:ID!){employees(siteId:$s){nodes{id phone department}} employee(siteId:$s,id:"' +
    ids.adminEmployee +
    '"){id}}';
  const m = await gql(tokens.manager!, query, { s: ids.dg });
  assert.deepEqual(
    m.data.employees.nodes.map((e: any) => e.id),
    [ids.employeeProfile],
  );
  assert.equal(m.data.employee, null);
  assert.equal(m.data.employees.nodes[0].phone, null);
  assert.equal(m.data.employees.nodes[0].department, "Engineering");
  for (const role of ["employee", "supervisor"])
    assert.equal(
      (await gql(tokens[role]!, query, { s: ids.dg })).errors[0].extensions
        .code,
      "FORBIDDEN",
    );
});
test("team directory excludes self and dependency field scope cannot borrow My HR visibility", async () => {
  const profile = "40000000-0000-4000-8000-000000000013";
  await owner.query(
    "INSERT INTO app.employees(id,organization_id,user_id,employee_code,display_name,work_email,job_title,department) VALUES($1,$2,$3,'MGR-TEST','Manager Fixture','manager@example.test','Manager','Engineering')",
    [profile, ids.org, ids.manager],
  );
  await owner.query(
    "INSERT INTO app.site_assignments(organization_id,site_id,employee_id,starts_on) VALUES($1,$2,$3,'2024-01-01')",
    [ids.org, ids.dg, profile],
  );
  await owner.query(
    "INSERT INTO app.employee_sensitive_fields(organization_id,employee_id,field,value) VALUES($1,$2,'salary','50000.00')",
    [ids.org, profile],
  );
  await owner.query(
    "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,'employees.field.salary','allow','own')",
    [ids.org, ids.dg, ids.manager],
  );
  const result = await gql(
    tokens.manager!,
    "query($s:ID!){employees(siteId:$s){nodes{id}} myProfile(siteId:$s){id salary}}",
    { s: ids.dg },
  );
  assert.deepEqual(
    result.data.employees.nodes.map((e: any) => e.id),
    [ids.employeeProfile],
  );
  assert.equal(result.data.myProfile.id, profile);
  assert.equal(result.data.myProfile.salary, null);
});
test("direct access endpoints and cross-site inputs cannot bypass authorization", async () => {
  for (const role of ["hr", "jr_hr", "employee", "manager", "supervisor"]) {
    const r = await gql(
      tokens[role]!,
      "query($s:ID!){accessUsers(siteId:$s){users{id}}}",
      { s: ids.dg },
    );
    assert.equal(r.errors[0].extensions.code, "FORBIDDEN");
  }
  const forbidden = await gql(
    tokens.admin!,
    "query($s:ID!){accessUsers(siteId:$s){users{id}}}",
    { s: ids.rg },
  );
  assert.equal(forbidden.errors[0].extensions.code, "FORBIDDEN");
  const r = await app.inject({
    method: "GET",
    url: `/files/exports/${randomUUID()}?siteId=${ids.dg}`,
    headers: { authorization: `Bearer ${tokens.employee}` },
  });
  assert.equal(r.statusCode, 403);
  for (const role of ["hr", "admin", "employee"]) {
    const r = await app.inject({
      method: "POST",
      url: "/analytics/tools/employee-summary",
      headers: { authorization: `Bearer ${tokens[role]}` },
      payload: { siteId: ids.dg },
    });
    assert.notEqual(r.statusCode, 200);
  }
  assert.equal(
    (
      await gql(
        tokens.hr!,
        'mutation($s:ID!,$i:FoundationInput!){saveFoundation(siteId:$s,operation:"reference",input:$i){id}}',
        { s: "all", i: { kind: "department", name: "Invalid" } },
      )
    ).errors[0].extensions.code,
    "BAD_INPUT",
  );
});
test("All Sites requires explicit organization reporting and never authorizes operational writes", async () => {
  const r = await gql(
    tokens.super_admin!,
    "query($s:ID!){organizationReport(siteId:$s){readOnly sites{id employees}}}",
    { s: ids.dg },
  );
  assert.equal(r.data.organizationReport.readOnly, true);
  assert.equal(r.data.organizationReport.sites.length, 2);
  const before = await snapshot(ids.employee);
  const invalid = await gql(tokens.super_admin!, accessMutation(), {
    s: ids.dg,
    u: ids.employee,
    i: changeInput(before, {
      rules: [
        { key: "employees.edit", effect: "allow", scope: "organization" },
      ],
    }),
  });
  assert.equal(invalid.errors[0].extensions.code, "BAD_INPUT");
});
test("employee cannot edit directly; profile request is pending until independent authorized approval", async () => {
  const direct = await gql(
    tokens.employee!,
    "mutation($s:ID!,$i:UpdateProfileInput!){updateProfile(siteId:$s,input:$i){id}}",
    {
      s: ids.dg,
      i: { employeeId: ids.employeeProfile, phone: "123", expectedVersion: 1 },
    },
  );
  assert.equal(direct.errors[0].extensions.code, "FORBIDDEN");
  const requested = await foundation(tokens.employee!, "request_profile", {
    phone: "+91 9876500000",
    expectedVersion: 1,
    reason: "Contact number changed",
  });
  assert.ok(requested.data, JSON.stringify(requested.errors));
  assert.equal(requested.data.saveFoundation.status, "pending");
  assert.equal(
    (
      await owner.query("SELECT phone FROM app.employees WHERE id=$1", [
        ids.employeeProfile,
      ])
    ).rows[0].phone,
    "",
  );
  const requestId = requested.data.saveFoundation.id;
  const junior = await foundation(tokens.jr_hr!, "review_profile", {
    id: requestId,
    expectedVersion: 1,
    approve: true,
    note: "Reviewed request details",
  });
  assert.equal(junior.errors[0].extensions.code, "FORBIDDEN");
  const approved = await foundation(tokens.hr!, "review_profile", {
    id: requestId,
    expectedVersion: 1,
    approve: true,
    note: "Verified updated contact",
  });
  assert.ok(approved.data, JSON.stringify(approved.errors));
  assert.equal(
    (
      await owner.query("SELECT phone FROM app.employees WHERE id=$1", [
        ids.employeeProfile,
      ])
    ).rows[0].phone,
    "+91 9876500000",
  );
  const stale = await foundation(tokens.hr!, "review_profile", {
    id: requestId,
    expectedVersion: 1,
    approve: true,
    note: "Repeated request review",
  });
  assert.equal(stale.errors[0].extensions.code, "CONFLICT");
  const forged = await foundation(tokens.employee!, "request_profile", {
    phone: "123",
    expectedVersion: 2,
    reason: "Trying employment edit",
    designation: "Director",
  });
  assert.equal(forged.errors[0].extensions.code, "BAD_INPUT");
});
test("photo and basic details travel in the reviewed request and apply only on approval", async () => {
  const rest = (token: string, method: "GET" | "POST", url: string, payload?: object) =>
    app.inject({
      method,
      url: `${url}${url.includes("?") ? "&" : "?"}siteId=${ids.dg}`,
      headers: { authorization: `Bearer ${token}` },
      ...(payload ? { payload } : {}),
    });
  const current = (
    await owner.query("SELECT phone,version FROM app.employees WHERE id=$1", [
      ids.employeeProfile,
    ])
  ).rows[0];
  // A phone photo with EXIF metadata; the server keeps only a 512 px derivative.
  const photo = await sharp({
    create: { width: 900, height: 600, channels: 3, background: "#2a7d4f" },
  })
    .jpeg()
    .withMetadata({ exif: { IFD0: { Copyright: "synthetic" } } })
    .toBuffer();
  const details = {
    dateOfBirth: "1990-05-17",
    bloodGroup: "O+",
    emergencyName: "Sita Mehta",
    emergencyRelation: "Mother",
    emergencyPhone: "+91 98765 43210",
  };
  const base = {
    phone: current.phone,
    expectedVersion: current.version,
    reason: "Adding my photo and details",
  };
  for (const bad of [
    { ...base, details: { ...details, salary: "1" } },
    { ...base, photo: Buffer.from("not an image").toString("base64") },
    { ...base, details: { dateOfBirth: "2999-01-01" } },
  ])
    assert.equal(
      (await rest(tokens.employee!, "POST", "/profile/requests", bad)).json()
        .code,
      "BAD_INPUT",
    );
  const sent = await rest(tokens.employee!, "POST", "/profile/requests", {
    ...base,
    details,
    photo: photo.toString("base64"),
  });
  assert.equal(sent.statusCode, 200, sent.body);
  const requestId = sent.json().id;
  const profileQuery =
    "query($s:ID!){myProfile(siteId:$s){personal{bloodGroup emergencyName} photoUpdatedAt}}";
  const before = await gql(tokens.employee!, profileQuery, { s: ids.dg });
  assert.equal(before.data.myProfile.personal.bloodGroup, null);
  assert.equal(before.data.myProfile.photoUpdatedAt, null);
  const proposed = await rest(
    tokens.employee!,
    "GET",
    `/profile/photos/request/${requestId}`,
  );
  assert.equal(proposed.headers["content-type"], "image/jpeg");
  const meta = await sharp(proposed.rawPayload).metadata();
  assert.deepEqual([meta.width, meta.height, meta.exif], [512, 512, undefined]);
  const listed = (
    await gql(
      tokens.hr!,
      "query($s:ID!){profileRequests(siteId:$s){id details{bloodGroup} hasPhoto currentDetails{bloodGroup}}}",
      { s: ids.dg },
    )
  ).data.profileRequests.find((r: any) => r.id === requestId);
  assert.deepEqual(listed, {
    id: requestId,
    details: { bloodGroup: "O+" },
    hasPhoto: true,
    currentDetails: { bloodGroup: null },
  });
  const approved = await foundation(tokens.hr!, "review_profile", {
    id: requestId,
    expectedVersion: 1,
    approve: true,
    note: "Verified photo and details",
  });
  assert.ok(approved.data, JSON.stringify(approved.errors));
  const after = await gql(tokens.employee!, profileQuery, { s: ids.dg });
  assert.equal(after.data.myProfile.personal.emergencyName, "Sita Mehta");
  assert.ok(after.data.myProfile.photoUpdatedAt);
  const photoUrl = `/profile/photos/employee/${ids.employeeProfile}`;
  for (const token of [tokens.employee!, tokens.hr!])
    assert.equal((await rest(token, "GET", photoUrl)).statusCode, 200);
  // No directory visibility, no photo; runtime cannot write photos directly.
  assert.equal((await rest(tokens.supervisor!, "GET", photoUrl)).statusCode, 404);
  await assert.rejects(() =>
    runtime.query(
      "INSERT INTO app.employee_photos(organization_id,employee_id,photo) VALUES($1,$2,'\\x00')",
      [ids.org, ids.employeeProfile],
    ),
  );
});
test("Jr HR drafts require approval; employee creation preserves legal-employer and dated assignment", async () => {
  const draft = await foundation(tokens.jr_hr!, "create_employee", {
    employeeCode: "TEST-004",
    displayName: "Draft Employee",
    workEmail: "draft@example.test",
    department: "Engineering",
    designation: "Site Engineer",
    phone: "",
    legalEmployerId: ids.employer,
    startsOn: "2026-01-01",
  });
  assert.equal(draft.data.saveFoundation.status, "draft");
  assert.equal(
    (
      await owner.query(
        "SELECT id FROM app.employees WHERE employee_code='TEST-004'",
      )
    ).rowCount,
    0,
  );
  const approve = await foundation(tokens.hr!, "approve_draft", {
    draftId: draft.data.saveFoundation.id,
    expectedVersion: 1,
  });
  assert.equal(approve.data.saveFoundation.status, "created");
  const row = (
    await owner.query(
      "SELECT * FROM app.site_assignments WHERE employee_id=$1",
      [approve.data.saveFoundation.id],
    )
  ).rows[0];
  assert.equal(row.site_id, ids.dg);
  const ended = await foundation(tokens.hr!, "end_assignment", {
    employeeId: approve.data.saveFoundation.id,
    expectedVersion: 1,
    assignmentId: row.id,
    endsOn: "2026-08-31",
  });
  assert.ok(ended.data, JSON.stringify(ended.errors));
  assert.equal(
    (
      await owner.query(
        "SELECT count(*)::int AS n FROM app.site_assignments WHERE id=$1",
        [row.id],
      )
    ).rows[0].n,
    1,
  );
});
test("site settings and references persist with optimistic versions; HR cannot manage settings", async () => {
  const input = {
    kind: "shift",
    name: "Evening shift",
    startTime: "14:00",
    endTime: "22:00",
  };
  assert.equal(
    (await foundation(tokens.hr!, "reference", input)).errors[0].extensions
      .code,
    "FORBIDDEN",
  );
  const r = await foundation(tokens.admin!, "reference", input);
  assert.ok(r.data, JSON.stringify(r.errors));
  const update = await foundation(tokens.admin!, "reference", {
    ...input,
    id: r.data.saveFoundation.id,
    expectedVersion: 1,
    name: "Evening coverage",
  });
  assert.ok(update.data);
  const conflict = await foundation(tokens.admin!, "reference", {
    ...input,
    id: r.data.saveFoundation.id,
    expectedVersion: 1,
  });
  assert.equal(conflict.errors[0].extensions.code, "CONFLICT");
});
test("dated site/reporting assignments and shifts persist; overlap and reporting cycles fail", async () => {
  const employee = (
    await owner.query(
      "SELECT id,user_id,version FROM app.employees WHERE employee_code='TEST-004'",
    )
  ).rows[0];
  // The previous test ended the original DG assignment. Add a new period without deleting it.
  let result = await foundation(tokens.hr!, "assign_site", {
    employeeId: employee.id,
    expectedVersion: employee.version,
    sourceSiteId: ids.dg,
    startsOn: "2026-09-01",
  });
  assert.ok(result.data, JSON.stringify(result.errors));
  let version = result.data.saveFoundation.version;
  const overlap = await foundation(tokens.hr!, "assign_site", {
    employeeId: employee.id,
    expectedVersion: version,
    sourceSiteId: ids.dg,
    startsOn: "2026-09-02",
  });
  assert.equal(overlap.errors[0].extensions.code, "ASSIGNMENT_OVERLAP");
  result = await foundation(tokens.hr!, "assign_team", {
    employeeId: employee.id,
    expectedVersion: version,
    managerId: ids.admin,
    startsOn: "2026-09-01",
  });
  assert.ok(result.data, JSON.stringify(result.errors));
  version = result.data.saveFoundation.version;
  const hr = (
    await owner.query("SELECT id,version FROM app.employees WHERE user_id=$1", [
      ids.admin,
    ])
  ).rows[0];
  const cycle = await foundation(tokens.hr!, "assign_team", {
    employeeId: hr.id,
    expectedVersion: hr.version,
    managerId: employee.user_id,
    startsOn: "2026-09-02",
  });
  assert.equal(cycle.errors[0].extensions.code, "REPORTING_CYCLE");
  result = await foundation(tokens.hr!, "assign_team", {
    employeeId: employee.id,
    expectedVersion: version,
    managerId: ids.manager,
    startsOn: "2026-09-10",
  });
  assert.ok(result.data, JSON.stringify(result.errors));
  version = result.data.saveFoundation.version;
  const history = (
    await owner.query(
      "SELECT manager_id,ends_on::text FROM app.team_assignments WHERE employee_id=$1 ORDER BY starts_on",
      [employee.id],
    )
  ).rows;
  assert.equal(history.length, 2);
  assert.equal(history[0].ends_on, "2026-09-09");
  const shift = (
    await owner.query(
      "SELECT id FROM app.site_reference_items WHERE site_id=$1 AND kind='shift' AND active LIMIT 1",
      [ids.dg],
    )
  ).rows[0];
  result = await foundation(tokens.hr!, "assign_shift", {
    employeeId: employee.id,
    expectedVersion: version,
    shiftId: shift.id,
  });
  assert.ok(result.data, JSON.stringify(result.errors));
  version = result.data.saveFoundation.version;
  assert.equal(
    (
      await owner.query(
        "SELECT shift_id FROM app.employee_site_details WHERE employee_id=$1",
        [employee.id],
      )
    ).rows[0].shift_id,
    shift.id,
  );
  result = await foundation(
    tokens.hr!,
    "assign_site",
    {
      employeeId: employee.id,
      expectedVersion: version,
      sourceSiteId: ids.dg,
      startsOn: "2026-09-01",
    },
    ids.rg,
  );
  assert.ok(result.data, JSON.stringify(result.errors));
  assert.equal(
    (
      await owner.query(
        "SELECT count(*)::int n FROM app.site_assignments WHERE employee_id=$1",
        [employee.id],
      )
    ).rows[0].n,
    3,
  );
});
test("Admin delegated grants work; self escalation, sensitive grants, templates and protected accounts fail", async () => {
  const employee = await snapshot(ids.employee);
  const allowed = await gql(tokens.admin!, accessMutation(), {
    s: ids.dg,
    u: ids.employee,
    i: changeInput(employee, {
      rules: [{ key: "employees.view", effect: "allow", scope: "team" }],
    }),
  });
  assert.ok(allowed.data, JSON.stringify(allowed.errors));
  for (const patch of [
    { role: "hr" },
    {
      rules: [
        { key: "employees.field.salary", effect: "allow", scope: "site" },
      ],
    },
    { delegations: [{ key: "employees.view", scope: "site" }] },
  ]) {
    const denied = await gql(tokens.admin!, accessMutation(), {
      s: ids.dg,
      u: ids.employee,
      i: changeInput(employee, patch),
    });
    assert.equal(denied.errors[0].extensions.code, "DELEGATION_LIMIT");
  }
  const self = await snapshot(ids.siteAdmin);
  assert.equal(
    (
      await gql(tokens.admin!, accessMutation(), {
        s: ids.dg,
        u: ids.siteAdmin,
        i: changeInput(self),
      })
    ).errors[0].extensions.code,
    "SELF_ESCALATION",
  );
  const superUser = await snapshot(ids.superAdmin);
  assert.equal(
    (
      await gql(tokens.admin!, accessMutation(), {
        s: ids.dg,
        u: ids.superAdmin,
        i: changeInput(superUser),
      })
    ).errors[0].extensions.code,
    "PROTECTED_ACCOUNT",
  );
});
test("explicit deny overrides a template; preview explains dependencies, save audits and rejects stale edits", async () => {
  const current = await snapshot(ids.junior);
  const input = changeInput(current, {
    rules: [{ key: "employees.view", effect: "deny", scope: "site" }],
  });
  const preview = await gql(tokens.super_admin!, accessMutation(), {
    s: ids.dg,
    u: ids.junior,
    i: input,
  });
  assert.ok(preview.data, JSON.stringify(preview.errors));
  assert.equal(
    preview.data.previewAccess.changes.find(
      (c: any) => c.key === "employees.view",
    ).after.rule,
    "explicit_deny",
  );
  assert.equal(
    preview.data.previewAccess.changes.find(
      (c: any) => c.key === "employees.edit",
    ).after.rule,
    "dependency:employees.view",
  );
  const save = await gql(tokens.super_admin!, accessMutation(true), {
    s: ids.dg,
    u: ids.junior,
    i: input,
  });
  assert.ok(save.data, JSON.stringify(save.errors));
  assert.ok(save.data.saveAccess.version > current.version);
  const stale = await gql(tokens.super_admin!, accessMutation(true), {
    s: ids.dg,
    u: ids.junior,
    i: input,
  });
  assert.equal(stale.errors[0].extensions.code, "CONFLICT");
  assert.equal(await auth.lookup(tokens.jr_hr!), null);
  const updated = await snapshot(ids.junior);
  assert.equal(updated.audit[0].reason, input.reason);
  tokens.jr_hr = await signIn("junior@example.test");
  assert.equal(
    (
      await gql(
        tokens.jr_hr!,
        "query($s:ID!){employees(siteId:$s){nodes{id}}}",
        { s: ids.dg },
      )
    ).errors[0].extensions.code,
    "FORBIDDEN",
  );
});
test("queued sensitive exports and old downloads are invalid after access changes", async () => {
  const q =
    "mutation($s:ID!,$f:[String!]!){queueExport(siteId:$s,fields:$f){id status}}";
  const denied = await gql(tokens.hr!, q, {
    s: ids.dg,
    f: ["displayName", "salary"],
  });
  assert.equal(denied.errors[0].extensions.code, "FORBIDDEN");
  const job = await gql(tokens.hr!, q, {
    s: ids.dg,
    f: ["displayName", "phone"],
  });
  assert.ok(job.data, JSON.stringify(job.errors));
  const id = job.data.queueExport.id;
  await owner.query("SELECT app.prepare_exports()");
  const file = await app.inject({
    method: "GET",
    url: `/files/exports/${id}?siteId=${ids.dg}`,
    headers: { authorization: `Bearer ${tokens.hr}` },
  });
  assert.equal(file.statusCode, 200);
  assert.ok(file.body.includes("Arjun Mehta"));
  assert.ok(!file.body.includes("42000"));
  const pending = await gql(tokens.hr!, q, { s: ids.dg, f: ["displayName"] });
  const hr = await snapshot(ids.admin);
  const changed = await gql(tokens.super_admin!, accessMutation(true), {
    s: ids.dg,
    u: ids.admin,
    i: changeInput(hr, { role: "employee" }),
  });
  assert.ok(changed.data, JSON.stringify(changed.errors));
  await owner.query("SELECT app.prepare_exports()");
  assert.equal(
    (
      await owner.query("SELECT status FROM app.export_jobs WHERE id=$1", [
        pending.data.queueExport.id,
      ])
    ).rows[0].status,
    "denied",
  );
  assert.equal(
    (
      await app.inject({
        method: "GET",
        url: `/files/exports/${id}?siteId=${ids.dg}`,
        headers: { authorization: `Bearer ${tokens.hr}` },
      })
    ).statusCode,
    401,
  );
  tokens.hr = await signIn("hr@example.test");
  const downgraded = await app.inject({
    method: "GET",
    url: `/files/exports/${id}?siteId=${ids.dg}`,
    headers: { authorization: `Bearer ${tokens.hr}` },
  });
  assert.equal(downgraded.statusCode, 403);
});
test("stale permission-version responses cannot be reused after membership changes", async () => {
  const token = tokens.manager!,
    a = (await auth.lookup(token))!;
  await owner.query(
    "UPDATE app.site_memberships SET active=false WHERE organization_id=$1 AND site_id=$2 AND user_id=$3",
    [ids.org, ids.dg, ids.manager],
  );
  const old = await gql(
    token,
    "query($s:ID!){scope(siteId:$s){capabilities}}",
    { s: ids.dg },
    a.permissionVersion,
  );
  assert.equal(old.errors[0].extensions.code, "SCOPE_CHANGED");
  const fresh = await gql(
    token,
    "query($s:ID!){scope(siteId:$s){capabilities}}",
    { s: ids.dg },
  );
  assert.equal(fresh.errors[0].extensions.code, "FORBIDDEN");
  await assert.rejects(() =>
    scoped(runtime, a, ids.dg, (c) => c.query("SELECT * FROM app.employees")),
  );
});
test("concurrent permission saves serialize and exactly one edit wins", async () => {
  const target = await snapshot(ids.supervisor);
  const proposals = ["my_leave.submit", "my_documents.export"].map((key) =>
    gql(tokens.super_admin!, accessMutation(true), {
      s: ids.dg,
      u: ids.supervisor,
      i: changeInput(target, {
        rules: [{ key, effect: "deny", scope: "own" }],
      }),
    }),
  );
  const results = await Promise.all(proposals);
  assert.equal(results.filter((r) => r.data?.saveAccess).length, 1);
  assert.equal(
    results.filter((r) => r.errors?.[0]?.extensions.code === "CONFLICT").length,
    1,
  );
});
test("Super Admin cannot self-escalate and self-service grants cannot escape own scope", async () => {
  const current = await snapshot(ids.superAdmin);
  const self = await gql(tokens.super_admin!, accessMutation(), {
    s: ids.dg,
    u: ids.superAdmin,
    i: changeInput(current, {
      rules: [
        ...current.rules,
        { key: "reports.export", effect: "allow", scope: "organization" },
      ],
    }),
  });
  assert.equal(self.errors[0].extensions.code, "SELF_ESCALATION");
  const target = await snapshot(ids.employee);
  const broad = await gql(tokens.super_admin!, accessMutation(), {
    s: ids.dg,
    u: ids.employee,
    i: changeInput(target, {
      rules: [{ key: "my_hr.view", effect: "allow", scope: "site" }],
    }),
  });
  assert.ok(broad.data, JSON.stringify(broad.errors));
  assert.equal(
    broad.data.previewAccess.changes.find((c: any) => c.key === "my_hr.view")
      .after.rule,
    "invalid_module_scope",
  );
});
test("module switches invalidate versions and concurrent site-settings edits conflict", async () => {
  const disabled = await foundation(tokens.super_admin!, "module", {
    moduleId: "leave",
    enabled: false,
    expectedVersion: 1,
  });
  assert.ok(disabled.data, JSON.stringify(disabled.errors));
  const snapshot = (
    await gql(
      tokens.super_admin!,
      "query($s:ID!){scope(siteId:$s){decisions{key decision{allowed rule}}}}",
      { s: ids.dg },
    )
  ).data.scope;
  assert.equal(
    snapshot.decisions.find((d: any) => d.key === "leave.view").decision.rule,
    "module_disabled",
  );
  const stale = await foundation(tokens.super_admin!, "module", {
    moduleId: "leave",
    enabled: true,
    expectedVersion: 1,
  });
  assert.equal(stale.errors[0].extensions.code, "CONFLICT");
  const enabled = await foundation(tokens.super_admin!, "module", {
    moduleId: "leave",
    enabled: true,
    expectedVersion: 2,
  });
  assert.ok(enabled.data, JSON.stringify(enabled.errors));
});
test("last recoverable Super Admin cannot be removed, denied management, or lose final site", async () => {
  const first = await snapshot(ids.superAdmin);
  const move = await gql(tokens.super_admin!, accessMutation(true), {
    s: ids.dg,
    u: ids.superAdmin,
    i: changeInput(first, { role: "admin", rules: [] }),
  });
  assert.ok(move.data, JSON.stringify(move.errors));
  tokens.super_admin = await signIn("superadmin@example.test");
  const last = await snapshot(ids.superAdmin, ids.rg);
  for (const patch of [
    { active: false },
    { role: "admin" },
    { rules: [{ key: "access.manage", effect: "deny", scope: "site" }] },
  ]) {
    const r = await gql(tokens.super_admin!, accessMutation(), {
      s: ids.rg,
      u: ids.superAdmin,
      i: changeInput(last, patch),
    });
    assert.equal(r.errors[0].extensions.code, "LAST_SUPER_ADMIN");
  }
});
