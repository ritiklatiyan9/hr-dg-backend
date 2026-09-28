import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { fixture } from "./fixture.js";
import { ids } from "../../packages/db/src/seed.js";
import { trendDays, topWithOther } from "../../apps/api/src/dashboard.js";
import type { DashboardSnapshot } from "../../packages/contracts/dashboard.js";

let f: Awaited<ReturnType<typeof fixture>>;
before(
  async () => {
    f = await fixture("dashboard");
  },
  { timeout: 60000 },
);
after(async () => {
  await f?.close();
});
async function gql(token: string, query: string, siteId: string = ids.dg) {
  return (
    await f.app.inject({
      method: "POST",
      url: "/graphql",
      headers: { authorization: `Bearer ${token}` },
      payload: { query, variables: { s: siteId } },
    })
  ).json();
}
const dashboard = async (token: string, siteId?: string) =>
  gql(token, "query($s:ID!){dashboard(siteId:$s)}", siteId);

test("helpers: 14 site-local days ending today; long tails fold into Other", () => {
  const days = trendDays("2026-03-02");
  assert.equal(days.length, 14);
  assert.equal(days[0], "2026-02-17");
  assert.equal(days.at(-1), "2026-03-02");
  const rows = [9, 8, 7, 6, 5, 4, 3].map((count, i) => ({
    name: `d${i}`,
    count,
  }));
  assert.deepEqual(topWithOther(rows, "count").at(-1), {
    name: "Other",
    count: 7,
  });
  assert.equal(topWithOther(rows.slice(0, 6), "count").length, 6);
});

test("sections follow site grants; approvals match the approval queue", async () => {
  for (const role of ["superadmin", "admin", "hr", "junior", "employee"]) {
    const { token } = await f.login(`${role}@example.test`);
    const r = await dashboard(token);
    assert.ok(r.data?.dashboard, `${role}: ${JSON.stringify(r.errors)}`);
    const d: DashboardSnapshot = r.data.dashboard;
    const scope = (
      await gql(token, "query($s:ID!){scope(siteId:$s){capabilities}}")
    ).data.scope.capabilities as string[];
    const has = (k: string) => scope.includes(k);
    assert.equal(!!d.people, has("employees.view"), `${role} people`);
    assert.equal(!!d.attendance, has("attendance.view"), `${role} attendance`);
    assert.equal(!!d.leave, has("leave.view"), `${role} leave`);
    assert.equal(!!d.tasks, has("tasks.view"), `${role} tasks`);
    assert.equal(!!d.dwr, has("dwr_review.view"), `${role} dwr`);
    assert.equal(
      !!d.location,
      has("employee_tracking.view"),
      `${role} location`,
    );
    if (d.attendance) assert.equal(d.attendance.trend.length, 14);
    if (d.dwr) assert.equal(d.dwr.trend.at(-1)!.day, d.workDate);
    if (d.people)
      assert.equal(
        d.people.departments.reduce((n, x) => n + x.count, 0),
        d.people.headcount,
      );
    const queue = (await gql(token, "query($s:ID!){approvalQueue(siteId:$s)}"))
      .data.approvalQueue.items as { kind: string }[];
    assert.equal(
      d.approvals.reduce((n, a) => n + a.count, 0),
      queue.length,
      `${role} approvals`,
    );
    // No names, emails or money leave the dashboard.
    assert.doesNotMatch(JSON.stringify(d), /@example\.test|Paise|netPaise/i);
  }
});

test("a revoked grant removes its section; other organizations stay closed", async () => {
  const { token } = await f.login("hr@example.test");
  const first = (await dashboard(token)).data.dashboard as DashboardSnapshot;
  assert.ok(first.people);
  await f.owner.query(
    "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,(SELECT id FROM auth.users WHERE email='hr@example.test'),'employees.view','deny','site') ON CONFLICT(organization_id,site_id,user_id,key) DO UPDATE SET effect='deny'",
    [ids.org, ids.dg],
  );
  const again = await f.login("hr@example.test");
  const after = (await dashboard(again.token)).data?.dashboard;
  assert.ok(after, "dashboard still loads");
  assert.equal(after.people, undefined);
  const foreign = await dashboard(again.token, ids.otherSite);
  assert.ok(foreign.errors?.length);
});

