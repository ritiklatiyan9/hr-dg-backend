import { createApp } from "../../apps/api/src/app.js";
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { randomBytes, randomUUID } from "node:crypto";
import { pool, scoped } from "../../packages/db/src/index.js";
import { migrate } from "../../packages/db/src/migrate.js";
import { seed, ids } from "../../packages/db/src/seed.js";
import { AuthService } from "../../apps/api/src/auth.js";
import { Tracking } from "../../apps/api/src/tracking.js";
import { totp } from "../../apps/api/src/security.js";
import type { Actor } from "../../packages/authz/src/index.js";
import type pg from "pg";
let owner: pg.Pool,
  runtime: pg.Pool,
  authPool: pg.Pool,
  control: pg.Pool,
  service: Tracking,
  auth: AuthService,
  dbName: string;
let admin: Actor,
  employee: Actor,
  river: Actor,
  outsider: Actor,
  otherDevice: Actor;
const rosterId = randomUUID(),
  shiftId = randomUUID(),
  password = randomBytes(24).toString("hex");
const policy = {
  expectedVersion: 0,
  enabled: true,
  mode: "roster",
  sampleSeconds: 15,
  staleSeconds: 60,
  notice:
    "During HR-assigned shifts, location is shared with authorized HR staff.",
  reason: "Synthetic tracking policy validation",
};
const tokens: Record<string, string> = {};
async function login(email: string) {
  const r = await auth.login({
    organizationId: email === "outsider@example.test" ? ids.otherOrg : ids.org,
    email,
    password,
    kind: "mobile",
    deviceId: randomUUID(),
  });
  let actor = (await auth.lookup(r.accessToken))!;
  if (r.mfaRequired) {
    const otp = await auth.setupMfa(actor);
    await auth.verifyMfa(actor, totp(otp.secret).generate());
    actor = (await auth.lookup(r.accessToken))!;
  }
  tokens[actor.sessionId] = r.accessToken;
  return actor;
}
async function expectCode(action: () => Promise<unknown>, code: string) {
  await assert.rejects(action, (e: any) => e.code === code, `Expected ${code}`);
}
const sample = (patch: Record<string, unknown> = {}) => ({
  clientId: randomUUID(),
  rosterId,
  rosterVersion: 1,
  policyVersion: 1,
  latitude: 28.6,
  longitude: 77.2,
  accuracyM: 5,
  observedAt: new Date(Date.now() - 30000).toISOString(),
  mocked: false,
  ...patch,
});
before(
  async () => {
    const root = process.env.TEST_MIGRATION_DATABASE_URL!;
    if (
      !root ||
      new URL(root).pathname !== "/hr_test" ||
      !["localhost", "127.0.0.1"].includes(new URL(root).hostname)
    )
      throw Error("Isolated loopback PostGIS required");
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
    owner = pool(url(root), 2);
    runtime = pool(url(process.env.TEST_DATABASE_URL!), 6);
    authPool = pool(url(process.env.TEST_AUTH_DATABASE_URL!), 2);
    auth = new AuthService(authPool, {
      NODE_ENV: "test",
      PORT: 4000,
      DATABASE_URL: url(process.env.TEST_DATABASE_URL!),
      AUTH_DATABASE_URL: url(process.env.TEST_AUTH_DATABASE_URL!),
      LOGIN_ORGANIZATION_ID: ids.org,
      WEB_ORIGIN: "http://localhost:5180",
      COOKIE_SECURE: "true",
      ENCRYPTION_KEY: randomBytes(32).toString("hex"),
      REDIS_URL: "redis://localhost:56379",
    });
    service = new Tracking(runtime);
    admin = await login("superadmin@example.test");
    employee = await login("employee@example.test");
    otherDevice = await login("employee@example.test");
    river = await login("river@example.test");
    outsider = await login("outsider@example.test");
    await service.command(admin, ids.dg, "policy", {
      expectedVersion: 0,
      reason: "Synthetic geofence attendance policy",
      rules: {
        allowOffline: false,
        offlineMaxHours: 0,
        maxAccuracyM: 50,
        freshnessSeconds: 60,
        clockSkewSeconds: 30,
        gapSeconds: 120,
        maxSessionHours: 12,
        lateGraceMinutes: 0,
        earlyGraceMinutes: 0,
        attendanceApproverId: ids.admin,
      },
    });
    await service.command(admin, ids.dg, "geofence", {
      expectedVersion: 0,
      label: "Synthetic test perimeter",
      reason: "Synthetic geofence validation",
      coordinates: [
        [77.19, 28.59],
        [77.21, 28.59],
        [77.21, 28.61],
        [77.19, 28.61],
        [77.19, 28.59],
      ],
    });
    await owner.query(
      'INSERT INTO app.site_reference_items(id,organization_id,site_id,kind,name,details) VALUES($1,$2,$3,\'shift\',\'Synthetic duty\', \'{"startTime":"09:00","endTime":"18:00"}\')',
      [shiftId, ids.org, ids.dg],
    );
    await owner.query(
      "INSERT INTO app.shift_rosters(id,organization_id,site_id,employee_id,shift_id,work_date,starts_at,ends_at) VALUES($1,$2,$3,$4,$5,current_date,now()-interval '1 hour',now()+interval '1 hour')",
      [rosterId, ids.org, ids.dg, ids.employeeProfile, shiftId],
    );
    await service.trackingCommand(admin, ids.dg, "settings", policy);
  },
  { timeout: 60000 },
);
after(async () => {
  await Promise.all([owner?.end(), runtime?.end(), authPool?.end()]);
  if (control) {
    if (dbName) await control.query(`DROP DATABASE ${dbName}`);
    await control.end();
  }
});
test("server grants a bounded shift lease without any check-in", async () => {
  const c = await service.trackingContext(employee, ids.dg);
  assert.equal(c.window.id, rosterId);
  assert.ok(c.locationRules);
  assert.ok(c.locationRules.maxAccuracyM > 0);
  assert.ok(c.locationRules.freshnessSeconds >= 5);
  assert.ok(Date.parse(c.leaseUntil!) - Date.parse(c.serverTime) <= 120000);
  assert.equal((await service.snapshot(employee, ids.dg)).sessions.length, 0);
});
test("sample is idempotent, independently stored and visible only with location permission", async () => {
  const input = sample(),
    result = await service.trackingCommand(employee, ids.dg, "sample", input);
  assert.equal(result.status, "accepted");
  assert.equal(result.classification, "inside");
  assert.equal(
    (await service.trackingCommand(employee, ids.dg, "sample", input)).id,
    result.id,
  );
  await expectCode(
    () =>
      service.trackingCommand(employee, ids.dg, "sample", {
        ...input,
        latitude: 28.601,
      }),
    "CONFLICT",
  );
  const view = await service.trackingMonitor(admin, ids.dg, {});
  assert.equal(view.employees![0].status, "fresh");
  assert.equal(view.employees![0].location.latitude, 28.6);
  await expectCode(
    () => service.trackingMonitor(employee, ids.dg, {}),
    "FORBIDDEN",
  );
  await expectCode(
    () => service.trackingMonitor(river, ids.dg, {}),
    "FORBIDDEN",
  );
  await expectCode(
    () => service.trackingMonitor(outsider, ids.dg, {}),
    "FORBIDDEN",
  );
  assert.equal(
    (await service.trackingMonitor(admin, ids.rg, {})).employees!.length,
    0,
  );
  assert.equal(
    (await owner.query("SELECT count(*)::int n FROM app.duty_events")).rows[0]
      .n,
    0,
  );
});
test("rejects mock, poor accuracy, stale, future, off-window and forged version samples without persisting", async () => {
  const before = (
    await owner.query("SELECT count(*) n FROM app.tracking_samples")
  ).rows[0].n;
  for (const patch of [
    { mocked: true },
    { accuracyM: 100 },
    { observedAt: new Date(Date.now() - 90000).toISOString() },
    { observedAt: new Date(Date.now() + 30000).toISOString() },
  ])
    await expectCode(
      () => service.trackingCommand(employee, ids.dg, "sample", sample(patch)),
      "BAD_INPUT",
    );
  for (const patch of [
    { rosterVersion: 99 },
    { policyVersion: 99 },
    { rosterId: randomUUID() },
  ])
    await expectCode(
      () => service.trackingCommand(employee, ids.dg, "sample", sample(patch)),
      "CONFLICT",
    );
  await expectCode(
    () =>
      service.trackingCommand(
        employee,
        ids.dg,
        "sample",
        sample({ observedAt: new Date(Date.now() - 7200000).toISOString() }),
      ),
    "FORBIDDEN",
  );
  assert.equal(
    (await owner.query("SELECT count(*) n FROM app.tracking_samples")).rows[0]
      .n,
    before,
  );
});
test("rejects simultaneous second-device collection and enforces sample interval", async () => {
  await expectCode(
    () =>
      service.trackingCommand(
        otherDevice,
        ids.dg,
        "sample",
        sample({ observedAt: new Date().toISOString() }),
      ),
    "CONFLICT",
  );
  const last = (
    await owner.query(
      "SELECT observed_at FROM app.tracking_samples ORDER BY observed_at DESC LIMIT 1",
    )
  ).rows[0].observed_at;
  await expectCode(
    () =>
      service.trackingCommand(
        employee,
        ids.dg,
        "sample",
        sample({ observedAt: new Date(+last + 500).toISOString() }),
      ),
    "RATE_LIMITED",
  );
});
test("outside and boundary uncertainty remain observations, not fabricated attendance", async () => {
  await owner.query(
    "UPDATE app.tracking_samples SET received_at=now()-interval '3 minutes',observed_at=now()-interval '3 minutes'",
  );
  const r = await service.trackingCommand(
    employee,
    ids.dg,
    "sample",
    sample({ latitude: 28.62 }),
  );
  assert.equal(r.classification, "outside");
  await owner.query(
    "UPDATE app.tracking_samples SET observed_at=observed_at-interval '3 minutes'",
  );
  const edge = await service.trackingCommand(
    employee,
    ids.dg,
    "sample",
    sample({ longitude: 77.19 }),
  );
  assert.equal(edge.classification, "unknown");
});
test("configuration optimistic lock and mode switch remove authorization immediately", async () => {
  await expectCode(
    () => service.trackingCommand(employee, ids.dg, "settings", policy),
    "FORBIDDEN",
  );
  await expectCode(
    () => service.trackingCommand(admin, ids.dg, "settings", policy),
    "CONFLICT",
  );
  await service.trackingCommand(admin, ids.dg, "settings", {
    ...policy,
    expectedVersion: 1,
    mode: "checked_in",
  });
  assert.equal((await service.trackingContext(employee, ids.dg)).window, null);
  await expectCode(
    () =>
      service.trackingCommand(
        employee,
        ids.dg,
        "sample",
        sample({ policyVersion: 2 }),
      ),
    "FORBIDDEN",
  );
  await service.trackingCommand(admin, ids.dg, "settings", {
    ...policy,
    expectedVersion: 2,
  });
});
test("roster ending stops authorization and rejects late writes", async () => {
  await owner.query(
    "UPDATE app.shift_rosters SET ends_at=now()-interval '1 minute',version=version+1 WHERE id=$1",
    [rosterId],
  );
  assert.equal((await service.trackingContext(employee, ids.dg)).window, null);
  await expectCode(
    () =>
      service.trackingCommand(
        employee,
        ids.dg,
        "sample",
        sample({ rosterVersion: 2, policyVersion: 3 }),
      ),
    "FORBIDDEN",
  );
  assert.equal(
    (await service.trackingMonitor(admin, ids.dg, {})).employees![0].status,
    "off_duty",
  );
  await owner.query(
    "UPDATE app.shift_rosters SET ends_at=now()+interval '1 hour' WHERE id=$1",
    [rosterId],
  );
});
test("direct runtime reads respect org/site/record RLS and auth role cannot read telemetry", async () => {
  await scoped(runtime, river, ids.rg, async (c) =>
    assert.equal(
      (await c.query("SELECT * FROM app.tracking_samples")).rowCount,
      0,
    ),
  );
  await scoped(runtime, employee, ids.rg, async (c) =>
    assert.equal(
      (await c.query("SELECT * FROM app.tracking_samples")).rowCount,
      0,
    ),
  );
  await scoped(runtime, outsider, ids.otherSite, async (c) =>
    assert.equal(
      (await c.query("SELECT * FROM app.tracking_samples")).rowCount,
      0,
    ),
  );
  await assert.rejects(
    () => authPool.query("SELECT * FROM app.tracking_samples"),
    /permission denied/,
  );
});
test("disabling settings revokes context and retains honest history", async () => {
  await service.trackingCommand(admin, ids.dg, "settings", {
    ...policy,
    expectedVersion: 3,
    enabled: false,
  });
  assert.equal((await service.trackingContext(employee, ids.dg)).window, null);
  assert.equal(
    (await service.trackingMonitor(admin, ids.dg, {})).employees![0].status,
    "disabled",
  );
  const route = await service.trackingMonitor(admin, ids.dg, { rosterId });
  assert.equal(route.points!.length, 3);
  assert.ok(route.points!.every((p) => Number.isFinite(p.latitude)));
});
test("cross-site overlapping rosters are rejected by the database", async () => {
  await assert.rejects(
    () =>
      owner.query(
        "INSERT INTO app.shift_rosters(organization_id,site_id,employee_id,shift_id,work_date,starts_at,ends_at) VALUES($1,$2,$3,$4,current_date+1,now(),now()+interval '2 hours')",
        [ids.org, ids.rg, ids.employeeProfile, shiftId],
      ),
    /overlaps/,
  );
});

