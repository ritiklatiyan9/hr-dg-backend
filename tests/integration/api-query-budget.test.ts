import { randomUUID } from "node:crypto";
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import type pg from "pg";
import { fixture } from "./fixture.js";
import { pool, scoped } from "../../packages/db/src/index.js";
import { readJson } from "../../packages/db/src/read-json.js";
import { ids } from "../../packages/db/src/seed.js";
import { Dashboard } from "../../apps/api/src/dashboard.js";
import { Tracking } from "../../apps/api/src/tracking.js";
import type { Actor } from "../../packages/authz/src/index.js";

let f: Awaited<ReturnType<typeof fixture>>,
  runtime: pg.Pool,
  actor: Actor,
  api: Dashboard,
  employeeId: string,
  count = 0;
before(
  async () => {
    f = await fixture("query-budget");
    actor = (await f.login("hr@example.test")).actor;
    employeeId = (
      await f.owner.query("SELECT id FROM app.employees WHERE user_id=$1", [
        actor.id,
      ])
    ).rows[0].id;
    for (const key of [
      "analytics.view",
      "reports.view",
      "employee_tracking.view",
      "site_settings.view",
      "attendance.edit",
    ])
      await f.owner.query(
        "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,$4,'allow','site') ON CONFLICT(organization_id,site_id,user_id,key) DO UPDATE SET effect='allow',scope='site'",
        [ids.org, ids.dg, actor.id, key],
      );
    // Refresh the verified actor after permission-version changes.
    actor = (await f.login("hr@example.test")).actor;
    runtime = pool(f.config.DATABASE_URL, 1);
    runtime.on("connect", (c) => {
      c.query = new Proxy(c.query, {
        apply(target, self, args) {
          count++;
          return Reflect.apply(target, self, args);
        },
      });
    });
    api = new Dashboard(runtime);
  },
  { timeout: 60_000 },
);
after(async () => {
  await runtime?.end();
  await f?.close();
});
async function budget<T>(name: string, limit: number, run: () => Promise<T>) {
  count = 0;
  const start = performance.now(),
    value = await run();
  console.log(
    `${name}: ${count} DB calls, ${Math.round(performance.now() - start)}ms (local synthetic data)`,
  );
  assert.ok(count <= limit, `${name}: ${count} calls exceeds ${limit}`);
  return { value, count };
}
async function seedRows(from: number, to: number) {
  await f.owner.query(
    `INSERT INTO app.hr_records(organization_id,site_id,kind,employee_id,user_id,created_by,payload)
    SELECT $1,$2,'expense',$3,$4,$4,jsonb_build_object('title','Synthetic expense '||n) FROM generate_series($5::int,$6::int) n`,
    [ids.org, ids.dg, employeeId, actor.id, from, to],
  );
  await f.owner.query(
    `INSERT INTO app.dwr_reports(organization_id,site_id,employee_id,user_id,work_date,content)
    SELECT $1,$2,$3,$4,CURRENT_DATE-n,jsonb_build_object('sourceTranscript','Synthetic source '||n) FROM generate_series($5::int,$6::int) n`,
    [ids.org, ids.dg, employeeId, actor.id, from, to],
  );
}
test("HR and DWR query counts remain constant when a page grows from one to forty records", async () => {
  await seedRows(1, 1);
  const hr1 = await budget("HR 1 row", 7, () =>
    api.hrSnapshot(actor, ids.dg, "expense"),
  );
  const dwr1 = await budget("DWR 1 row", 8, () =>
    api.dwrSnapshot(actor, ids.dg),
  );
  assert.equal(hr1.value.records.length, 1);
  assert.equal(dwr1.value.reports.length, 1);
  await seedRows(2, 40);
  const hr40 = await budget("HR 40 rows", 7, () =>
    api.hrSnapshot(actor, ids.dg, "expense"),
  );
  const dwr40 = await budget("DWR 40 rows", 8, () =>
    api.dwrSnapshot(actor, ids.dg),
  );
  assert.equal(hr40.value.records.length, 40);
  assert.equal(dwr40.value.reports.length, 40);
  assert.equal(hr1.count, hr40.count);
  assert.equal(dwr1.count, dwr40.count);
  assert.ok(
    hr40.value.records.every(
      (r) =>
        !("handlers" in r) &&
        Array.isArray(r.actions) &&
        Array.isArray(r.history),
    ),
  );
});
test("page entry points have explicit bounded database round-trip budgets", async () => {
  await budget("bootstrap", 5, () => api.bootstrap(actor));
  await budget("scope", 5, () => api.scope(actor, ids.dg));
  await budget("employees", 8, () => api.list(actor, ids.dg));
  await budget("foundation", 6, () => api.foundation(actor, ids.dg));
  await budget("operations", 10, () => api.snapshot(actor, ids.dg));
  await budget("dashboard", 14, () => api.dashboard(actor, ids.dg));
  await budget("payroll", 7, () => api.payrollSnapshot(actor, ids.dg));
  await budget("DWR chat", 8, () =>
    api.dwrChat(actor, ids.dg, { view: "home" }),
  );
  await budget("DWR personal thread", 8, () =>
    api.dwrChat(actor, ids.dg, { view: "thread", groupId: null }),
  );
  await budget("attendance day", 9, () =>
    api.snapshot(actor, ids.dg, { workDate: "2026-09-29" }),
  );
  await budget("tracking", 8, () =>
    new Tracking(runtime).trackingMonitor(actor, ids.dg, {}),
  );
  await budget("analytics", 21, () =>
    api.analyticsSnapshot(actor, ids.dg, {
      siteIds: [ids.dg],
      from: "2026-01-01",
      to: "2026-01-31",
    }),
  );
});
test("batched JSON reads keep parameters bound, empty arrays, and tenant RLS", async () => {
  await scoped(runtime, actor, ids.dg, async (c) => {
    const marker = "'); SELECT 'not sql'; --";
    const data = await readJson(c, {
      first: ["SELECT $1::text value", [marker]],
      second: ["SELECT $1::int value", [7]],
      empty: ["SELECT id FROM app.employees WHERE false"],
      other: [
        "SELECT id FROM app.employees WHERE organization_id=$1",
        [ids.otherOrg],
      ],
    });
    assert.deepEqual(data, {
      first: [{ value: marker }],
      second: [{ value: 7 }],
      empty: [],
      other: [],
    });
  });
});

