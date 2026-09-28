import { before, after, test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { fixture } from "./fixture.js";
import { ids } from "../../packages/db/src/seed.js";
import { Operations } from "../../apps/api/src/operations.js";

let f: Awaited<ReturnType<typeof fixture>>;
let admin: string;
let employee: string;
before(
  async () => {
    f = await fixture("attendance-recovery");
    admin = (await f.login("superadmin@example.test")).token;
    employee = (await f.login("employee@example.test")).token;
  },
  { timeout: 60000 },
);
after(async () => f?.close());

async function operate(token: string, operation: string, input: unknown) {
  const response = await f.app.inject({
    method: "POST",
    url: "/graphql",
    headers: { authorization: `Bearer ${token}` },
    payload: {
      query:
        "mutation($s:ID!,$o:String!,$i:JSON!){operate(siteId:$s,operation:$o,input:$i)}",
      variables: { s: ids.dg, o: operation, i: input },
    },
  });
  const result = response.json();
  assert.ok(result.data?.operate, JSON.stringify(result.errors));
  return result.data.operate;
}

async function photo(capturedAt: string) {
  const intent = await operate(employee, "fileIntent", {
    clientId: randomUUID(),
    purpose: "attendance",
    type: "image/jpeg",
    bytes: 12,
  });
  // Only the isolated synthetic fixture simulates a completed upload.
  await f.owner.query(
    "UPDATE app.private_files SET status='ready',created_at=$2 WHERE id=$1",
    [intent.id, new Date(Date.parse(capturedAt) + 1000)],
  );
  return intent.id;
}

function entry(dutyId: string, photoId: string, capturedAt: string) {
  return {
    clientEventId: randomUUID(),
    dutyId,
    sequence: 1,
    kind: "IN",
    capturedAt,
    payloadVersion: 1,
    policyVersion: 1,
    geofenceVersion: 1,
    photoId,
    location: {
      latitude: 28.6,
      longitude: 77.2,
      accuracyM: 10,
      observedAt: capturedAt,
      mocked: false,
    },
  };
}

test("online upload delay stays verified and an expired duty leaves an auditable missed exit", async () => {
  await operate(admin, "policy", {
    rules: {
      allowOffline: false,
      offlineMaxHours: 0,
      maxAccuracyM: 40,
      freshnessSeconds: 5,
      clockSkewSeconds: 30,
      gapSeconds: 120,
      maxSessionHours: 18,
      lateGraceMinutes: 10,
      earlyGraceMinutes: 10,
      attendanceApproverId: ids.admin,
    },
    expectedVersion: 0,
    reason: "Synthetic attendance recovery policy",
  });
  await operate(admin, "geofence", {
    coordinates: [
      [77.19, 28.59],
      [77.21, 28.59],
      [77.21, 28.61],
      [77.19, 28.61],
      [77.19, 28.59],
    ],
    label: "Synthetic attendance boundary",
    expectedVersion: 0,
    reason: "Synthetic attendance recovery boundary",
  });
  await f.owner.query(
    "UPDATE app.geofence_versions SET created_at=now()-interval '1 day' WHERE organization_id=$1 AND site_id=$2",
    [ids.org, ids.dg],
  );
  const firstCapture = new Date(Date.now() - 90_000).toISOString();
  const oldDuty = randomUUID();
  const first = entry(oldDuty, await photo(firstCapture), firstCapture);
  const accepted = await new Operations(f.runtime).command(
    (await f.auth.lookup(employee))!,
    ids.dg,
    "event",
    first,
  );
  assert.equal(accepted.status, "accepted");
  const agedStart = new Date(Date.now() - 19 * 3600_000);
  await f.owner.query("UPDATE app.duty_sessions SET opened_at=$2 WHERE id=$1", [
    oldDuty,
    agedStart,
  ]);
  // Advance the synthetic fixture's clock without waiting nineteen hours.
  await f.owner.query(
    "UPDATE app.event_verifications SET effective_at=$2 WHERE event_id=$1",
    [accepted.id, agedStart],
  );
  const newDuty = randomUUID();
  const newCapture = new Date().toISOString();
  const next = await operate(
    employee,
    "event",
    entry(newDuty, await photo(newCapture), newCapture),
  );
  assert.equal(next.status, "accepted");
  const rows = (
    await f.owner.query(
      "SELECT id,status,closed_at FROM app.duty_sessions WHERE id=ANY($1::uuid[]) ORDER BY opened_at",
      [[oldDuty, newDuty]],
    )
  ).rows;
  assert.deepEqual(
    rows.map((row) => row.status),
    ["needs_review", "open"],
  );
  assert.equal(rows[0].closed_at, null);
  assert.equal((await operate(employee, "event", first)).id, accepted.id);
  const response = await f.app.inject({
    method: "POST",
    url: "/graphql",
    headers: { authorization: `Bearer ${employee}` },
    payload: {
      query: "query($s:ID!){operations(siteId:$s)}",
      variables: { s: ids.dg },
    },
  });
  const snapshot = response.json().data.operations;
  assert.equal(snapshot.timezone, "Asia/Kolkata");
  assert.match(snapshot.workDate, /^\d{4}-\d{2}-\d{2}$/);
  assert.equal(
    snapshot.sessions.find((s: any) => s.id === oldDuty).status,
    "needs_review",
  );
  assert.ok(snapshot.sessions.find((s: any) => s.id === newDuty).expires_at);
  assert.ok(
    snapshot.events.find((e: any) => e.id === accepted.id).location_reason,
  );
  const outCaptured = new Date().toISOString();
  const pending = await operate(employee, "event", {
    ...entry(oldDuty, await photo(outCaptured), outCaptured),
    kind: "OUT",
    sequence: 2,
  });
  assert.equal(pending.status, "pending_verification");
  async function decide(at: string) {
    const response = await f.app.inject({
      method: "POST",
      url: "/graphql",
      headers: { authorization: `Bearer ${admin}` },
      payload: {
        query:
          "mutation($s:ID!,$o:String!,$i:JSON!){operate(siteId:$s,operation:$o,input:$i)}",
        variables: {
          s: ids.dg,
          o: "verifyEvent",
          i: {
            id: pending.id,
            expectedStatus: "pending_verification",
            approve: true,
            effectiveAt: at,
            reason: "Reviewed synthetic missed exit evidence",
          },
        },
      },
    });
    return response.json();
  }
  assert.equal(
    (await decide(new Date().toISOString())).errors[0].extensions.code,
    "BAD_INPUT",
  );
  assert.equal(
    (await decide(new Date(Date.now() - 2 * 3600_000).toISOString())).data
      .operate.status,
    "accepted",
  );
  assert.equal(
    (
      await f.owner.query("SELECT status FROM app.duty_sessions WHERE id=$1", [
        oldDuty,
      ])
    ).rows[0].status,
    "closed",
  );
});

test("review desk locates pending evidence from an earlier site work date", async () => {
  const dates = (
    await f.owner.query(
      `SELECT to_char(now() AT TIME ZONE timezone,'YYYY-MM-DD') today,
      to_char((now()-interval '1 day') AT TIME ZONE timezone,'YYYY-MM-DD') yesterday
     FROM app.sites WHERE id=$1`,
      [ids.dg],
    )
  ).rows[0];
  const dutyId = randomUUID();
  const employeeId = (
    await f.owner.query("SELECT id FROM app.employees WHERE user_id=$1", [
      ids.employee,
    ])
  ).rows[0].id;
  await f.owner.query(
    `INSERT INTO app.duty_sessions
      (id,organization_id,site_id,employee_id,user_id,device_id,
       policy_version,geofence_version,status,opened_at,closed_at)
     VALUES($1,$2,$3,$4,$5,$6,1,1,'closed',now()-interval '1 day',now()-interval '23 hours')`,
    [dutyId, ids.org, ids.dg, employeeId, ids.employee, randomUUID()],
  );
  const row = (
    await f.owner.query(
      `INSERT INTO app.duty_events
      (organization_id,site_id,employee_id,user_id,duty_id,client_event_id,
       device_id,sequence,kind,captured_at,payload_version,payload_hash,payload)
     SELECT organization_id,site_id,employee_id,user_id,id,$2,device_id,
       1,'OUT',now()-interval '1 day',1,'synthetic', '{}'::jsonb
     FROM app.duty_sessions WHERE id=$1 RETURNING id`,
      [dutyId, randomUUID()],
    )
  ).rows[0];
  await f.owner.query(
    `INSERT INTO app.event_verifications
      (organization_id,site_id,employee_id,event_id,status,reason)
     VALUES($1,$2,$3,$4,'pending_verification','Synthetic earlier evidence')`,
    [ids.org, ids.dg, employeeId, row.id],
  );
  async function review(day: string) {
    const response = await f.app.inject({
      method: "POST",
      url: "/graphql",
      headers: { authorization: `Bearer ${admin}` },
      payload: {
        query:
          "query($s:ID!,$d:String!){attendanceReview(siteId:$s,workDate:$d)}",
        variables: { s: ids.dg, d: day },
      },
    });
    const json = response.json();
    assert.ok(json.data?.attendanceReview, JSON.stringify(json.errors));
    return json.data.attendanceReview;
  }
  const today = await review(dates.today);
  assert.equal(today.earlierPendingCount, 1);
  assert.equal(today.oldestPendingDate, dates.yesterday);
  const yesterday = await review(dates.yesterday);
  assert.ok(yesterday.events.some((e: any) => e.id === row.id));
});
