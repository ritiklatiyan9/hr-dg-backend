import { readFile } from "node:fs/promises";
import { parseEnv } from "node:util";
import sharp from "sharp";
import { DeleteObjectCommand } from "@aws-sdk/client-s3";
import { objectStorage } from "../../apps/api/src/files.js";
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { randomBytes, randomUUID } from "node:crypto";
import type pg from "pg";
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
    for (const user of [ids.superAdmin, ids.siteAdmin, ids.admin]) {
      for (const key of permissionKeys.filter(
        (k) =>
          k.startsWith("payroll.") ||
          k.startsWith("expenses.") ||
          k.startsWith("assets.") ||
          k.startsWith("helpdesk.") ||
          k.startsWith("announcements.") ||
          k.startsWith("documents."),
      ))
        await owner.query(
          "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,$4,'allow','site') ON CONFLICT(organization_id,site_id,user_id,key) DO UPDATE SET effect='allow',scope='site'",
          [ids.org, ids.dg, user, key],
        );
    }
    for (const key of [
      "grievances.view",
      "grievances.review",
      "grievances.manage",
      "grievances.field.confidential",
    ])
      await owner.query(
        "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,$4,'allow','site')",
        [ids.org, ids.dg, ids.admin, key],
      );
    await owner.query("INSERT INTO app.hr_case_handlers VALUES($1,$2,$3)", [
      ids.org,
      ids.dg,
      ids.admin,
    ]);
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
  if (owner) {
    const keys = (await owner.query("SELECT object_key FROM app.dwr_voice"))
      .rows;
    for (const r of keys)
      await objectStorage().send(
        new DeleteObjectCommand({
          Bucket: process.env.S3_BUCKET ?? "hr-private",
          Key: r.object_key,
        }),
      );
  }
  await app?.close();
  await Promise.all([owner?.end(), runtime?.end(), authPool?.end()]);
  if (control && dbName) {
    await control.query(`DROP DATABASE IF EXISTS ${dbName}`);
    await control.end();
  }
});

test("Phase 5 migrations load", async () =>
  assert.ok(
    (await owner.query("SELECT to_regclass('app.payroll_results') t")).rows[0]
      .t,
  ));
const mutation = async (
  role: string,
  module: string,
  operation: string,
  input: any,
  site = ids.dg,
) =>
  gql(
    tokens[role]!,
    `mutation($s:ID!,$o:String!,$i:JSON!){${module}Command(siteId:$s,operation:$o,input:$i)}`,
    { s: site, o: operation, i: input },
  );