test("bulk roster scheduling has constant queries and keeps unchanged versions", async () => {
  const shiftId = randomUUID();
  await f.owner.query(
    "INSERT INTO app.site_reference_items(id,organization_id,site_id,kind,name,details) VALUES($1,$2,$3,'shift','Synthetic audit shift',$4)",
    [shiftId, ids.org, ids.dg, { startTime: "09:00", endTime: "17:00" }],
  );
  const day = (offset: number) =>
    new Date(Date.now() + offset * 86400000).toISOString().slice(0, 10);
  const input = {
    employeeIds: [employeeId],
    shiftId,
    fromDate: day(2),
    toDate: day(2),
    weekdays: [0, 1, 2, 3, 4, 5, 6],
  };
  const one = await budget("roster 1 day", 13, () =>
    api.command(actor, ids.dg, "rosterRange", input),
  );
  const week = await budget("roster 7 days", 13, () =>
    api.command(actor, ids.dg, "rosterRange", { ...input, toDate: day(8) }),
  );
  assert.equal(one.count, week.count);
  assert.equal(one.value.assigned, 1);
  assert.equal(week.value.assigned, 7);
  const before = (
    await f.owner.query(
      "SELECT id,version FROM app.shift_rosters WHERE shift_id=$1 ORDER BY id",
      [shiftId],
    )
  ).rows;
  await api.command(actor, ids.dg, "rosterRange", { ...input, toDate: day(8) });
  assert.deepEqual(
    (
      await f.owner.query(
        "SELECT id,version FROM app.shift_rosters WHERE shift_id=$1 ORDER BY id",
        [shiftId],
      )
    ).rows,
    before,
  );
});
