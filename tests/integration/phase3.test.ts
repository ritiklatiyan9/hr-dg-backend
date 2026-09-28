import { readFile } from "node:fs/promises";
import { parseEnv } from "node:util";
import sharp from "sharp";
import { workDate } from "../../packages/authz/src/index.js";
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
const op = (role: string, operation: string, input: any, site = ids.dg) =>
  gql(
    tokens[role]!,
    "mutation($s:ID!,$o:String!,$i:JSON!){operate(siteId:$s,operation:$o,input:$i)}",
    { s: site, o: operation, i: input },
  );
const snap = (role: string, site = ids.dg) =>
  gql(tokens[role]!, "query($s:ID!){operations(siteId:$s)}", { s: site });
const rules = {
  allowOffline: true,
  offlineMaxHours: 24,
  maxAccuracyM: 40,
  freshnessSeconds: 90,
  clockSkewSeconds: 30,
  gapSeconds: 120,
  maxSessionHours: 18,
  lateGraceMinutes: 10,
  earlyGraceMinutes: 10,
  attendanceApproverId: ids.admin,
};
const coords = [
  [77.19, 28.59],
  [77.21, 28.59],
  [77.21, 28.61],
  [77.19, 28.61],
  [77.19, 28.59],
];
function value(r: any) {
  assert.ok(r.data?.operate, JSON.stringify(r.errors));
  return r.data.operate;
}
async function readyPhoto(role = "employee") {
  const id = value(
    await op(role, "fileIntent", {
      clientId: randomUUID(),
      purpose: "attendance",
      type: "image/jpeg",
      bytes: 12,
    }),
  ).id;
  await owner.query(
    "UPDATE app.private_files SET status='ready',scan_result='synthetic_database_fixture' WHERE id=$1",
    [id],
  );
  return id;
}
let duty: string, first: any, photo: string, typeId: string, leaveId: string;
const event = (
  kind: string,
  sequence: number,
  dutyId = duty,
  extra: any = {},
) => {
  const capturedAt = new Date().toISOString();
  return {
    clientEventId: randomUUID(),
    dutyId,
    sequence,
    kind,
    capturedAt,
    payloadVersion: 1,
    policyVersion: 1,
    geofenceVersion: 1,
    photoId: photo,
    location: {
      latitude: 28.6,
      longitude: 77.2,
      accuracyM: 10,
      observedAt: capturedAt,
    },
    ...extra,
  };
};
test("site policy is required, validates approvers and geofence units/version", async () => {
  const unconfigured = await op(
    "employee",
    "event",
    event("IN", 1, randomUUID()),
  );
  assert.equal(
    unconfigured.errors[0].extensions.code,
    "CONFIGURATION_REQUIRED",
  );
  value(
    await op("super_admin", "policy", {
      rules,
      expectedVersion: 0,
      reason: "Synthetic attendance policy only",
    }),
  );
  value(
    await op("super_admin", "geofence", {
      coordinates: coords,
      label: "Synthetic test boundary",
      expectedVersion: 0,
      reason: "Synthetic test polygon only",
    }),
  );
  const conflict = await op("super_admin", "policy", {
    rules,
    expectedVersion: 0,
    reason: "Conflicting test policy change",
  });
  assert.equal(conflict.errors[0].extensions.code, "CONFLICT");
  assert.equal(
    (
      await op("employee", "policy", {
        rules,
        expectedVersion: 1,
        reason: "Forbidden configuration edit",
      })
    ).errors[0].extensions.code,
    "FORBIDDEN",
  );
});
test("photo failure produces no attendance; real raw event retry after commit is idempotent", async () => {
  duty = randomUUID();
  photo = randomUUID();
  first = event("IN", 1);
  assert.equal(
    (await op("employee", "event", first)).errors[0].extensions.code,
    "PHOTO_NOT_READY",
  );
  assert.equal(
    (await owner.query("SELECT id FROM app.duty_sessions WHERE id=$1", [duty]))
      .rowCount,
    0,
  );
  photo = await readyPhoto();
  first.photoId = photo;
  const accepted = value(await op("employee", "event", first));
  assert.equal(accepted.status, "accepted");
  assert.equal(value(await op("employee", "event", first)).id, accepted.id);
  assert.equal(
    (
      await owner.query("SELECT id FROM app.duty_events WHERE duty_id=$1", [
        duty,
      ])
    ).rowCount,
    1,
  );
  assert.equal(
    (await op("employee", "event", { ...first, kind: "OUT" })).errors[0]
      .extensions.code,
    "CONFLICT",
  );
  const secondDevice = await signIn("employee@example.test");
  const duplicate = await gql(
    secondDevice,
    'mutation($s:ID!,$i:JSON!){operate(siteId:$s,operation:"event",input:$i)}',
    { s: ids.dg, i: event("OUT", 2) },
  );
  assert.equal(duplicate.errors[0].extensions.code, "CONFLICT");
});
test("phone check-in appears on HR's selected local date and employee immediately after the receipt", async () => {
  const r = await gql(
    tokens.hr!,
    "query($s:ID!,$d:String!,$e:ID){attendanceDay(siteId:$s,workDate:$d,employeeId:$e)}",
    {
      s: ids.dg,
      d: workDate(new Date(first.capturedAt), "Asia/Kolkata"),
      e: ids.employeeProfile,
    },
  );
  assert.ok(r.data?.attendanceDay, JSON.stringify(r.errors));
  assert.ok(r.data.attendanceDay.sessions.some((s: any) => s.id === duty));
  assert.ok(
    r.data.attendanceDay.events.some(
      (e: any) =>
        e.duty_id === duty && e.kind === "IN" && e.status === "accepted",
    ),
  );
});
test("out-of-order, clock and missing GPS remain raw/pending; independent review restores sequence", async () => {
  const out = event("OUT", 3);
  const pending = value(await op("employee", "event", out));
  assert.equal(pending.status, "pending_verification");
  const next = event("LOCATION", 2);
  value(await op("employee", "event", next));
  assert.equal(
    (
      await op("employee", "verifyEvent", {
        id: pending.id,
        expectedStatus: "pending_verification",
        approve: true,
        effectiveAt: new Date().toISOString(),
        reason: "Cannot approve my own evidence",
      })
    ).errors[0].extensions.code,
    "FORBIDDEN",
  );
  const verified = value(
    await op("hr", "verifyEvent", {
      id: pending.id,
      expectedStatus: "pending_verification",
      approve: true,
      effectiveAt: new Date().toISOString(),
      reason: "Verified synthetic delayed exit order",
    }),
  );
  assert.equal(verified.status, "accepted");
  const data = (await snap("employee")).data?.operations;
  assert.ok(data);
  assert.equal(data.sessions[0].status, "closed");
  assert.equal(data.events.length, 3);
  duty = randomUUID();
  const clock = event("IN", 1, duty, {
    capturedAt: new Date(Date.now() + 3600000).toISOString(),
  });
  assert.equal(
    value(await op("employee", "event", clock)).status,
    "pending_verification",
  );
  // Pending evidence still counts for numbering: the next event is #2, not a second #1.
  const reopened = (await snap("employee")).data.operations.sessions.find(
    (s: any) => s.id === duty,
  );
  assert.deepEqual([reopened.last_sequence, reopened.max_sequence], [0, 1]);
});
test("overnight rosters are explicit instants and adjustments cannot self-approve", async () => {
  const shift = (
    await foundation(tokens.admin!, "reference", {
      kind: "shift",
      name: "Synthetic overnight",
      startTime: "22:00",
      endTime: "06:00",
    })
  ).data.saveFoundation;
  const roster = value(
    await op("hr", "roster", {
      employeeId: ids.employeeProfile,
      shiftId: shift.id,
      workDate: "2026-09-20",
      expectedVersion: 0,
    }),
  );
  const row = (
    await owner.query(
      "SELECT extract(epoch FROM ends_at-starts_at)/3600 hours FROM app.shift_rosters WHERE id=$1",
      [roster.id],
    )
  ).rows[0];
  assert.equal(Number(row.hours), 8);
});
test("half-day ledger rejects overlap and concurrent double approval deducts exactly once", async () => {
  typeId = value(
    await op("super_admin", "leaveType", {
      code: "SYNTH",
      label: "Synthetic paid leave",
      halfDays: true,
      includeWeekends: true,
      includeHolidays: true,
      approverId: ids.admin,
    }),
  ).id;
  value(
    await op("super_admin", "leaveCredit", {
      employeeId: ids.employeeProfile,
      typeId,
      units: 10,
      effectiveOn: "2026-01-01",
      reason: "Synthetic opening balance only",
    }),
  );
  const input = {
    clientId: randomUUID(),
    typeId,
    startsOn: "2026-10-01",
    endsOn: "2026-10-01",
    half: "am",
    reason: "Synthetic half-day application",
  };
  leaveId = value(await op("employee", "leave", input)).id;
  assert.equal(value(await op("employee", "leave", input)).id, leaveId);
  assert.equal(
    (await op("employee", "leave", { ...input, clientId: randomUUID() }))
      .errors[0].extensions.code,
    "CONFLICT",
  );
  const decision = {
    id: leaveId,
    expectedVersion: 1,
    approve: true,
    reason: "Independent synthetic leave review",
  };
  const results = await Promise.all([
    op("hr", "reviewLeave", decision),
    op("hr", "reviewLeave", decision),
  ]);
  assert.equal(results.filter((r) => r.data?.operate).length, 1);
  assert.equal(
    results.filter((r) => r.errors?.[0]?.extensions.code === "CONFLICT").length,
    1,
  );
  const balance = (
    await owner.query(
      "SELECT sum(units) balance FROM app.leave_ledger WHERE employee_id=$1 AND type_id=$2",
      [ids.employeeProfile, typeId],
    )
  ).rows[0].balance;
  assert.equal(Number(balance), 9.5);
});
test("assigned tasks, comments, inbox and attachment authorization remain connected", async () => {
  const task = value(
    await op("hr", "task", {
      clientId: randomUUID(),
      employeeId: ids.employeeProfile,
      title: "Synthetic site inspection",
      description: "Check the assigned visit",
      deadline: new Date(Date.now() + 86400000).toISOString(),
      priority: "high",
    }),
  );
  const employee = (await snap("employee")).data.operations;
  assert.ok(employee.tasks.some((t: any) => t.id === task.id));
  assert.ok(employee.inbox.some((n: any) => n.entity_id === task.id));
  value(
    await op("employee", "taskStatus", {
      id: task.id,
      expectedVersion: 1,
      status: "in_progress",
    }),
  );
  value(
    await op("employee", "comment", {
      clientId: randomUUID(),
      taskId: task.id,
      body: "Work started",
    }),
  );
  assert.equal(
    (
      await op("supervisor", "taskStatus", {
        id: task.id,
        expectedVersion: 2,
        status: "done",
      })
    ).errors[0].extensions.code,
    "NOT_FOUND",
  );
  const forbidden = await app.inject({
    method: "GET",
    url: `/files/attachments/${photo}?siteId=${ids.dg}`,
    headers: { authorization: `Bearer ${tokens.supervisor}` },
  });
  assert.equal(forbidden.statusCode, 404);
  const cross = await snap("admin", ids.rg);
  assert.equal(cross.errors[0].extensions.code, "FORBIDDEN");
});