const result = (r: any, key: string) => {
  assert.ok(r.data?.[key], JSON.stringify(r.errors));
  return r.data[key];
};
const failure = (r: any) => assert.ok(r.errors?.length, JSON.stringify(r));
const policy = {
  rounding: "half_up_line",
  accountantReview: true,
  policyVersion: "SYNTHETIC-ACCOUNTANT-REVIEW",
  assumptions: "Synthetic rules; no statutory deductions configured",
  lines: [
    {
      code: "BASE",
      label: "Base",
      kind: "earning",
      paise: "3000000",
      numerator: 1,
      denominator: 1,
    },
  ],
};
const reason = "Synthetic reviewed workflow evidence";
let pay: any, employment: string;
test("payroll separation, idempotency, concurrent edits, publication and wrong-person downloads", async () => {
  employment = (
    await owner.query(
      "SELECT id FROM app.employment_records WHERE employee_id=$1",
      [ids.employeeProfile],
    )
  ).rows[0].id;
  const input = {
    clientId: randomUUID(),
    expectedVersion: 0,
    employmentId: employment,
    periodStart: "2026-08-01",
    periodEnd: "2026-08-31",
    calculation: policy,
    allocations: [{ siteId: ids.dg, paise: "3000000" }],
    attendanceNote: "Explicit approved paid units; no GPS deductions",
    reason,
  };
  for (const role of ["employee", "jr_hr", "manager", "supervisor"])
    failure(await mutation(role, "payroll", "save", input));
  pay = result(
    await mutation("hr", "payroll", "save", input),
    "payrollCommand",
  );
  assert.deepEqual(
    result(await mutation("hr", "payroll", "save", input), "payrollCommand"),
    pay,
  );
  failure(
    await mutation("hr", "payroll", "save", {
      ...input,
      clientId: randomUUID(),
    }),
  );
  failure(
    await mutation("hr", "payroll", "save", {
      ...input,
      clientId: randomUUID(),
      periodStart: "2026-08-15",
    }),
  );
  failure(
    await mutation("hr", "payroll", "save", {
      ...input,
      clientId: randomUUID(),
      periodStart: "2026-09-01",
      periodEnd: "2026-09-30",
      csv: "bad,csv",
    }),
  );
  const edits = await Promise.all([
    mutation("hr", "payroll", "save", {
      ...input,
      id: pay.id,
      expectedVersion: pay.version,
      clientId: randomUUID(),
    }),
    mutation("hr", "payroll", "save", {
      ...input,
      id: pay.id,
      expectedVersion: pay.version,
      clientId: randomUUID(),
    }),
  ]);
  assert.equal(edits.filter((x) => x.data?.payrollCommand).length, 1);
  pay = result(
    edits.find((x) => x.data?.payrollCommand),
    "payrollCommand",
  );
  let next = result(
    await mutation("hr", "payroll", "validate", {
      clientId: randomUUID(),
      expectedVersion: pay.version,
      id: pay.id,
      reason,
    }),
    "payrollCommand",
  );
  failure(
    await mutation("hr", "payroll", "review", {
      clientId: randomUUID(),
      expectedVersion: next.version,
      id: pay.id,
      reason,
    }),
  );
  failure(
    await mutation("admin", "payroll", "review", {
      clientId: randomUUID(),
      expectedVersion: 1,
      id: pay.id,
      reason,
    }),
  );
  next = result(
    await mutation("admin", "payroll", "review", {
      clientId: randomUUID(),
      expectedVersion: next.version,
      id: pay.id,
      reason,
    }),
    "payrollCommand",
  );
  failure(
    await mutation("admin", "payroll", "approve", {
      clientId: randomUUID(),
      expectedVersion: next.version,
      id: pay.id,
      reason,
    }),
  );
  const approval = {
    clientId: randomUUID(),
    expectedVersion: next.version,
    id: pay.id,
    reason,
  };
  const concurrent = await Promise.all([
    mutation("super_admin", "payroll", "approve", approval),
    mutation("super_admin", "payroll", "approve", {
      ...approval,
      clientId: randomUUID(),
    }),
  ]);
  assert.equal(concurrent.filter((x) => x.data?.payrollCommand).length, 1);
  next = result(
    concurrent.find((x) => x.data?.payrollCommand),
    "payrollCommand",
  );
  let snap = await gql(tokens.employee!, "query($s:ID!){payroll(siteId:$s)}", {
    s: ids.dg,
  });
  assert.equal(snap.data.payroll.results.length, 0);
  next = result(
    await mutation("admin", "payroll", "publish", {
      clientId: randomUUID(),
      expectedVersion: next.version,
      id: pay.id,
      reason,
    }),
    "payrollCommand",
  );
  pay = next;
  snap = await gql(tokens.employee!, "query($s:ID!){payroll(siteId:$s)}", {
    s: ids.dg,
  });
  assert.equal(snap.data.payroll.results[0].snapshot.netPaise, "3000000");
  failure(
    await mutation("hr", "payroll", "save", {
      ...input,
      id: pay.id,
      expectedVersion: pay.version,
      clientId: randomUUID(),
    }),
  );
  const url = `/payroll/${pay.id}/print?siteId=${ids.dg}`;
  assert.equal(
    (
      await app.inject({
        url,
        headers: { authorization: `Bearer ${tokens.employee}` },
      })
    ).statusCode,
    200,
  );
  assert.equal(
    (
      await app.inject({
        url,
        headers: { authorization: `Bearer ${tokens.manager}` },
      })
    ).statusCode,
    404,
  );
  assert.equal(
    (
      await app.inject({
        url: `/payroll/${randomUUID()}/print?siteId=${ids.dg}`,
        headers: { authorization: `Bearer ${tokens.employee}` },
      })
    ).statusCode,
    404,
  );
  const correction = result(
    await mutation("hr", "payroll", "save", {
      ...input,
      clientId: randomUUID(),
      previousId: pay.id,
    }),
    "payrollCommand",
  );
  assert.ok(correction.id !== pay.id);
  assert.equal(
    (
      await owner.query(
        "SELECT count(*)::int n FROM app.payroll_results WHERE employment_id=$1",
        [employment],
      )
    ).rows[0].n,
    2,
  );
});
test("historical transfer retains old payslip, salary field deny and revoked download", async () => {
  await owner.query(
    "UPDATE app.site_assignments SET ends_on='2026-08-31' WHERE employee_id=$1 AND site_id=$2",
    [ids.employeeProfile, ids.dg],
  );
  // Assignment edits invalidate versions; refresh login through real authentication.
  tokens.employee = await signIn("employee@example.test");
  tokens.hr = await signIn("hr@example.test");
  let response = await app.inject({
    url: `/payroll/${pay.id}/print?siteId=${ids.dg}`,
    headers: { authorization: `Bearer ${tokens.employee}` },
  });
  assert.equal(response.statusCode, 200);
  await owner.query(
    "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,'my_payroll.field.salary','deny','own')",
    [ids.org, ids.dg, ids.employee],
  );
  tokens.employee = await signIn("employee@example.test");
  response = await app.inject({
    url: `/payroll/${pay.id}/print?siteId=${ids.dg}`,
    headers: { authorization: `Bearer ${tokens.employee}` },
  });
  assert.equal(response.statusCode, 404);
  await owner.query(
    "DELETE FROM app.access_overrides WHERE user_id=$1 AND key='my_payroll.field.salary'",
    [ids.employee],
  );
  await owner.query(
    "UPDATE app.site_assignments SET ends_on=NULL WHERE employee_id=$1 AND site_id=$2",
    [ids.employeeProfile, ids.dg],
  );
  tokens.employee = await signIn("employee@example.test");
  tokens.hr = await signIn("hr@example.test");
});
const saveHr = async (
  role: string,
  kind: string,
  payload: any,
  extra: any = {},
) =>
  result(
    await mutation(role, "hr", "save", {
      clientId: randomUUID(),
      expectedVersion: 0,
      kind,
      payload,
      note: reason,
      ...extra,
    }),
    "hrCommand",
  );