test("overnight roster uses site timezone, supports optimistic edits, rejects stale edits", async () => {
  await owner.query(
    'UPDATE app.site_reference_items SET details=\'{"startTime":"22:00","endTime":"06:00"}\' WHERE id=$1',
    [shiftId],
  );
  const workDate = (
    await owner.query("SELECT to_char(current_date+3,'YYYY-MM-DD') d")
  ).rows[0].d;
  const input = {
    employeeId: ids.employeeProfile,
    shiftId,
    workDate,
    expectedVersion: 0,
  };
  const created = await service.command(admin, ids.dg, "roster", input);
  const row = (
    await owner.query(
      "SELECT starts_at,ends_at,to_char(starts_at AT TIME ZONE 'Asia/Kolkata','HH24:MI') local_start,to_char(ends_at AT TIME ZONE 'Asia/Kolkata','HH24:MI') local_end FROM app.shift_rosters WHERE id=$1",
      [created.id],
    )
  ).rows[0];
  assert.equal(+row.ends_at - +row.starts_at, 8 * 3600000);
  assert.equal(row.local_start, "22:00");
  assert.equal(row.local_end, "06:00");
  assert.equal(
    (
      await service.command(admin, ids.dg, "roster", {
        ...input,
        expectedVersion: 1,
      })
    ).version,
    2,
  );
  await expectCode(
    () =>
      service.command(admin, ids.dg, "roster", {
        ...input,
        expectedVersion: 1,
      }),
    "CONFLICT",
  );
});