test("review corrects a future entry without changing capture time; field visit order, distance and segments are verified", async () => {
  const pending = (await snap("employee")).data.operations.events.find(
    (e: any) => e.duty_id === duty && e.kind === "IN",
  );
  const effectiveAt = new Date().toISOString();
  value(
    await op("hr", "verifyEvent", {
      id: pending.id,
      expectedStatus: "pending_verification",
      approve: true,
      effectiveAt,
      reason: "Synthetic independent clock correction",
    }),
  );
  const corrected = (await snap("employee")).data.operations.sessions.find(
    (s: any) => s.id === duty,
  );
  assert.equal(corrected.opened_at, effectiveAt);
  assert.notEqual(
    (await snap("employee")).data.operations.events.find(
      (e: any) => e.id === pending.id,
    ).captured_at,
    effectiveAt,
  );
  const visit = value(
    await op("hr", "visit", {
      employeeId: ids.employeeProfile,
      title: "Synthetic assigned inspection",
      scheduledAt: effectiveAt,
      latitude: 28.6,
      longitude: 77.2,
      radiusM: 100,
      notes: "Fixture only",
    }),
  );
  assert.equal(
    value(await op("employee", "event", event("FIELD_START", 2))).status,
    "accepted",
  );
  const invalid = value(
    await op(
      "employee",
      "event",
      event("VISIT_END", 3, duty, { visitId: visit.id }),
    ),
  );
  assert.equal(invalid.status, "pending_verification");
  const outside = event("VISIT_START", 3, duty, { visitId: visit.id });
  outside.location.longitude = 77.205;
  assert.equal(
    value(await op("employee", "event", outside)).status,
    "pending_verification",
  );
  assert.equal(
    value(
      await op(
        "employee",
        "event",
        event("VISIT_START", 3, duty, { visitId: visit.id }),
      ),
    ).status,
    "accepted",
  );
  assert.equal(
    (await snap("employee")).data.operations.visits.find(
      (v: any) => v.id === visit.id,
    ).status,
    "in_progress",
  );
  assert.equal(
    value(
      await op(
        "employee",
        "event",
        event("VISIT_END", 4, duty, { visitId: visit.id }),
      ),
    ).status,
    "accepted",
  );
  assert.equal(
    value(await op("employee", "event", event("FIELD_END", 5))).status,
    "accepted",
  );
  assert.equal(
    value(await op("employee", "event", event("OUT", 6))).status,
    "accepted",
  );
  const result = (await snap("employee")).data.operations;
  assert.equal(
    result.visits.find((v: any) => v.id === visit.id).status,
    "completed",
  );
  assert.ok(
    result.sessions
      .find((s: any) => s.id === duty)
      .timeAtLocation.some((t: any) => t.visitId === visit.id),
  );
});