const act = async (role: string, r: any, action: string, extra: any = {}) =>
  result(
    await mutation(role, "hr", "action", {
      clientId: randomUUID(),
      expectedVersion: r.version,
      id: r.id,
      action,
      note: reason,
      ...extra,
    }),
    "hrCommand",
  );
test("confidential grievance is invisible to reporting manager and unrelated admin; employee-handler-employee resolution", async () => {
  const configured = result(
    await mutation("hr", "hr", "handlers", {
      clientId: randomUUID(),
      expectedVersion: 0,
      userIds: [ids.admin],
      note: reason,
    }),
    "hrCommand",
  );
  assert.equal(configured.version, 1);
  failure(
    await mutation("hr", "hr", "handlers", {
      clientId: randomUUID(),
      expectedVersion: 1,
      userIds: [ids.manager],
      note: reason,
    }),
  );
  failure(
    await mutation("hr", "hr", "handlers", {
      clientId: randomUUID(),
      expectedVersion: 0,
      userIds: [],
      note: reason,
    }),
  );
  let r = await saveHr("employee", "grievance", {
    subject: "Confidential fixture",
    description: "Synthetic private case evidence",
  });
  r = await act("employee", r, "submit");
  for (const role of [
    "manager",
    "supervisor",
    "admin",
    "super_admin",
    "jr_hr",
  ]) {
    const s = await gql(
      tokens[role]!,
      'query($s:ID!){hrRecords(siteId:$s,kind:"grievance")}',
      { s: ids.dg },
    );
    assert.equal(s.data.hrRecords.records.length, 0);
    failure(
      await mutation(role, "hr", "action", {
        clientId: randomUUID(),
        expectedVersion: r.version,
        id: r.id,
        action: "start",
        note: reason,
      }),
    );
  }
  r = await act("hr", r, "start");
  r = await act("hr", r, "resolve");
  r = await act("employee", r, "close");
  assert.equal(r.status, "closed");
  const inbox = (
    await owner.query(
      "SELECT user_id FROM app.inbox_items WHERE entity_id=$1",
      [r.id],
    )
  ).rows;
  assert.ok(inbox.every((x) => [ids.employee, ids.admin].includes(x.user_id)));
});
test("expense requires ready own-parent receipt, independent decision, one settlement and persisted employee response", async () => {
  const payload = {
    amountPaise: "12345",
    date: "2026-09-01",
    category: "Travel",
    description: "Synthetic approved travel fixture",
  };
  let r = await saveHr("employee", "expense", payload);
  failure(
    await mutation("employee", "hr", "action", {
      clientId: randomUUID(),
      expectedVersion: r.version,
      id: r.id,
      action: "submit",
      note: reason,
    }),
  );
  const f = (
    await owner.query(
      "INSERT INTO app.private_files(organization_id,site_id,employee_id,owner_id,client_id,purpose,parent_id,declared_type,byte_limit,object_key,status) VALUES($1,$2,$3,$4,$5,'hr',$6,'image/jpeg',100,$7,'ready') RETURNING id",
      [
        ids.org,
        ids.dg,
        ids.employeeProfile,
        ids.employee,
        randomUUID(),
        r.id,
        `synthetic/${randomUUID()}`,
      ],
    )
  ).rows[0];
  r = result(
    await mutation("employee", "hr", "save", {
      clientId: randomUUID(),
      expectedVersion: r.version,
      id: r.id,
      kind: "expense",
      payload,
      attachments: [f.id],
      note: reason,
    }),
    "hrCommand",
  );
  r = await act("employee", r, "submit");
  failure(
    await mutation("employee", "hr", "action", {
      clientId: randomUUID(),
      expectedVersion: r.version,
      id: r.id,
      action: "approve",
      note: reason,
    }),
  );
  r = await act("hr", r, "approve");
  r = await act("hr", r, "settle");
  assert.equal(r.status, "settled");
  failure(
    await mutation("hr", "hr", "action", {
      clientId: randomUUID(),
      expectedVersion: r.version,
      id: r.id,
      action: "settle",
      note: reason,
    }),
  );
  assert.equal(
    (
      await app.inject({
        url: `/files/attachments/${f.id}?siteId=${ids.dg}`,
        headers: { authorization: `Bearer ${tokens.manager}` },
      })
    ).statusCode,
    404,
  );
  const s = await gql(
    tokens.employee!,
    'query($s:ID!){hrRecords(siteId:$s,kind:"expense")}',
    { s: ids.dg },
  );
  assert.equal(s.data.hrRecords.records[0].history[0].event, "settle");
});
test("asset register → assign → employee acknowledge → return → clearance", async () => {
  let r = await saveHr("hr", "asset", {
    assetTag: "SYNTHETIC-LAPTOP-1",
    name: "Test laptop",
    serialNumber: "SYNTHETIC",
    condition: "Checked working",
  });
  r = await act("hr", r, "submit");
  r = await act("hr", r, "assign", { employeeId: ids.employeeProfile });
  failure(
    await mutation("manager", "hr", "action", {
      clientId: randomUUID(),
      expectedVersion: r.version,
      id: r.id,
      action: "acknowledge",
      note: reason,
    }),
  );
  r = await act("employee", r, "acknowledge");
  r = await act("employee", r, "return");
  r = await act("hr", r, "receive");
  r = await act("hr", r, "clear");
  assert.equal(r.status, "cleared");
});
test("announcement selected audience, independent publication and acknowledgment", async () => {
  let r = await saveHr(
    "hr",
    "announcement",
    {
      title: "Synthetic policy notice",
      body: "Synthetic announcement content",
      expiresOn: "2027-01-01",
      acknowledgment: true,
    },
    { audience: [ids.employee] },
  );
  r = await act("hr", r, "submit");
  r = await act("admin", r, "publish");
  r = await act("employee", r, "acknowledge");
  assert.equal(
    (
      await owner.query(
        "SELECT count(*)::int n FROM app.hr_acknowledgments WHERE record_id=$1",
        [r.id],
      )
    ).rows[0].n,
    1,
  );
  const s = await gql(
    tokens.manager!,
    'query($s:ID!){hrRecords(siteId:$s,kind:"announcement")}',
    { s: ids.dg },
  );
  assert.equal(s.data.hrRecords.records.length, 0);
});
test("effective salary structures never overlap: a revision ends the running salary; lifecycle approvals preserve dates and expose promotion in profile", async () => {
  const st = {
    clientId: randomUUID(),
    expectedVersion: 0,
    employmentId: employment,
    startsOn: "2026-01-01",
    endsOn: "2026-12-31",
    calculation: policy,
    reason,
  };
  const structure = result(
    await mutation("hr", "payroll", "structure", st),
    "payrollCommand",
  );
  // A revision from June ends the running salary on 31 May; its amounts stay.
  const revised = result(
    await mutation("hr", "payroll", "structure", {
      ...st,
      clientId: randomUUID(),
      startsOn: "2026-06-01",
    }),
    "payrollCommand",
  );
  assert.deepEqual(revised.closed, [structure.id]);
  failure(
    await mutation("hr", "payroll", "structure", {
      ...st,
      clientId: randomUUID(),
      startsOn: "2026-06-01",
    }),
  );
  const base = {
    effectiveOn: "2026-01-01",
    details: "Synthetic effective-dated employment change",
    employmentId: employment,
    destinationSiteId: null,
    designation: "Senior specialist",
    department: "Operations",
    salaryStructureId: null,
  };
  for (const event of [
    "joining",
    "probation",
    "confirmation",
    "promotion",
    "salary_revision",
  ]) {
    let r = await saveHr(
      "hr",
      "lifecycle",
      {
        ...base,
        event,
        ...(event === "salary_revision"
          ? { salaryStructureId: structure.id }
          : {}),
      },
      { employeeId: ids.employeeProfile },
    );
    r = await act("hr", r, "submit");
    failure(
      await mutation("hr", "hr", "action", {
        clientId: randomUUID(),
        expectedVersion: r.version,
        id: r.id,
        action: "approve",
        note: reason,
      }),
    );
    r = await act("admin", r, "approve");
    assert.equal(r.status, "approved");
  }
  const profile = await gql(
    tokens.employee!,
    "query($s:ID!){myProfile(siteId:$s){jobTitle department}}",
    { s: ids.dg },
  );
  assert.equal(profile.data.myProfile.jobTitle, "Senior specialist");
});
test("restricted bank documents, ready evidence, configured expiry reminders and queue respect field access", async () => {
  const today = (
    await owner.query(
      "SELECT (now() AT TIME ZONE 'Asia/Kolkata')::date::text d",
    )
  ).rows[0].d;
  let r = await saveHr(
    "hr",
    "document",
    {
      title: "Synthetic bank confirmation",
      category: "bank",
      expiresOn: today,
      description: "Synthetic restricted file, no real bank details",
    },
    { employeeId: ids.employeeProfile },
  );
  const f = (
    await owner.query(
      "INSERT INTO app.private_files(organization_id,site_id,employee_id,owner_id,client_id,purpose,parent_id,declared_type,byte_limit,object_key,status) VALUES($1,$2,$3,$4,$5,'hr',$6,'image/jpeg',100,$7,'ready') RETURNING id",
      [
        ids.org,
        ids.dg,
        ids.employeeProfile,
        ids.admin,
        randomUUID(),
        r.id,
        `synthetic/${randomUUID()}`,
      ],
    )
  ).rows[0];
  r = result(
    await mutation("hr", "hr", "save", {
      clientId: randomUUID(),
      expectedVersion: r.version,
      id: r.id,
      kind: "document",
      payload: {
        title: "Synthetic bank confirmation",
        category: "bank",
        expiresOn: today,
        description: "Synthetic restricted file, no real bank details",
      },
      attachments: [f.id],
      note: reason,
    }),
    "hrCommand",
  );
  r = await act("hr", r, "submit");
  const queue = await gql(
    tokens.admin!,
    "query($s:ID!){approvalQueue(siteId:$s)}",
    { s: ids.dg },
  );
  assert.ok(queue.data.approvalQueue.items.some((x: any) => x.id === r.id));
  const junior = await gql(
    tokens.jr_hr!,
    'query($s:ID!){hrRecords(siteId:$s,kind:"document")}',
    { s: ids.dg },
  );
  assert.equal(junior.data.hrRecords.records.length, 0);
  r = await act("admin", r, "approve");
  result(
    await mutation("hr", "hr", "reminders", {
      clientId: randomUUID(),
      expectedVersion: 0,
      days: 30,
      note: reason,
    }),
    "hrCommand",
  );
  failure(
    await mutation("hr", "hr", "reminders", {
      clientId: randomUUID(),
      expectedVersion: 0,
      days: 10,
      note: reason,
    }),
  );
  await owner.query("SELECT app.hr_tick()");
  await owner.query("SELECT app.hr_tick()");
  assert.equal(
    (
      await owner.query(
        "SELECT count(*)::int n FROM app.inbox_items WHERE entity_id=$1 AND user_id=$2 AND event_type LIKE 'hr.document.expiry.%'",
        [r.id, ids.employee],
      )
    ).rows[0].n,
    1,
  );
  assert.equal(
    (
      await owner.query(
        "SELECT count(*)::int n FROM app.inbox_items WHERE entity_id=$1 AND user_id=$2",
        [r.id, ids.junior],
      )
    ).rows[0].n,
    0,
  );
});
test("site payroll grants cannot borrow team salary access or allocate without an authorized historical assignment", async () => {
  await owner.query(
    "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) SELECT $1,$2,$3,key,'allow','team' FROM app.permission_catalogue WHERE module_id='payroll'",
    [ids.org, ids.dg, ids.manager],
  );
  tokens.manager = await signIn("manager@example.test");
  const s = await gql(tokens.manager!, "query($s:ID!){payroll(siteId:$s)}", {
    s: ids.dg,
  });
  assert.equal(s.data.payroll.results.length, 0);
  failure(
    await mutation("hr", "payroll", "save", {
      clientId: randomUUID(),
      expectedVersion: 0,
      employmentId: employment,
      periodStart: "2026-10-01",
      periodEnd: "2026-10-31",
      calculation: policy,
      allocations: [{ siteId: ids.otherSite, paise: "3000000" }],
      attendanceNote: reason,
      reason,
    }),
  );
});
test("approved transfer changes only dated assignments, preserves old payroll site and requires destination authority; exit respects clearance", async () => {
  await owner.query(
    "UPDATE app.site_assignments SET ends_on='2025-12-31' WHERE employee_id=$1 AND site_id=$2",
    [ids.employeeProfile, ids.rg],
  );
  tokens.employee = await signIn("employee@example.test");
  let r = await saveHr(
    "hr",
    "lifecycle",
    {
      event: "transfer",
      effectiveOn: "2026-10-01",
      details: "Synthetic future transfer preserves history",
      employmentId: employment,
      destinationSiteId: ids.rg,
      designation: "",
      department: "",
      salaryStructureId: null,
    },
    { employeeId: ids.employeeProfile },
  );
  r = await act("hr", r, "submit");
  failure(
    await mutation("admin", "hr", "action", {
      clientId: randomUUID(),
      expectedVersion: r.version,
      id: r.id,
      action: "approve",
      note: reason,
    }),
  );
  r = await act("super_admin", r, "approve");
  assert.equal(r.status, "approved");
  const assignments = (
    await owner.query(
      "SELECT site_id,starts_on::text,ends_on::text FROM app.site_assignments WHERE employee_id=$1 ORDER BY starts_on",
      [ids.employeeProfile],
    )
  ).rows;
  assert.ok(
    assignments.some((x) => x.site_id === ids.dg && x.ends_on === "2026-09-30"),
  );
  assert.ok(
    assignments.some(
      (x) => x.site_id === ids.rg && x.starts_on === "2026-10-01",
    ),
  );
  assert.equal(
    (
      await owner.query("SELECT site_id FROM app.payroll_results WHERE id=$1", [
        pay.id,
      ])
    ).rows[0].site_id,
    ids.dg,
  );
  tokens.employee = await signIn("employee@example.test");
  let exit = await saveHr(
    "hr",
    "lifecycle",
    {
      event: "exit",
      effectiveOn: "2026-11-01",
      details: "Synthetic exit after asset clearance",
      employmentId: employment,
      destinationSiteId: null,
      designation: "",
      department: "",
      salaryStructureId: null,
    },
    { employeeId: ids.employeeProfile },
  );
  exit = await act("hr", exit, "submit");
  exit = await act("super_admin", exit, "approve");
  assert.equal(exit.status, "approved");
  assert.equal(
    (
      await owner.query(
        "SELECT ends_on::text FROM app.employment_records WHERE id=$1",
        [employment],
      )
    ).rows[0].ends_on,
    "2026-11-01",
  );
});