test("route cursor returns every sample without truncation or duplicates", async () => {
  await owner.query(
    `INSERT INTO app.tracking_samples(organization_id,site_id,employee_id,user_id,device_id,client_id,payload_hash,roster_id,roster_version,policy_version,geofence_version,observed_at,point,accuracy_m,classification)
    SELECT $1,$2,$3,$4,gen_random_uuid(),gen_random_uuid(),'synthetic',$5,1,1,1,now()-interval '30 minutes'+n*interval '1 second',ST_SetSRID(ST_MakePoint(77.2,28.6),4326)::geography,5,'inside' FROM generate_series(1,501) n`,
    [ids.org, ids.dg, ids.employeeProfile, ids.employee, rosterId],
  );
  const first = await service.trackingMonitor(admin, ids.dg, { rosterId });
  assert.equal(first.points!.length, 500);
  assert.ok(first.next);
  const second = await service.trackingMonitor(admin, ids.dg, {
    rosterId,
    sampleAfter: first.next,
  });
  assert.equal(second.points!.length, 4);
  assert.equal(second.next, null);
  assert.equal(
    new Set([...first.points!, ...second.points!].map((p) => p.id)).size,
    504,
  );
});

test("GraphQL tracking contracts use verified sessions and reject forged identities", async () => {
  const app = await createApp(auth.config, runtime, authPool, false);
  try {
    const request = async (
      actor: Actor | undefined,
      query: string,
      variables: Record<string, unknown>,
    ) =>
      (
        await app.inject({
          method: "POST",
          url: "/graphql",
          headers: actor
            ? { authorization: `Bearer ${tokens[actor.sessionId]}` }
            : {},
          payload: { query, variables },
        })
      ).json();
    const query =
      "query($siteId:ID!,$input:JSON!){trackingMonitor(siteId:$siteId,input:$input)}";
    const success = await request(admin, query, { siteId: ids.dg, input: {} });
    assert.equal(success.data.trackingMonitor.employees[0].status, "disabled");
    const denied = await request(employee, query, {
      siteId: ids.dg,
      input: {},
    });
    assert.equal(denied.errors[0].extensions.code, "FORBIDDEN");
    const anonymous = await request(undefined, query, {
      siteId: ids.dg,
      input: {},
    });
    assert.ok(anonymous.errors || anonymous.code);
    const mutation =
      "mutation($siteId:ID!,$operation:String!,$input:JSON!){trackingCommand(siteId:$siteId,operation:$operation,input:$input)}";
    const forged = await request(employee, mutation, {
      siteId: ids.dg,
      operation: "sample",
      input: { ...sample(), employeeId: ids.riverProfile },
    });
    assert.ok(forged.errors);
    const changed = await request(admin, mutation, {
      siteId: ids.dg,
      operation: "settings",
      input: { ...policy, expectedVersion: 4, enabled: false },
    });
    assert.equal(changed.data.trackingCommand.version, 5);
  } finally {
    await app.close();
  }
});