test("original-site upload intents and events cannot migrate to another selected site", async () => {
  const intent = value(
    await op("employee", "fileIntent", {
      clientId: randomUUID(),
      purpose: "attendance",
      type: "image/jpeg",
      bytes: 12,
    }),
  );
  const wrongSite = await app.inject({
    method: "POST",
    url: `/files/intents/${intent.id}/content?siteId=${ids.rg}`,
    headers: {
      authorization: `Bearer ${tokens.employee}`,
      "content-type": "application/octet-stream",
    },
    payload: Buffer.from("syntheticbad"),
  });
  assert.equal(wrongSite.statusCode, 404);
  const original = (
    await owner.query(
      "SELECT site_id,status FROM app.private_files WHERE id=$1",
      [intent.id],
    )
  ).rows[0];
  assert.equal(original.site_id, ids.dg);
  assert.equal(original.status, "awaiting_upload");
});

test("real private storage: photo upload retry, stripped derivative, inaccessible file and scanner quarantine", async () => {
  const local = parseEnv(await readFile(".env", "utf8"));
  assert.ok(
    ["localhost", "127.0.0.1"].includes(new URL(local.S3_ENDPOINT!).hostname),
    "Only loopback synthetic storage is allowed",
  );
  for (const k of [
    "S3_ENDPOINT",
    "S3_ACCESS_KEY",
    "S3_SECRET_KEY",
    "S3_BUCKET",
  ])
    process.env[k] = local[k];
  const bytes = await sharp({
    create: { width: 32, height: 32, channels: 3, background: "#277052" },
  })
    .withMetadata({ orientation: 1 })
    .jpeg()
    .toBuffer();
  const intent = value(
    await op("employee", "fileIntent", {
      clientId: randomUUID(),
      purpose: "attendance",
      type: "image/jpeg",
      bytes: bytes.length,
    }),
  );
  const headers = {
    authorization: `Bearer ${tokens.employee}`,
    "content-type": "application/octet-stream",
  };
  const upload = () =>
    app.inject({
      method: "POST",
      url: `/files/intents/${intent.id}/content?siteId=${ids.dg}`,
      headers,
      payload: bytes,
    });
  try {
    const first = await upload();
    assert.equal(first.statusCode, 200, first.body);
    assert.equal(first.json().status, "ready");
    assert.equal((await upload()).json().status, "ready");
    const downloaded = await app.inject({
      method: "GET",
      url: `/files/attachments/${intent.id}?siteId=${ids.dg}`,
      headers: { authorization: `Bearer ${tokens.employee}` },
    });
    assert.equal(downloaded.statusCode, 200);
    assert.equal(
      (await sharp(downloaded.rawPayload).metadata()).exif,
      undefined,
    );
    const forbidden = await app.inject({
      method: "GET",
      url: `/files/attachments/${intent.id}?siteId=${ids.dg}`,
      headers: { authorization: `Bearer ${tokens.supervisor}` },
    });
    assert.equal(forbidden.statusCode, 404);
    const changed = await app.inject({
      method: "POST",
      url: `/files/intents/${intent.id}/content?siteId=${ids.dg}`,
      headers,
      payload: Buffer.alloc(bytes.length),
    });
    assert.equal(changed.statusCode, 409);
    const row = (
      await owner.query(
        "SELECT object_key FROM app.private_files WHERE id=$1",
        [intent.id],
      )
    ).rows[0];
    const anonymous = await fetch(
      `${process.env.S3_ENDPOINT}/${process.env.S3_BUCKET}/${row.object_key}/content`,
    );
    assert.ok([401, 403].includes(anonymous.status));
  } finally {
    const row = (
      await owner.query(
        "SELECT object_key FROM app.private_files WHERE id=$1",
        [intent.id],
      )
    ).rows[0];
    for (const suffix of ["quarantine", "content"])
      await objectStorage().send(
        new DeleteObjectCommand({
          Bucket: process.env.S3_BUCKET,
          Key: `${row.object_key}/${suffix}`,
        }),
      );
  }
});