test("historical own documents/assets survive transfer, while membership revocation removes access", async () => {
  await owner.query(
    "UPDATE app.site_assignments SET ends_on='2026-08-31' WHERE employee_id=$1 AND site_id=$2",
    [ids.employeeProfile, ids.dg],
  );
  tokens.employee = await signIn("employee@example.test");
  for (const kind of ["document", "asset"]) {
    const response = await gql(
      tokens.employee!,
      "query($s:ID!,$k:String!){hrRecords(siteId:$s,kind:$k)}",
      { s: ids.dg, k: kind },
    );
    assert.ok(
      response.data?.hrRecords.records.length > 0,
      JSON.stringify(response.errors),
    );
  }
  await owner.query(
    "UPDATE app.site_memberships SET active=false WHERE user_id=$1 AND site_id=$2",
    [ids.employee, ids.dg],
  );
  tokens.employee = await signIn("employee@example.test");
  const denied = await gql(
    tokens.employee!,
    'query($s:ID!){hrRecords(siteId:$s,kind:"asset")}',
    { s: ids.dg },
  );
  failure(denied);
  await owner.query(
    "UPDATE app.site_memberships SET active=true WHERE user_id=$1 AND site_id=$2",
    [ids.employee, ids.dg],
  );
  await owner.query(
    "UPDATE app.site_assignments SET ends_on='2026-09-30' WHERE employee_id=$1 AND site_id=$2",
    [ids.employeeProfile, ids.dg],
  );
  tokens.employee = await signIn("employee@example.test");
});

