import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { createApp } from "../../apps/api/src/app.js";
import { Domain } from "../../apps/api/src/domain.js";
import { fixture } from "./fixture.js";
import { ids } from "../../packages/db/src/seed.js";
import { Analytics } from "../../apps/api/src/analytics.js";
import { AnalyticsProviderError } from "../../apps/api/src/analytics-provider.js";
let f: Awaited<ReturnType<typeof fixture>>, service: Analytics;
const input = { from: "2026-08-01", to: "2026-08-31", siteIds: [ids.dg] };
before(
  async () => {
    f = await fixture();
    service = new Analytics(f.runtime);
    await f.owner.query(
      "INSERT INTO app.site_memberships(organization_id,site_id,user_id) VALUES($1,$2,$3) ON CONFLICT DO NOTHING",
      [ids.org, ids.rg, ids.superAdmin],
    );
    for (const user of [ids.superAdmin, ids.siteAdmin, ids.admin, ids.manager])
      for (const site of [ids.dg, ids.rg])
        for (const key of ["analytics.view", "reports.view"])
          await f.owner.query(
            "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) SELECT $1,$2,$3,$4,'allow',$5 WHERE EXISTS(SELECT 1 FROM app.site_memberships WHERE organization_id=$1 AND site_id=$2 AND user_id=$3) ON CONFLICT(organization_id,site_id,user_id,key) DO UPDATE SET effect='allow',scope=excluded.scope",
            [ids.org, site, user, key, user === ids.manager ? "team" : "site"],
          );
  },
  { timeout: 60000 },
);
after(async () => {
  await f?.close();
});
test("same-origin web assets are served without exposing arbitrary files", async () => {
  const saved = { serve: process.env.SERVE_WEB, root: process.env.WEB_ROOT };
  process.env.SERVE_WEB = "true";
  process.env.WEB_ROOT = "apps/hr-web/dist";
  const app = await createApp(f.config, f.runtime, f.authPool, false);
  try {
    const r = await app.inject({ method: "GET", url: "/" });
    assert.equal(r.statusCode, 200);
    assert.match(r.body, /<div id="root">/);
    assert.equal(
      (await app.inject({ method: "GET", url: "/.env" })).statusCode,
      404,
    );
  } finally {
    await app.close();
    if (saved.serve === undefined) delete process.env.SERVE_WEB;
    else process.env.SERVE_WEB = saved.serve;
    if (saved.root === undefined) delete process.env.WEB_ROOT;
    else process.env.WEB_ROOT = saved.root;
  }
});
test("GraphQL profile aliases share a request loader but never the next request", async () => {
  const { token } = await f.login("employee@example.test");
  const original = Domain.prototype.profile;
  let calls = 0;
  Domain.prototype.profile = async function (...args) {
    calls++;
    return original.apply(this, args);
  };
  try {
    const payload = {
      query:
        "query($s:ID!,$id:ID!){a:employee(siteId:$s,id:$id){id} b:employee(siteId:$s,id:$id){id}}",
      variables: { s: ids.dg, id: ids.employeeProfile },
    };
    const req = {
      method: "POST" as const,
      url: "/graphql",
      headers: { authorization: `Bearer ${token}` },
      payload,
    };
    assert.ok((await f.app.inject(req)).json().data.a);
    assert.equal(calls, 1);
    assert.ok((await f.app.inject(req)).json().data.a);
    assert.equal(calls, 2);
  } finally {
    Domain.prototype.profile = original;
  }
});
test("deterministic zero-record dashboard has defined scope, sources, gaps and disabled AI", async () => {
  const { actor } = await f.login("hr@example.test");
  const result = await service.analyticsSnapshot(actor, ids.dg, input);
  assert.equal(result.sites.length, 1);
  assert.equal(result.sites[0]?.timezone, "Asia/Kolkata");
  assert.ok(
    result.sites[0]?.metrics.every(
      (m) => m.denominator && m.source && m.limitation,
    ),
  );
  assert.equal(
    result.sites[0]?.metrics.find((m) => m.id === "hours_unknown")?.value,
    "0",
  );
  assert.equal(
    result.sites[0]?.metrics.find((m) => m.id === "dwr_overdue")?.state,
    "not_configured",
  );
  assert.equal(result.explanation.mode, "setup_required");
});
test("all four panel roles and employee cannot gain analytics through navigation or forged scope", async () => {
  for (const role of ["superadmin", "admin", "hr", "junior", "employee"]) {
    const { token } = await f.login(`${role}@example.test`);
    const r = (
      await f.app.inject({
        method: "POST",
        url: "/graphql",
        headers: { authorization: `Bearer ${token}` },
        payload: {
          query: "query($s:ID!,$i:JSON!){analytics(siteId:$s,input:$i)}",
          variables: { s: ids.dg, i: input },
        },
      })
    ).json();
    if (["junior", "employee"].includes(role)) assert.ok(r.errors);
    else assert.ok(r.data?.analytics, JSON.stringify(r.errors));
    const wrong = await f.app.inject({
      method: "POST",
      url: "/analytics/tools/getAttendanceSummary",
      headers: { authorization: `Bearer ${token}` },
      payload: {
        siteId: ids.dg,
        input: { ...input, siteIds: [ids.dg, ids.otherSite] },
      },
    });
    assert.notEqual(wrong.statusCode, 200);
  }
});
test("tools reject model-selected scope, SQL, unknown arguments and arbitrary windows", async () => {
  const { token } = await f.login("hr@example.test");
  for (const bad of [
    { ...input, organizationId: ids.otherOrg },
    { ...input, sql: "SELECT * FROM auth.users" },
    { ...input, to: "2030-01-01" },
    { ...input, siteIds: [ids.dg, ids.dg] },
  ]) {
    const r = await f.app.inject({
      method: "POST",
      url: "/analytics/tools/getTaskBacklog",
      headers: { authorization: `Bearer ${token}` },
      payload: { siteId: ids.dg, input: bad },
    });
    assert.notEqual(r.statusCode, 200);
  }
});
test("team scopes intersect source scopes; raw payroll is suppressed", async () => {
  const { actor } = await f.login("manager@example.test"),
    r = await service.analyticsSnapshot(actor, ids.dg, input);
  assert.ok(
    r.sites[0]?.metrics.every((m) => m.unit !== "paise" || m.value === null),
  );
  const me = r.sites[0]?.metrics.find((m) => m.id === "workforce");
  assert.equal(me?.value, "1");
});
test("organization selection needs explicit reporting at anchor and current access at every site", async () => {
  await f.owner.query(
    "UPDATE app.access_overrides SET scope='organization' WHERE user_id=$1 AND key IN('analytics.view','reports.view')",
    [ids.superAdmin],
  );
  let session = await f.login("superadmin@example.test");
  assert.equal(
    (
      await service.analyticsSnapshot(session.actor, ids.dg, {
        ...input,
        siteIds: [ids.dg, ids.rg],
      })
    ).sites.length,
    2,
  );
  await f.owner.query(
    "UPDATE app.access_overrides SET effect='deny' WHERE user_id=$1 AND site_id=$2 AND key='analytics.view'",
    [ids.superAdmin, ids.rg],
  );
  await assert.rejects(() =>
    service.analyticsSnapshot(session.actor, ids.dg, input),
  );
  session = await f.login("superadmin@example.test");
  await assert.rejects(() =>
    service.analyticsSnapshot(session.actor, ids.dg, {
      ...input,
      siteIds: [ids.dg, ids.rg],
    }),
  );
});
test("provider calls hold no transaction, exclude sensitive values, and recheck revocation", async () => {
  Object.assign(process.env, {
    OPENROUTER_API_KEY: "synthetic-test",
    OPENROUTER_ANALYTICS_MODEL: "synthetic",
    OPENROUTER_ANALYTICS_PROVIDER: "synthetic",
    ANALYTICS_PROVIDER_REVIEWED_AT: "2026-09-22",
    ANALYTICS_USER_DAILY_CALLS: "10",
    ANALYTICS_ORG_DAILY_CALLS: "20",
    ANALYTICS_CONCURRENCY: "2",
  });
  const small = await f.login("manager@example.test");
  const suppressed = await service.explainAnalytics(
    small.actor,
    ids.dg,
    input,
    {
      async explain() {
        throw Error("Small cohorts must not reach provider");
      },
    },
  );
  assert.equal(suppressed.explanation.mode, "insufficient_evidence");
  await f.owner.query(
    "INSERT INTO app.employees(id,organization_id,employee_code,display_name,work_email) SELECT md5('analytics-fixture-'||i)::uuid,$1,'ANALYTICS-'||i,'Synthetic analytics fixture','analytics-'||i||'@example.test' FROM generate_series(1,8)i",
    [ids.org],
  );
  await f.owner.query(
    "INSERT INTO app.site_assignments(organization_id,site_id,employee_id,starts_on) SELECT $1,$2,id,'2025-01-01' FROM app.employees WHERE employee_code LIKE 'ANALYTICS-%'",
    [ids.org, ids.dg],
  );
  const { actor } = await f.login("hr@example.test");
  const r = await service.explainAnalytics(actor, ids.dg, input, {
    async explain(facts) {
      assert.equal(f.runtime.idleCount, f.runtime.totalCount);
      assert.ok(facts.every((x) => x.metric.unit !== "paise"));
      return { items: [{ factId: facts[0]!.id, reading: "observed" }] };
    },
  });
  assert.equal(r.explanation.mode, "explained");
  const invalid = await service.explainAnalytics(actor, ids.dg, input, {
    async explain() {
      return {
        items: [
          { factId: "fake_payroll", reading: "observed", value: "999999" },
        ],
      };
    },
  });
  assert.equal(invalid.explanation.mode, "recoverable_error");
  await assert.rejects(() =>
    service.explainAnalytics(actor, ids.dg, input, {
      async explain() {
        await f.owner.query(
          "UPDATE app.access_overrides SET effect='deny' WHERE user_id=$1 AND key='analytics.view'",
          [ids.admin],
        );
        return { items: [] };
      },
    }),
  );
  await f.owner.query(
    "UPDATE app.access_overrides SET effect='allow' WHERE user_id=$1 AND key='analytics.view'",
    [ids.admin],
  );
});
test("provider Retry-After prevents immediate reattempts across durable admission", async () => {
  const { actor } = await f.login("hr@example.test");
  await service.explainAnalytics(actor, ids.dg, input, {
    async explain() {
      throw new AnalyticsProviderError(60);
    },
  });
  const r = await service.explainAnalytics(actor, ids.dg, input, {
    async explain() {
      throw Error("must not call");
    },
  });
  assert.equal(r.explanation.mode, "budget_exhausted");
});
test("aggregate boundary clips overnight latest revisions, preserves unknown time and rejects unscoped calls", async () => {
  const duty = randomUUID();
  await f.owner.query(
    "INSERT INTO app.operation_policies(organization_id,site_id,version,rules,reason) VALUES($1,$2,1,'{\"lateGraceMinutes\":10,\"earlyGraceMinutes\":10}','SYNTHETIC')",
    [ids.org, ids.dg],
  );
  await f.owner.query(
    "INSERT INTO app.duty_sessions(id,organization_id,site_id,employee_id,user_id,device_id,policy_version,geofence_version,status,opened_at,closed_at) VALUES($1,$2,$3,$4,$5,$1,1,1,'closed','2026-08-31T22:00:00+05:30','2026-09-01T06:00:00+05:30')",
    [duty, ids.org, ids.dg, ids.employeeProfile, ids.employee],
  );
  await f.owner.query(
    "INSERT INTO app.shift_rosters(organization_id,site_id,employee_id,shift_id,work_date,starts_at,ends_at) VALUES($1,$2,$3,$2,'2026-08-31','2026-08-31T22:00:00+05:30','2026-09-01T06:00:00+05:30')",
    [ids.org, ids.dg, ids.employeeProfile],
  );
  for (const revision of [1, 2])
    await f.owner.query(
      "INSERT INTO app.duty_segments(organization_id,site_id,employee_id,duty_id,revision,engine_version,starts_at,ends_at,kind,source_ids,assumption) VALUES($1,$2,$3,$4,$5,1,'2026-08-31T22:00:00+05:30','2026-09-01T06:00:00+05:30',$6,'[]','SYNTHETIC')",
      [
        ids.org,
        ids.dg,
        ids.employeeProfile,
        duty,
        revision,
        revision === 1 ? "office" : "unknown",
      ],
    );
  const { actor } = await f.login("admin@example.test");
  const r = await service.analyticsSnapshot(
    actor,
    ids.dg,
    { ...input, from: "2026-08-31" },
    "getAttendanceSummary",
  );
  const metrics = Object.fromEntries(
    r.sites[0]!.metrics.map((m) => [m.id, m.value]),
  );
  assert.equal(metrics.attendance_rostered, "1");
  assert.equal(metrics.attendance_observed, "1");
  assert.equal(metrics.hours_unknown, "7200");
  assert.equal(metrics.hours_office, "0");
  assert.equal(metrics.attendance_early, "0");
  await assert.rejects(() =>
    f.runtime.query(
      "SELECT app.analytics_attendance('2026-08-01','2026-08-31')",
    ),
  );
  await assert.rejects(() =>
    service.site(actor, ids.dg, (c) =>
      c.query("SELECT app.analytics_attendance('2020-01-01','2026-08-31')"),
    ),
  );
  await assert.rejects(() =>
    service.site(actor, ids.dg, (c) =>
      c.query("SELECT app.analytics_workload('sql','2026-08-01','2026-08-31')"),
    ),
  );
});