test("PDF without a configured scanner stays quarantined and cannot download", async () => {
  const task = (await snap("employee")).data.operations.tasks[0];
  const bytes = Buffer.from("%PDF-1.4 synthetic quarantine fixture");
  const intent = value(
    await op("employee", "fileIntent", {
      clientId: randomUUID(),
      purpose: "task",
      parentId: task.id,
      type: "application/pdf",
      bytes: bytes.length,
    }),
  );
  try {
    const response = await app.inject({
      method: "POST",
      url: `/files/intents/${intent.id}/content?siteId=${ids.dg}`,
      headers: {
        authorization: `Bearer ${tokens.employee}`,
        "content-type": "application/octet-stream",
      },
      payload: bytes,
    });
    assert.equal(response.statusCode, 200);
    assert.equal(response.json().status, "quarantined");
    const changed = await app.inject({
      method: "POST",
      url: `/files/intents/${intent.id}/content?siteId=${ids.dg}`,
      headers: {
        authorization: `Bearer ${tokens.employee}`,
        "content-type": "application/octet-stream",
      },
      payload: Buffer.alloc(bytes.length),
    });
    assert.equal(changed.statusCode, 409);
    const forbidden = await app.inject({
      method: "GET",
      url: `/files/attachments/${intent.id}?siteId=${ids.dg}`,
      headers: { authorization: `Bearer ${tokens.employee}` },
    });
    assert.equal(forbidden.statusCode, 404);
  } finally {
    const row = (
      await owner.query(
        "SELECT object_key FROM app.private_files WHERE id=$1",
        [intent.id],
      )
    ).rows[0];
    await objectStorage().send(
      new DeleteObjectCommand({
        Bucket: process.env.S3_BUCKET,
        Key: `${row.object_key}/quarantine`,
      }),
    );
  }
});