test("queued notifications recheck inbox permission without erasing durable records", async () => {
  const c = await owner.connect();
  try {
    await c.query("BEGIN");
    await c.query("UPDATE app.inbox_items SET push_status='delivered'");
    const inbox = (
      await c.query(
        "UPDATE app.inbox_items SET push_status='pending' WHERE id=(SELECT id FROM app.inbox_items WHERE user_id=$1 AND entity_id=$2 LIMIT 1) RETURNING id",
        [ids.employee, pay.id],
      )
    ).rows[0];
    assert.ok(inbox);
    await c.query(
      "INSERT INTO app.push_devices(organization_id,site_id,user_id,token_ciphertext,platform) VALUES($1,$2,$3,'synthetic-test-never-send','android')",
      [ids.org, ids.dg, ids.employee],
    );
    assert.ok(
      (await c.query("SELECT * FROM app.pending_operation_push()")).rows.some(
        (r) => r.inbox_id === inbox.id,
      ),
    );
    await c.query(
      "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,'inbox.view','deny','own')",
      [ids.org, ids.dg, ids.employee],
    );
    assert.equal(
      (await c.query("SELECT * FROM app.pending_operation_push()")).rows.length,
      0,
    );
    assert.equal(
      (
        await c.query(
          "SELECT count(*)::int n FROM app.inbox_items WHERE id=$1",
          [inbox.id],
        )
      ).rows[0].n,
      1,
    );
  } finally {
    await c.query("ROLLBACK");
    c.release();
  }
});