let offlineGrant: any;
let offlineSamples: any[];
test("offline grant is reused, device bound, and cannot be forged across sites", async () => {
  await service.trackingCommand(admin, ids.dg, "settings", {
    ...policy,
    expectedVersion: 5,
  });
  await owner.query(
    "UPDATE app.shift_rosters SET starts_at=now()-interval '10 hours',ends_at=now()+interval '2 hours' WHERE id=$1",
    [rosterId],
  );
  const expected = { rosterId, rosterVersion: 2, policyVersion: 6 };
  offlineGrant = await service.trackingCommand(
    employee,
    ids.dg,
    "offlinePermit",
    expected,
  );
  assert.ok(offlineGrant.id);
  assert.equal(
    (await service.trackingCommand(employee, ids.dg, "offlinePermit", expected))
      .id,
    offlineGrant.id,
  );
  assert.ok(+offlineGrant.ends_at - +offlineGrant.starts_at <= 86400000);
  await expectCode(
    () =>
      service.trackingCommand(otherDevice, ids.dg, "offlinePermit", expected),
    "CONFLICT",
  );
  await expectCode(
    () =>
      service.trackingCommand(employee, ids.rg, "batch", {
        grantId: offlineGrant.id,
        samples: [sample()],
      }),
    "FORBIDDEN",
  );
  await assert.rejects(
    () => authPool.query("SELECT * FROM app.tracking_offline_grants"),
    /permission denied/,
  );
  // Simulate a completed offline shift using synthetic owner fixtures only.
  await owner.query(
    "UPDATE app.tracking_offline_grants SET starts_at=now()-interval '6 hours',ends_at=now()-interval '4 hours',upload_until=now()-interval '4 hours'+interval '7 days' WHERE id=$1",
    [offlineGrant.id],
  );
  await owner.query(
    "UPDATE app.shift_rosters SET ends_at=now()-interval '3 hours' WHERE id=$1",
    [rosterId],
  );
  offlineSamples = Array.from({ length: 100 }, (_, i) =>
    sample({
      rosterVersion: 2,
      policyVersion: 6,
      observedAt: new Date(Date.now() - 5 * 3600000 + i * 15000).toISOString(),
    }),
  );
});
test("100 offline readings persist after duty end in one batch, retries deduplicate, and old points stay historical", async () => {
  const input = { grantId: offlineGrant.id, samples: offlineSamples };
  const t = performance.now();
  const result = await service.trackingCommand(
    employee,
    ids.dg,
    "batch",
    input,
  );
  console.log(
    `offline batch 100 rows: ${Math.round(performance.now() - t)} ms (local synthetic database)`,
  );
  assert.equal(result.results.length, 100);
  assert.ok(
    result.results.every((r: any) => r.status === "accepted"),
    JSON.stringify(result.results.slice(0, 2)),
  );
  const again = await service.trackingCommand(employee, ids.dg, "batch", input);
  assert.deepEqual(
    again.results.map((r: any) => r.id).sort(),
    result.results.map((r: any) => r.id).sort(),
  );
  assert.equal(
    (
      await owner.query(
        "SELECT count(*) n FROM app.tracking_samples WHERE offline_grant_id=$1",
        [offlineGrant.id],
      )
    ).rows[0].n,
    "100",
  );
  const monitor = await service.trackingMonitor(admin, ids.dg, {});
  assert.equal(
    monitor.employees!.find((r: any) => r.id === rosterId).status,
    "off_duty",
  );
});
test("batch acknowledgement isolates invalid readings, changed UUIDs, and excessive frequency", async () => {
  const changed = { ...offlineSamples[0], latitude: 29 };
  const outside = sample({
    rosterVersion: 2,
    policyVersion: 6,
    observedAt: new Date(Date.now() - 7 * 3600000).toISOString(),
  });
  const mocked = sample({
    rosterVersion: 2,
    policyVersion: 6,
    mocked: true,
    observedAt: new Date(Date.now() - 5.5 * 3600000).toISOString(),
  });
  const close = sample({ ...offlineSamples[1], clientId: randomUUID() });
  const valid = sample({
    rosterVersion: 2,
    policyVersion: 6,
    observedAt: new Date(Date.now() - 5.5 * 3600000 + 60000).toISOString(),
  });
  const result = await service.trackingCommand(employee, ids.dg, "batch", {
    grantId: offlineGrant.id,
    samples: [changed, outside, mocked, close, valid],
  });
  const reasons = new Map(
    result.results.map((r: any) => [r.clientId, r.reason]),
  );
  assert.equal(reasons.get(changed.clientId), "ID_CONFLICT");
  assert.equal(reasons.get(outside.clientId), "OUTSIDE_WINDOW");
  assert.equal(reasons.get(mocked.clientId), "INVALID_LOCATION");
  assert.equal(reasons.get(close.clientId), "SAMPLE_TOO_CLOSE");
  assert.equal(
    result.results.find((r: any) => r.clientId === valid.clientId).status,
    "accepted",
  );
  await assert.rejects(() =>
    service.trackingCommand(employee, ids.dg, "batch", {
      grantId: offlineGrant.id,
      samples: Array(101).fill(valid),
    }),
  );
  await expectCode(
    () =>
      service.trackingCommand(otherDevice, ids.dg, "batch", {
        grantId: offlineGrant.id,
        samples: [valid],
      }),
    "FORBIDDEN",
  );
});
test("expired and revoked offline grants cannot backfill; RLS prevents direct delayed inserts without a grant", async () => {
  await scoped(runtime, employee, ids.dg, async (c) =>
    assert.rejects(
      () =>
        c.query(
          `INSERT INTO app.tracking_samples(organization_id,site_id,employee_id,user_id,device_id,client_id,payload_hash,roster_id,roster_version,policy_version,geofence_version,observed_at,point,accuracy_m,classification)
    VALUES(app.org_id(),app.site_id(),$1,app.actor_id(),$2,gen_random_uuid(),'forged',$3,2,6,1,now()-interval '5 hours',ST_SetSRID(ST_MakePoint(77.2,28.6),4326)::geography,5,'inside')`,
          [ids.employeeProfile, offlineGrant.device_id, rosterId],
        ),
      /row-level security/,
    ),
  );
  const newPoint = sample({
    rosterVersion: 2,
    policyVersion: 6,
    observedAt: new Date(Date.now() - 5.8 * 3600000).toISOString(),
  });
  await service.trackingCommand(admin, ids.dg, "settings", {
    ...policy,
    expectedVersion: 6,
    enabled: false,
  });
  const denied = await service.trackingCommand(employee, ids.dg, "batch", {
    grantId: offlineGrant.id,
    samples: [newPoint],
  });
  assert.equal(denied.results[0].reason, "AUTHORIZATION_CHANGED");
  await owner.query(
    "UPDATE app.tracking_offline_grants SET starts_at=now()-interval '9 days',ends_at=now()-interval '8 days',upload_until=now()-interval '1 day' WHERE id=$1",
    [offlineGrant.id],
  );
  const expired = await service.trackingCommand(employee, ids.dg, "batch", {
    grantId: offlineGrant.id,
    samples: [newPoint],
  });
  assert.equal(expired.results[0].reason, "UPLOAD_EXPIRED");
});