test("correction decisions require an independent approver and overlapping adjustments cannot double count", async () => {
  const session = (await snap("employee")).data.operations.sessions.find(
    (s: any) => s.id === duty,
  );
  const input = {
    dutyId: duty,
    startsAt: session.opened_at,
    endsAt: session.closed_at,
    kind: "office",
    reason: "Synthetic independently reviewed correction",
  };
  const request = value(await op("employee", "adjustment", input));
  const decision = {
    id: request.id,
    expectedVersion: 1,
    approve: true,
    reason: "Synthetic evidence reviewed independently",
  };
  assert.equal(
    (await op("employee", "reviewAdjustment", decision)).errors[0].extensions
      .code,
    "FORBIDDEN",
  );
  assert.equal(
    value(await op("hr", "reviewAdjustment", decision)).status,
    "approved",
  );
  assert.equal(
    (await op("hr", "reviewAdjustment", decision)).errors[0].extensions.code,
    "CONFLICT",
  );
  const overlapping = value(await op("employee", "adjustment", input));
  assert.equal(
    (await op("hr", "reviewAdjustment", { ...decision, id: overlapping.id }))
      .errors[0].extensions.code,
    "CONFLICT",
  );
  const projection = (await snap("employee")).data.operations.sessions.find(
    (s: any) => s.id === duty,
  );
  assert.ok(projection.segments.every((s: any) => s.kind === "office"));
  const raw = (
    await owner.query("SELECT count(*) FROM app.duty_events WHERE duty_id=$1", [
      duty,
    ])
  ).rows[0];
  assert.equal(Number(raw.count), 8);
});