test("fast aggregates equal RLS-scoped counts for every role, including team scope", async () => {
  const { scoped } = await import("../../packages/db/src/index.js");
  const S = ids.dg,
    O = ids.org;
  // Activity today for everyone assigned here: rosters, sessions, DWRs in every
  // status (including a manual draft reviewers must not count), leave, tasks.
  await f.owner.query(`
    SET session_replication_role=replica;
    CREATE TEMP TABLE staff AS SELECT DISTINCT employee_id id,row_number() OVER () i FROM app.site_assignments WHERE site_id='${S}';
    CREATE TEMP TABLE today AS SELECT (now() AT TIME ZONE timezone)::date d,timezone tz FROM app.sites WHERE id='${S}';
    INSERT INTO app.shift_rosters(organization_id,site_id,employee_id,shift_id,work_date,starts_at,ends_at)
      SELECT '${O}','${S}',id,gen_random_uuid(),d,d+time '09:00',d+time '18:00' FROM staff,today ON CONFLICT DO NOTHING;
    INSERT INTO app.duty_sessions(organization_id,site_id,employee_id,user_id,device_id,policy_version,geofence_version,status,opened_at)
      SELECT '${O}','${S}',id,gen_random_uuid(),gen_random_uuid(),1,1,'closed',(d+time '09:05') AT TIME ZONE tz FROM staff,today
      WHERE NOT EXISTS(SELECT 1 FROM app.duty_sessions s WHERE s.employee_id=staff.id);
    INSERT INTO app.dwr_reports(organization_id,site_id,employee_id,user_id,work_date,status,origin,content)
      SELECT '${O}','${S}',id,gen_random_uuid(),d-(i%3)::int,(ARRAY['draft','submitted','approved','returned'])[1+i%4],(ARRAY['manual','chat'])[1+i%2],'{}' FROM staff,today
      ON CONFLICT DO NOTHING;
    INSERT INTO app.work_tasks(organization_id,site_id,employee_id,assignee_id,author_id,client_id,title,deadline,priority,status)
      SELECT '${O}','${S}',id,gen_random_uuid(),gen_random_uuid(),gen_random_uuid(),'t',now()+(i-2)*interval '1 day','normal',(ARRAY['todo','in_progress','blocked','done'])[1+i%4] FROM staff;
    -- A session left open three days ago (exit never recorded) and one live location sample.
    INSERT INTO app.duty_sessions(organization_id,site_id,employee_id,user_id,device_id,policy_version,geofence_version,status,opened_at)
      SELECT '${O}','${S}',id,gen_random_uuid(),gen_random_uuid(),1,1,'open',now()-interval '3 days' FROM staff WHERE i=1;
    INSERT INTO app.tracking_samples(organization_id,site_id,employee_id,user_id,device_id,client_id,payload_hash,roster_id,roster_version,policy_version,geofence_version,observed_at,point,accuracy_m,classification)
      SELECT '${O}','${S}',id,gen_random_uuid(),gen_random_uuid(),gen_random_uuid(),'h',gen_random_uuid(),1,1,1,now(),'SRID=4326;POINT(77.2 28.6)'::geography,10,'inside' FROM staff WHERE i=2;
    -- Staff 2 shares location but never checked in (the case that reads as "0 checked in").
    DELETE FROM app.duty_sessions WHERE status='closed' AND employee_id=(SELECT id FROM staff WHERE i=2);
    SET session_replication_role=origin;`);
  const stale =
    (
      await f.owner.query(
        "SELECT stale_seconds FROM app.tracking_policies WHERE site_id=$1 ORDER BY version DESC LIMIT 1",
        [S],
      )
    ).rows[0]?.stale_seconds ?? 120;
  const seen = { missing: 0, stale: 0, location: 0 };
  for (const role of [
    "superadmin",
    "admin",
    "hr",
    "junior",
    "manager",
    "supervisor",
    "employee",
  ]) {
    const { token, actor } = await f.login(`${role}@example.test`);
    const d: DashboardSnapshot = (await dashboard(token)).data.dashboard;
    const oracle = await scoped(f.runtime, actor, S, async (c) => {
      const q = async (sql: string) =>
        (await c.query(sql, [d.workDate, d.timezone])).rows[0];
      return {
        headcount: (
          await q(
            "SELECT count(DISTINCT employee_id)::int n FROM app.site_assignments WHERE starts_on<=$1::date AND (ends_on IS NULL OR ends_on>=$1::date) AND app.allowed('employees.view',employee_id) AND $2::text IS NOT NULL",
          )
        ).n,
        rostered: (
          await q(
            "SELECT count(*)::int n FROM app.shift_rosters WHERE work_date=$1::date AND app.allowed('attendance.view',employee_id) AND $2::text IS NOT NULL",
          )
        ).n,
        checkedIn: (
          await q(
            "SELECT count(DISTINCT employee_id)::int n FROM app.duty_sessions WHERE opened_at>=$1::date::timestamp AT TIME ZONE $2 AND opened_at<($1::date+1)::timestamp AT TIME ZONE $2 AND app.allowed('attendance.view',employee_id)",
          )
        ).n,
        dwrToday: (
          await q(
            "SELECT count(*)::int n FROM app.dwr_reports WHERE work_date=$1::date AND app.allowed('dwr_review.view',employee_id) AND (status<>'draft' OR origin='chat') AND $2::text IS NOT NULL",
          )
        ).n,
        notCheckedIn: (
          await q(
            "SELECT count(*)::int n FROM app.shift_rosters r WHERE r.work_date=$1::date AND app.allowed('attendance.view',r.employee_id) AND NOT EXISTS(SELECT 1 FROM app.duty_sessions s WHERE s.employee_id=r.employee_id AND s.opened_at>=$1::date::timestamp AT TIME ZONE $2 AND s.opened_at<($1::date+1)::timestamp AT TIME ZONE $2)",
          )
        ).n,
        exitNotRecorded: (
          await q(
            "SELECT count(*)::int n FROM app.duty_sessions s WHERE s.status='open' AND app.allowed('attendance.view',s.employee_id) AND s.opened_at+coalesce((SELECT (op.rules->>'maxSessionHours')::int FROM app.operation_policies op WHERE op.version=s.policy_version),24)*interval '1 hour'<=now() AND $1::date IS NOT NULL AND $2::text IS NOT NULL",
          )
        ).n,
        location: await q(
          `SELECT count(DISTINCT employee_id) FILTER(WHERE observed_at>now()-${stale}*interval '1 second')::int now,count(DISTINCT employee_id)::int today FROM app.tracking_samples WHERE observed_at>=$1::date::timestamp AT TIME ZONE $2 AND observed_at<($1::date+1)::timestamp AT TIME ZONE $2 AND app.allowed('employee_tracking.view',employee_id)`,
        ),
        named: (
          await q(
            "SELECT count(*)::int n FROM app.shift_rosters r WHERE r.work_date=$1::date AND app.allowed('attendance.view',r.employee_id) AND app.allowed('employees.view',r.employee_id) AND $2::text IS NOT NULL",
          )
        ).n,
        tasksOpen: (
          await q(
            "SELECT count(*)::int n FROM app.work_tasks WHERE status<>'done' AND app.allowed('tasks.view',employee_id) AND $1::date IS NOT NULL AND $2::text IS NOT NULL",
          )
        ).n,
      };
    });
    const sum = (xs?: { count: number }[]) =>
      xs?.reduce((n, x) => n + x.count, 0);
    if (d.people)
      assert.equal(d.people.headcount, oracle.headcount, `${role} headcount`);
    if (d.attendance) {
      assert.equal(d.attendance.rostered, oracle.rostered, `${role} rostered`);
      assert.equal(
        d.attendance.checkedIn,
        oracle.checkedIn,
        `${role} checkedIn`,
      );
      assert.equal(d.attendance.trend.at(-1)!.checkedIn, oracle.checkedIn);
    }
    if (d.dwr) assert.equal(sum(d.dwr.today), oracle.dwrToday, `${role} dwr`);
    if (d.tasks)
      assert.equal(sum(d.tasks.open), oracle.tasksOpen, `${role} tasks`);
    if (d.attendance) {
      assert.equal(
        d.attendance.notCheckedIn.count,
        oracle.notCheckedIn,
        `${role} not checked in`,
      );
      assert.equal(
        d.attendance.exitNotRecorded.count,
        oracle.exitNotRecorded,
        `${role} exit not recorded`,
      );
      // Names only for people the viewer may see in the directory.
      if (oracle.named === 0)
        assert.ok(
          d.attendance.notCheckedIn.people.every((p) => p.name === null),
        );
    }
    if (d.location)
      assert.deepEqual(d.location, oracle.location, `${role} location`);
    seen.missing += d.attendance?.notCheckedIn.count ?? 0;
    seen.stale += d.attendance?.exitNotRecorded.count ?? 0;
    seen.location += d.location?.today ?? 0;
    if (role === "manager" && d.people)
      assert.ok(d.people.headcount < 5, "team scope stays narrow");
  }
  assert.ok(
    seen.missing && seen.stale && seen.location,
    JSON.stringify(seen),
  );
});