test("real HR document upload retries, strips metadata and rejects revoked downloads", async () => {
  const local = parseEnv(await readFile(".env", "utf8"));
  assert.ok(
    ["localhost", "127.0.0.1"].includes(new URL(local.S3_ENDPOINT!).hostname),
  );
  for (const k of [
    "S3_ENDPOINT",
    "S3_ACCESS_KEY",
    "S3_SECRET_KEY",
    "S3_BUCKET",
  ])
    process.env[k] = local[k];
  let r = await saveHr("employee", "document", {
    title: "Synthetic private document",
    category: "general",
    expiresOn: null,
    description: "Synthetic ready attachment test",
  });
  const bytes = await sharp({
    create: { width: 32, height: 32, channels: 3, background: "#277052" },
  })
    .withMetadata({ orientation: 1 })
    .jpeg()
    .toBuffer();
  const intent = result(
    await mutation("employee", "hr", "fileIntent", {
      id: r.id,
      expectedVersion: r.version,
      clientId: randomUUID(),
      type: "image/jpeg",
      bytes: bytes.length,
    }),
    "hrCommand",
  );
  const upload = () =>
    app.inject({
      method: "POST",
      url: `/files/intents/${intent.id}/content?siteId=${ids.dg}`,
      headers: {
        authorization: `Bearer ${tokens.employee}`,
        "content-type": "application/octet-stream",
      },
      payload: bytes,
    });
  const download = () =>
    app.inject({
      url: `/files/attachments/${intent.id}?siteId=${ids.dg}`,
      headers: { authorization: `Bearer ${tokens.employee}` },
    });
  try {
    for (let i = 0; i < 2; i++) {
      const response = await upload();
      assert.equal(response.statusCode, 200, response.body);
      assert.equal(response.json().status, "ready");
    }
    const file = await download();
    assert.equal(file.statusCode, 200, file.body);
    assert.equal((await sharp(file.rawPayload).metadata()).exif, undefined);
    assert.equal(
      (
        await app.inject({
          url: `/files/attachments/${intent.id}?siteId=${ids.dg}`,
          headers: { authorization: `Bearer ${tokens.manager}` },
        })
      ).statusCode,
      404,
    );
    await owner.query(
      "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,'my_documents.export','deny','own')",
      [ids.org, ids.dg, ids.employee],
    );
    tokens.employee = await signIn("employee@example.test");
    assert.equal((await download()).statusCode, 403);
  } finally {
    await owner.query(
      "DELETE FROM app.access_overrides WHERE user_id=$1 AND key='my_documents.export'",
      [ids.employee],
    );
    const key = (
      await owner.query(
        "SELECT object_key FROM app.private_files WHERE id=$1",
        [intent.id],
      )
    ).rows[0].object_key;
    for (const suffix of ["content", "quarantine"])
      await objectStorage().send(
        new DeleteObjectCommand({
          Bucket: process.env.S3_BUCKET,
          Key: `${key}/${suffix}`,
        }),
      );
  }
});