test("transfer cannot open a concurrent duty across sites and original duty remains unchanged", async () => {
  value(
    await op(
      "super_admin",
      "policy",
      { rules, expectedVersion: 0, reason: "Synthetic transfer policy only" },
      ids.rg,
    ),
  );
  value(
    await op(
      "super_admin",
      "geofence",
      {
        coordinates: coords,
        label: "Synthetic transfer boundary",
        expectedVersion: 0,
        reason: "Synthetic transfer boundary only",
      },
      ids.rg,
    ),
  );
  const original = randomUUID();
  assert.equal(
    value(await op("employee", "event", event("IN", 1, original))).status,
    "accepted",
  );
  const intent = value(
    await op(
      "employee",
      "fileIntent",
      {
        clientId: randomUUID(),
        purpose: "attendance",
        type: "image/jpeg",
        bytes: 12,
      },
      ids.rg,
    ),
  );
  await owner.query(
    "UPDATE app.private_files SET status='ready',scan_result='synthetic_database_fixture' WHERE id=$1",
    [intent.id],
  );
  const transferred = await op(
    "employee",
    "event",
    event("IN", 1, randomUUID(), { photoId: intent.id }),
    ids.rg,
  );
  assert.equal(transferred.errors[0].extensions.code, "CONFLICT");
  assert.equal(
    (
      await owner.query("SELECT site_id FROM app.duty_sessions WHERE id=$1", [
        original,
      ])
    ).rows[0].site_id,
    ids.dg,
  );
  assert.equal(
    value(await op("employee", "event", event("OUT", 2, original))).status,
    "accepted",
  );
});

test("offsite OUT requires an employee reason, stays pending, and rejected evidence does not trap the duty", async () => {
  const d = randomUUID();
  assert.equal(
    value(await op("employee", "event", event("IN", 1, d))).status,
    "accepted",
  );
  const capturedAt = new Date().toISOString();
  const outside = event("OUT", 2, d, {
    capturedAt,
    location: {
      latitude: 28.7,
      longitude: 77.3,
      accuracyM: 10,
      observedAt: capturedAt,
    },
  });
  assert.equal(
    (await op("employee", "event", outside)).errors[0].extensions.code,
    "OFFSITE_REASON_REQUIRED",
  );
  assert.equal(
    (
      await owner.query(
        "SELECT count(*)::int n FROM app.duty_events WHERE duty_id=$1 AND kind='OUT'",
        [d],
      )
    ).rows[0].n,
    0,
  );
  const pending = value(
    await op("employee", "event", {
      ...outside,
      offsiteReason: "Finishing approved client visit offsite",
    }),
  );
  assert.equal(pending.status, "pending_verification");
  assert.equal(
    value(
      await op("employee", "event", {
        ...outside,
        offsiteReason: "Finishing approved client visit offsite",
      }),
    ).id,
    pending.id,
  );
  const snapshot = (await snap("employee")).data.operations;
  const duty = snapshot.sessions.find((x: any) => x.id === d);
  assert.equal(duty.status, "open");
  assert.equal(duty.closed_at, null);
  assert.equal(
    snapshot.events.find((x: any) => x.id === pending.id).offsite_reason,
    "Finishing approved client visit offsite",
  );
  assert.equal(
    snapshot.events.find((x: any) => x.id === pending.id).effective_at,
    null,
  );
  assert.equal(
    (
      await op("manager", "verifyEvent", {
        id: pending.id,
        expectedStatus: "pending_verification",
        approve: true,
        effectiveAt: capturedAt,
        reason: "Neither the configured approver nor a site admin",
      })
    ).errors[0].extensions.code,
    "FORBIDDEN",
  );
  value(
    await op("hr", "verifyEvent", {
      id: pending.id,
      expectedStatus: "pending_verification",
      approve: false,
      reason: "Employee returned; submit a new onsite OUT",
    }),
  );
  assert.equal(
    value(await op("employee", "event", event("OUT", 3, d))).status,
    "accepted",
  );
});