test("employee lookup: permitted people only, wildcards are literal", async () => {
  const lookup = async (token: string, search: string) =>
    (
      await f.app.inject({
        method: "POST",
        url: "/graphql",
        headers: { authorization: `Bearer ${token}` },
        payload: {
          query:
            "query($s:ID!,$q:String!){employeeLookup(siteId:$s,search:$q)}",
          variables: { s: ids.dg, q: search },
        },
      })
    ).json();
  const { token: admin } = await f.login("admin@example.test");
  const all = (await lookup(admin, "a")).data.employeeLookup as {
    id: string;
    name: string;
    code: string;
  }[];
  assert.ok(all.length > 0 && all.length <= 8);
  assert.ok(all.every((e) => /a/i.test(`${e.name} ${e.code}`)));
  assert.deepEqual((await lookup(admin, "%")).data.employeeLookup, []);
  assert.deepEqual((await lookup(admin, "_")).data.employeeLookup, []);
  assert.ok((await lookup(admin, "")).errors, "empty search is rejected");
  const { token: manager, actor } = await f.login("manager@example.test");
  const team = (await lookup(manager, "e")).data.employeeLookup as {
    id: string;
  }[];
  const { scoped } = await import("../../packages/db/src/index.js");
  for (const e of team)
    assert.ok(
      await scoped(
        f.runtime,
        actor,
        ids.dg,
        async (c) =>
          (await c.query("SELECT app.allowed('employees.view',$1) ok", [e.id]))
            .rows[0].ok,
      ),
      "manager sees only permitted employees",
    );
});