test("indexed route reads remain bounded with 50,000 synthetic historical samples", async () => {
  await owner.query(
    `INSERT INTO app.tracking_samples(organization_id,site_id,employee_id,user_id,device_id,client_id,payload_hash,roster_id,roster_version,policy_version,geofence_version,observed_at,point,accuracy_m,classification)
    SELECT $1,$2,$3,$4,$5,gen_random_uuid(),'synthetic-scale-fixture',$6,2,6,1,now()-interval '30 days'+n*interval '15 seconds',ST_SetSRID(ST_MakePoint(77.2,28.6),4326)::geography,5,'inside' FROM generate_series(1,50000) n`,
    [
      ids.org,
      ids.dg,
      ids.employeeProfile,
      ids.employee,
      offlineGrant.device_id,
      rosterId,
    ],
  );
  await owner.query("ANALYZE app.tracking_samples");
  const plan = await owner.query(
    `EXPLAIN (ANALYZE,FORMAT JSON) SELECT id,observed_at FROM app.tracking_samples WHERE organization_id=$1 AND site_id=$2 AND roster_id=$3 ORDER BY observed_at DESC,id DESC LIMIT 501`,
    [ids.org, ids.dg, rosterId],
  );
  assert.match(JSON.stringify(plan.rows), /tracking_latest/);
  const timings = [];
  for (let i = 0; i < 10; i++) {
    const begin = performance.now();
    const page = await service.trackingMonitor(admin, ids.dg, { rosterId });
    assert.equal(page.points!.length, 500);
    timings.push(performance.now() - begin);
  }
  timings.sort((a, b) => a - b);
  console.log(
    `50k synthetic history: bounded 500-point RLS read p50=${Math.round(timings[4]!)}ms p95=${Math.round(timings[9]!)}ms; tracking_latest index used`,
  );
});