test("policy publication is independent, audience-scoped and acknowledgment is idempotent", async () => {
  tokens.hr = await signIn("hr@example.test");
  tokens.employee = await signIn("employee@example.test");
  let r = await saveHr(
    "hr",
    "policy",
    {
      title: "Synthetic policy",
      body: "Synthetic policy only; no company rules inferred.",
      effectiveOn: "2026-09-01",
      acknowledgment: true,
    },
    { audience: [ids.employee] },
  );
  r = await act("hr", r, "submit");
  failure(
    await mutation("hr", "hr", "action", {
      id: r.id,
      expectedVersion: r.version,
      clientId: randomUUID(),
      action: "publish",
      note: reason,
    }),
  );
  r = await act("admin", r, "publish");
  const visible = await gql(
    tokens.employee!,
    'query($s:ID!){hrRecords(siteId:$s,kind:"policy")}',
    { s: ids.dg },
  );
  assert.ok(visible.data.hrRecords.records.some((x: any) => x.id === r.id));
  const hidden = await gql(
    tokens.manager!,
    'query($s:ID!){hrRecords(siteId:$s,kind:"policy")}',
    { s: ids.dg },
  );
  assert.ok(!hidden.data.hrRecords.records.some((x: any) => x.id === r.id));
  await act("employee", r, "acknowledge");
  await act("employee", r, "acknowledge");
  assert.equal(
    (
      await owner.query(
        "SELECT count(*)::int n FROM app.hr_acknowledgments WHERE record_id=$1 AND user_id=$2",
        [r.id, ids.employee],
      )
    ).rows[0].n,
    1,
  );
});