test("an approved offsite OUT closes the duty once and preserves the original employee reason", async () => {
  const d = randomUUID();
  value(await op("employee", "event", event("IN", 1, d)));
  const capturedAt = new Date().toISOString();
  const pending = value(
    await op(
      "employee",
      "event",
      event("OUT", 2, d, {
        capturedAt,
        location: {
          latitude: 28.7,
          longitude: 77.3,
          accuracyM: 10,
          observedAt: capturedAt,
        },
        offsiteReason: "Travelled directly home after the client visit",
      }),
    ),
  );
  const decision = {
    id: pending.id,
    expectedStatus: "pending_verification",
    approve: true,
    effectiveAt: capturedAt,
    reason: "Client visit and exit independently verified",
  };
  // Approval is assigned to HR; a site super_admin may still decide.
  assert.equal(
    value(await op("super_admin", "verifyEvent", decision)).status,
    "accepted",
  );
  assert.equal(
    (await op("hr", "verifyEvent", decision)).errors[0].extensions.code,
    "CONFLICT",
  );
  const workDate = new Date(capturedAt).toLocaleDateString("en-CA", {
    timeZone: "Asia/Kolkata",
  });
  const reviewResult = await gql(
    tokens.hr!,
    "query($s:ID!,$d:String!){attendanceReview(siteId:$s,workDate:$d)}",
    { s: ids.dg, d: workDate },
  );
  const review = reviewResult.data?.attendanceReview;
  assert.ok(review, JSON.stringify(reviewResult.errors));
  const reviewed = review.events.find((x: any) => x.id === pending.id);
  assert.equal(reviewed.reviewer_id, ids.superAdmin);
  assert.ok(review.reviewers[ids.superAdmin]);
  assert.ok(reviewed.reviewed_at);
  const snapshot = (await snap("employee")).data.operations;
  assert.equal(snapshot.sessions.find((x: any) => x.id === d).status, "closed");
  assert.equal(
    snapshot.events.find((x: any) => x.id === pending.id).offsite_reason,
    "Travelled directly home after the client visit",
  );
});

test("raw evidence is immutable to runtime credentials and queued synchronization rechecks revoked membership", async () => {
  await assert.rejects(
    runtime.query("UPDATE app.duty_events SET kind='OUT'"),
    /permission denied/,
  );
  const before = await snapshot(ids.employee);
  const revoke = await gql(tokens.super_admin!, accessMutation(true), {
    s: ids.dg,
    u: ids.employee,
    i: changeInput(before, { active: false }),
  });
  assert.ok(revoke.data?.saveAccess, JSON.stringify(revoke.errors));
  const retry = await op("employee", "event", first);
  assert.ok(
    ["FORBIDDEN", "UNAUTHENTICATED"].includes(retry.errors[0].extensions.code),
  );
  const download = await app.inject({
    method: "GET",
    url: `/files/attachments/${photo}?siteId=${ids.dg}`,
    headers: { authorization: `Bearer ${tokens.employee}` },
  });
  assert.ok([401, 403].includes(download.statusCode));
});