test("next roster can be prepared online but future observations cannot be uploaded early", async () => {
  await service.trackingCommand(admin, ids.dg, "settings", {
    ...policy,
    expectedVersion: 7,
  });
  await owner.query(
    "UPDATE app.shift_rosters SET starts_at=now()+interval '1 hour',ends_at=now()+interval '9 hours',version=version+1 WHERE id=$1",
    [rosterId],
  );
  const context = await service.trackingContext(employee, ids.dg);
  assert.equal(context.window, null);
  assert.equal(context.upcomingWindow.id, rosterId);
  const grant = await service.trackingCommand(
    employee,
    ids.dg,
    "offlinePermit",
    { rosterId, rosterVersion: 3, policyVersion: 8 },
  );
  assert.ok(+grant.starts_at > Date.now());
  const future = sample({
    rosterVersion: 3,
    policyVersion: 8,
    observedAt: new Date(+grant.starts_at + 60000).toISOString(),
  });
  const result = await service.trackingCommand(employee, ids.dg, "batch", {
    grantId: grant.id,
    samples: [future],
  });
  assert.equal(result.results[0].reason, "OUTSIDE_WINDOW");
  const app = await createApp(auth.config, runtime, authPool, false);
  try {
    const command = async (operation: string, input: unknown) =>
      (
        await app.inject({
          method: "POST",
          url: "/graphql",
          headers: { authorization: `Bearer ${tokens[employee.sessionId]}` },
          payload: {
            query:
              "mutation($siteId:ID!,$operation:String!,$input:JSON!){trackingCommand(siteId:$siteId,operation:$operation,input:$input)}",
            variables: { siteId: ids.dg, operation, input },
          },
        })
      ).json();
    const prepared = await command("offlinePermit", {
      rosterId,
      rosterVersion: 3,
      policyVersion: 8,
    });
    assert.equal(prepared.errors, undefined);
    assert.equal(prepared.data.trackingCommand.id, grant.id);
    assert.ok(
      Number.isFinite(Date.parse(prepared.data.trackingCommand.starts_at)),
    );
    const uploaded = await command("batch", {
      grantId: grant.id,
      samples: [future],
    });
    assert.equal(uploaded.errors, undefined);
    assert.equal(
      uploaded.data.trackingCommand.results[0].reason,
      "OUTSIDE_WINDOW",
    );
  } finally {
    await app.close();
  }
});

