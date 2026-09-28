import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { fixture } from "./fixture.js";
import { ids } from "../../packages/db/src/seed.js";
let f: Awaited<ReturnType<typeof fixture>>,
  hr: string,
  employee: string,
  own: string,
  other: string;
before(
  async () => {
    f = await fixture("attendance-day");
    hr = (await f.login("hr@example.test")).token;
    employee = (await f.login("employee@example.test")).token;
    const people = (
      await f.owner.query(
        "SELECT id,user_id FROM app.employees WHERE user_id=ANY($1::uuid[])",
        [[ids.employee, ids.admin]],
      )
    ).rows;
    own = people.find((r) => r.user_id === ids.employee).id;
    other = people.find((r) => r.user_id === ids.admin).id;
    // UTC evening is the NEXT work date at this Asia/Kolkata site.
    await f.owner.query(
      `INSERT INTO app.duty_sessions(organization_id,site_id,employee_id,user_id,device_id,policy_version,geofence_version,status,opened_at,closed_at)
    SELECT $1,$2,$3,$4,$5,1,1,'closed','2026-09-28T18:31:00Z'::timestamptz+n*interval '1 second','2026-09-28T19:31:00Z'::timestamptz+n*interval '1 second'
    FROM generate_series(1,105) n`,
      [ids.org, ids.dg, own, ids.employee, randomUUID()],
    );
    await f.owner.query(
      `INSERT INTO app.duty_sessions(organization_id,site_id,employee_id,user_id,device_id,policy_version,geofence_version,status,opened_at,closed_at)
    VALUES($1,$2,$3,$4,$5,1,1,'closed','2026-09-28T12:00Z','2026-09-28T13:00Z'),($1,$2,$3,$4,$5,1,1,'closed','2026-09-29T12:00Z','2026-09-29T13:00Z')`,
      [ids.org, ids.dg, other, ids.admin, randomUUID()],
    );
  },
  { timeout: 60000 },
);
after(async () => f?.close());
async function day(
  token: string,
  workDate: string,
  employeeId: string | null = null,
  offset = 0,
  site = ids.dg,
) {
  return (
    await f.app.inject({
      method: "POST",
      url: "/graphql",
      headers: { authorization: `Bearer ${token}` },
      payload: {
        query:
          "query($s:ID!,$d:String!,$e:ID,$o:Int){attendanceDay(siteId:$s,workDate:$d,employeeId:$e,offset:$o)}",
        variables: { s: site, d: workDate, e: employeeId, o: offset },
      },
    })
  ).json();
}
test("date filtering uses site midnight, employee selector is exact, and every page is reachable", async () => {
  const p1 = (await day(hr, "2026-09-29", own)).data.attendanceDay;
  const p2 = (await day(hr, "2026-09-29", own, 100)).data.attendanceDay;
  assert.equal(p1.timezone, "Asia/Kolkata");
  assert.equal(p1.sessions.length, 100);
  assert.equal(p1.hasMore, true);
  assert.equal(p2.sessions.length, 5);
  assert.equal(p2.hasMore, false);
  assert.equal(
    new Set([...p1.sessions, ...p2.sessions].map((r: any) => r.id)).size,
    105,
  );
  assert.ok(p1.sessions.every((r: any) => r.employee_id === own));
  const yesterday = (await day(hr, "2026-09-28", own)).data.attendanceDay;
  assert.equal(yesterday.sessions.length, 0);
  assert.deepEqual(p1.tasks, []);
  assert.deepEqual(p1.files, []);
});
test("attendance employee and site selectors never grant access", async () => {
  const denied = (await day(employee, "2026-09-29", other)).data.attendanceDay;
  assert.equal(denied.sessions.length, 0);
  assert.ok(denied.people.every((r: any) => r.id === own));
  assert.equal(
    (await day(employee, "2026-09-29", null, 0, ids.rg)).data.attendanceDay
      .sessions.length,
    0,
  );
  assert.ok((await day(employee, "2026-09-29", null, 0, ids.otherSite)).errors);
  assert.ok((await day(hr, "not-a-date")).errors);
});