test("bulk duty schedule assigns site-local days, skips unchanged versions and needs roster rights", async () => {
  const dayShift = randomUUID();
  await owner.query(
    'INSERT INTO app.site_reference_items(id,organization_id,site_id,kind,name,details) VALUES($1,$2,$3,\'shift\',\'Synthetic 9 to 6\', \'{"startTime":"09:00","endTime":"18:00"}\')',
    [dayShift, ids.org, ids.dg],
  );
  const day = async (n: number) =>
    (await owner.query(`SELECT to_char(current_date+${n},'YYYY-MM-DD') d`))
      .rows[0].d as string;
  const input = {
    employeeIds: [ids.employeeProfile],
    shiftId: dayShift,
    fromDate: await day(20),
    toDate: await day(26),
    weekdays: [1, 2, 3, 4, 5, 6],
  };
  const first = await service.command(admin, ids.dg, "rosterRange", input);
  assert.equal(first.assigned, 6);
  assert.deepEqual(first.skipped, []);
  const rows = (
    await owner.query(
      "SELECT version,extract(dow FROM work_date)::int dow,to_char(starts_at AT TIME ZONE 'Asia/Kolkata','HH24:MI') s,to_char(ends_at AT TIME ZONE 'Asia/Kolkata','HH24:MI') e FROM app.shift_rosters WHERE shift_id=$1",
      [dayShift],
    )
  ).rows;
  assert.equal(rows.length, 6);
  assert.ok(rows.every((r) => r.s === "09:00" && r.e === "18:00" && r.dow));
  await service.command(admin, ids.dg, "rosterRange", input);
  assert.ok(
    (
      await owner.query(
        "SELECT version FROM app.shift_rosters WHERE shift_id=$1",
        [dayShift],
      )
    ).rows.every((r) => r.version === 1),
  );
  await expectCode(
    () => service.command(employee, ids.dg, "rosterRange", input),
    "FORBIDDEN",
  );
  await expectCode(
    () =>
      service.command(admin, ids.dg, "rosterRange", {
        ...input,
        fromDate: "2020-01-01",
        toDate: "2020-01-07",
      }),
    "BAD_INPUT",
  );
});

test("heartbeat shows a still, connected phone as idle, reports location off, and cannot be forged", async () => {
  await service.trackingCommand(admin, ids.dg, "settings", {
    ...policy,
    expectedVersion: 8,
  });
  await owner.query(
    "UPDATE app.shift_rosters SET starts_at=now()-interval '2 hours',ends_at=now()+interval '2 hours',version=version+1 WHERE id=$1",
    [rosterId],
  );
  const grant = await service.trackingCommand(
    employee,
    ids.dg,
    "offlinePermit",
    { rosterId, rosterVersion: 4, policyVersion: 9 },
  );
  // Synthetic: let the grant cover a reading taken before it was issued, and drop
  // earlier tests' older-version readings that were observed after it.
  await owner.query(
    "UPDATE app.tracking_offline_grants SET starts_at=now()-interval '1 hour' WHERE id=$1",
    [grant.id],
  );
  await owner.query("DELETE FROM app.tracking_samples WHERE roster_id=$1", [
    rosterId,
  ]);
  const old = sample({
    rosterVersion: 4,
    policyVersion: 9,
    observedAt: new Date(Date.now() - 180000).toISOString(),
  });
  const uploaded = await service.trackingCommand(employee, ids.dg, "batch", {
    grantId: grant.id,
    samples: [old],
  });
  assert.equal(uploaded.results[0].status, "accepted");
  const row = async () =>
    (await service.trackingMonitor(admin, ids.dg, {})).employees!.find(
      (r: any) => r.id === rosterId,
    );
  // The upload itself proves contact even though the fix is 3 minutes old.
  assert.equal((await row()).status, "idle");
  await owner.query(
    "UPDATE app.tracking_samples SET received_at=now()-interval '5 minutes' WHERE client_id=$1",
    [old.clientId],
  );
  assert.equal((await row()).status, "stale");
  const beat = (actor: Actor, state = "tracking") =>
    service.trackingCommand(actor, ids.dg, "heartbeat", {
      grantId: grant.id,
      state,
    });
  assert.equal((await beat(employee)).status, "accepted");
  const idle = await row();
  assert.equal(idle.status, "idle");
  assert.ok(Date.now() - Date.parse(idle.seen_at) < 10000);
  assert.equal(idle.location.latitude, 28.6);
  assert.equal((await beat(employee, "location_off")).status, "accepted");
  assert.equal((await row()).status, "location_off");
  const seen = (
    await owner.query(
      "SELECT last_seen_at FROM app.tracking_offline_grants WHERE id=$1",
      [grant.id],
    )
  ).rows[0].last_seen_at;
  await beat(employee, "location_off");
  assert.deepEqual(
    (
      await owner.query(
        "SELECT last_seen_at FROM app.tracking_offline_grants WHERE id=$1",
        [grant.id],
      )
    ).rows[0].last_seen_at,
    seen,
    "a repeated ping inside 10 s must not write",
  );
  // A newer accepted reading supersedes the older location-off report.
  const fresh = sample({ rosterVersion: 4, policyVersion: 9 });
  await service.trackingCommand(employee, ids.dg, "batch", {
    grantId: grant.id,
    samples: [fresh],
  });
  assert.equal((await row()).status, "fresh");
  await expectCode(() => beat(otherDevice), "FORBIDDEN");
  await expectCode(() => beat(river), "FORBIDDEN");
  await expectCode(() => beat(admin), "NOT_FOUND");
  // Column grant plus RLS: only the owner can touch presence, nothing else.
  await assert.rejects(
    () =>
      scoped(runtime, employee, ids.dg, (c) =>
        c.query(
          "UPDATE app.tracking_offline_grants SET ends_at=ends_at+interval '1 hour' WHERE id=$1",
          [grant.id],
        ),
      ),
    /permission denied/,
  );
  assert.equal(
    (
      await scoped(runtime, admin, ids.dg, (c) =>
        c.query(
          "UPDATE app.tracking_offline_grants SET last_seen_at=now() WHERE id=$1",
          [grant.id],
        ),
      )
    ).rowCount,
    0,
  );
  const mine = await service.trackingMonitor(admin, ids.dg, {
    employeeId: ids.employeeProfile,
  });
  assert.ok(mine.employees!.length >= 1);
  assert.ok(
    mine.employees!.every((r: any) => r.employee_id === ids.employeeProfile),
  );
  assert.equal(
    (
      await service.trackingMonitor(admin, ids.dg, {
        employeeId: randomUUID(),
      })
    ).employees!.length,
    0,
  );
  // Revoking the policy stops the heartbeat and hides the old presence.
  await service.trackingCommand(admin, ids.dg, "settings", {
    ...policy,
    expectedVersion: 9,
  });
  assert.equal((await beat(employee)).reason, "AUTHORIZATION_CHANGED");
  assert.equal((await row()).status, "missing");
});

test("duty schedule skips site holidays and the snapshot keeps today's roster among many future ones", async () => {
  const day = async (n: number) =>
    (await owner.query(`SELECT to_char(current_date+${n},'YYYY-MM-DD') d`))
      .rows[0].d as string;
  const holiday = await day(30);
  await owner.query(
    "INSERT INTO app.site_reference_items(organization_id,site_id,kind,name,details) VALUES($1,$2,'holiday','Synthetic holiday',jsonb_build_object('date',$3::text))",
    [ids.org, ids.dg, holiday],
  );
  const range = {
    employeeIds: [ids.employeeProfile],
    shiftId,
    fromDate: holiday,
    toDate: await day(31),
    weekdays: [0, 1, 2, 3, 4, 5, 6],
  };
  const result = await service.command(admin, ids.dg, "rosterRange", range);
  assert.equal(result.assigned, 1);
  assert.deepEqual(result.holidays, [holiday]);
  await expectCode(
    () =>
      service.command(admin, ids.dg, "rosterRange", {
        ...range,
        toDate: holiday,
      }),
    "BAD_INPUT",
  );
  await owner.query(
    `INSERT INTO app.shift_rosters(organization_id,site_id,employee_id,shift_id,work_date,starts_at,ends_at)
    SELECT $1,$2,$3,$4,current_date+n,now()+n*interval '1 day',now()+n*interval '1 day'+interval '1 hour' FROM generate_series(40,160) n`,
    [ids.org, ids.dg, ids.employeeProfile, shiftId],
  );
  const snapshot = await service.snapshot(admin, ids.dg);
  assert.ok(snapshot.rosters.some((r: any) => r.id === rosterId));
  assert.ok(
    snapshot.rosters.every(
      (r: any) => +r.starts_at < Date.now() + 7 * 86400000,
    ),
  );
});
