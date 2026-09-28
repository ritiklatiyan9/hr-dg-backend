import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import pg from "pg";
import { fixture } from "./fixture.js";
import { ids } from "../../packages/db/src/seed.js";
import { permissionKeys } from "../../packages/authz/src/catalogue.js";
let f: Awaited<ReturnType<typeof fixture>>;
const token: Record<string, string> = {};
let employment: string, adminEmployment: string, today: string;
const calculation = (paise = "3000000") => ({
  rounding: "half_up_line",
  accountantReview: true,
  policyVersion: "SYNTHETIC-ACCOUNTANT-REVIEW",
  assumptions: "Synthetic rules; no statutory deductions configured",
  lines: [
    {
      code: "BASE",
      label: "Base",
      kind: "earning",
      paise,
      numerator: 1,
      denominator: 1,
    },
  ],
});
const reason = "Synthetic reviewed payroll evidence";
async function gql(who: string, query: string, variables: object) {
  return (
    await f.app.inject({
      method: "POST",
      url: "/graphql",
      headers: { authorization: `Bearer ${token[who]}` },
      payload: { query, variables },
    })
  ).json();
}
const cmd = (who: string, o: string, i: object) =>
  gql(
    who,
    "mutation($s:ID!,$o:String!,$i:JSON!){payrollCommand(siteId:$s,operation:$o,input:$i)}",
    { s: ids.dg, o, i },
  );
const list = async (who: string, i: object = {}) => {
  const r = await gql(
    who,
    "query($s:ID!,$i:JSON){payroll(siteId:$s,input:$i)}",
    { s: ids.dg, i },
  );
  assert.ok(r.data?.payroll, JSON.stringify(r.errors));
  return r.data.payroll;
};
const ok = (r: any) => {
  assert.ok(r.data?.payrollCommand, JSON.stringify(r.errors));
  return r.data.payrollCommand;
};
const rejects = (r: any, pattern?: RegExp) => {
  assert.ok(r.errors?.length, JSON.stringify(r));
  if (pattern) assert.match(r.errors[0].message, pattern);
};
const step = (who: string, op: string, r: any) =>
  cmd(who, op, {
    clientId: randomUUID(),
    id: r.id,
    expectedVersion: r.version,
    reason,
  }).then(ok);
const find = async (who: string, id: string) =>
  (await list(who)).results.find((r: any) => r.id === id);
before(
  async () => {
    f = await fixture("payroll");
    for (const user of [ids.superAdmin, ids.siteAdmin, ids.admin])
      for (const key of permissionKeys.filter((k) => k.startsWith("payroll.")))
        await f.owner.query(
          "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,$4,'allow','site') ON CONFLICT(organization_id,site_id,user_id,key) DO UPDATE SET effect='allow',scope='site'",
          [ids.org, ids.dg, user, key],
        );
    for (const [who, email] of [
      ["hr", "hr"],
      ["admin", "admin"],
      ["super", "superadmin"],
      ["employee", "employee"],
    ] as const)
      token[who] = (await f.login(`${email}@example.test`)).token;
    const job = (profile: string) =>
      f.owner
        .query("SELECT id FROM app.employment_records WHERE employee_id=$1", [
          profile,
        ])
        .then((r) => r.rows[0].id);
    employment = await job(ids.employeeProfile);
    adminEmployment = await job(ids.adminEmployee);
    today = (
      await f.owner.query(
        "SELECT (now() AT TIME ZONE timezone)::date::text d FROM app.sites WHERE id=$1",
        [ids.dg],
      )
    ).rows[0].d;
  },
  { timeout: 90000 },
);
after(() => f?.close());
let march: any, april: any;
test("payroll run drafts only fully covered structures, skips the rest and is idempotent", async () => {
  ok(
    await cmd("hr", "structure", {
      clientId: randomUUID(),
      expectedVersion: 0,
      employmentId: employment,
      startsOn: "2026-01-01",
      endsOn: "2026-12-31",
      calculation: calculation(),
      reason,
    }),
  );
  const input = {
    clientId: randomUUID(),
    periodStart: "2026-03-01",
    periodEnd: "2026-03-31",
    attendanceNote: "Explicit approved paid units; no GPS deductions",
    reason,
  };
  rejects(await cmd("employee", "run", input));
  const run = ok(await cmd("hr", "run", input));
  assert.equal(run.created.length, 1);
  assert.equal(run.created[0].employmentId, employment);
  assert.deepEqual(
    run.skipped.find((s: any) => s.employmentId === adminEmployment),
    { employmentId: adminEmployment, reason: "no_structure" },
  );
  assert.deepEqual(ok(await cmd("hr", "run", input)), run);
  const again = ok(
    await cmd("hr", "run", { ...input, clientId: randomUUID() }),
  );
  assert.equal(again.created.length, 0);
  assert.ok(
    again.skipped.some(
      (s: any) => s.employmentId === employment && s.reason === "exists",
    ),
  );
  const partial = ok(
    await cmd("hr", "run", {
      ...input,
      clientId: randomUUID(),
      periodStart: "2025-12-15",
      periodEnd: "2026-01-14",
    }),
  );
  assert.ok(
    partial.skipped.some(
      (s: any) =>
        s.employmentId === employment && s.reason === "structure_partial",
    ),
  );
  march = await find("hr", run.created[0].id);
  assert.equal(march.status, "draft");
  assert.equal(march.snapshot.netPaise, "3000000");
  assert.equal(march.history[0].event, "run");
  assert.equal(march.snapshot.segments, undefined, "list omits heavy evidence");
  april = await find(
    "hr",
    ok(
      await cmd("hr", "run", {
        ...input,
        clientId: randomUUID(),
        periodStart: "2026-04-01",
        periodEnd: "2026-04-30",
      }),
    ).created[0].id,
  );
});
test("bulk transitions are atomic and keep maker-checker separation", async () => {
  const items = (rs: any[]) =>
    rs.map((r) => ({ id: r.id, expectedVersion: r.version }));
  const bulk = (who: string, op: string, rs: any[]) =>
    cmd(who, op, { clientId: randomUUID(), items: items(rs), reason });
  let r = ok(await bulk("hr", "validate", [march, april]));
  assert.deepEqual(
    r.results.map((x: any) => x.status),
    ["validated", "validated"],
  );
  [march, april] = r.results;
  rejects(await bulk("hr", "review", [march, april]), /Result 1 of 2/);
  rejects(
    await bulk("admin", "review", [march, { ...april, version: 1 }]),
    /Result 2 of 2/,
  );
  assert.equal(
    (await find("hr", march.id)).status,
    "validated",
    "failed batch rolled back",
  );
  rejects(
    await cmd("admin", "review", {
      clientId: randomUUID(),
      items: items([march, march]),
      reason,
    }),
  );
  [march, april] = ok(await bulk("admin", "review", [march, april])).results;
  rejects(await bulk("admin", "approve", [march, april]));
  [march, april] = ok(await bulk("super", "approve", [march, april])).results;
  [march] = ok(await bulk("admin", "publish", [march])).results;
  assert.equal(march.status, "published");
  assert.equal(april.status, "approved");
});
test("payments reconcile to the pay-period chain, reject overpayment/self/future and reverse append-only", async () => {
  const pay = (who: string, id: string, paise: string, extra: object = {}) =>
    cmd(who, "pay", {
      clientId: randomUUID(),
      items: [{ id, paise }],
      method: "bank_transfer",
      reference: "UTR0000001",
      paidOn: today,
      reason,
      ...extra,
    });
  rejects(await pay("employee", march.id, "100"));
  rejects(
    await pay("admin", march.id, "100", { paidOn: "2999-01-01" }),
    /future/,
  );
  rejects(await pay("admin", march.id, "100", { reference: "=HYPERLINK(1)" }));
  rejects(await pay("admin", march.id, "0"));
  const replay = {
    clientId: randomUUID(),
    items: [{ id: march.id, paise: "1000000" }],
    method: "upi",
    reference: "UPI/REF-1",
    paidOn: today,
    reason,
  };
  const first = ok(await cmd("admin", "pay", replay)).payments[0];
  assert.deepEqual(ok(await cmd("admin", "pay", replay)).payments[0], first);
  rejects(await pay("admin", march.id, "2000001"), /exceeds the balance due/);
  const race = await Promise.all([
    pay("admin", march.id, "2000000"),
    pay("super", march.id, "2000000"),
  ]);
  assert.equal(
    race.filter((x) => x.data?.payrollCommand).length,
    1,
    JSON.stringify(race),
  );
  let mine = (await list("employee")).results.find(
    (r: any) => r.id === march.id,
  );
  assert.equal(mine.paidPaise, "3000000");
  assert.equal(mine.duePaise, "0");
  assert.equal(mine.payments.length, 2);
  assert.ok(
    (await list("admin", { payment: "paid" })).results.some(
      (r: any) => r.id === march.id,
    ),
  );
  assert.ok(
    !(await list("admin", { payment: "due" })).results.some(
      (r: any) => r.id === march.id,
    ),
  );
  const reverse = (who: string, paymentId: string) =>
    cmd(who, "reverse_payment", { clientId: randomUUID(), paymentId, reason });
  const reversal = ok(await reverse("admin", first.id));
  rejects(await reverse("super", first.id), /already reversed/);
  rejects(await reverse("admin", reversal.id));
  assert.equal((await find("admin", march.id)).duePaise, "1000000");
  // The ledger is append-only for the runtime role.
  await assert.rejects(
    f.runtime.query("UPDATE app.payroll_payments SET amount_paise=1"),
    /permission denied/,
  );
  // Payments on an approved result, and the beneficiary can never record their own.
  assert.equal(ok(await pay("admin", april.id, "3000000")).payments.length, 1);
  await f.owner.query(
    `SET session_replication_role=replica;
     INSERT INTO app.payroll_results(organization_id,site_id,employment_id,employee_id,user_id,legal_employer_id,period_start,period_end,status,input,snapshot,allocations,reason,created_by)
     VALUES('${ids.org}','${ids.dg}','${adminEmployment}','${ids.adminEmployee}','${ids.admin}','${ids.employer}','2026-03-01','2026-03-31','approved','{}','{"netPaise":"500","grossPaise":"500","deductionPaise":"0","employeeName":"HR"}','[]','synthetic','${ids.siteAdmin}');
     SET session_replication_role=origin;`,
  );
  const own = (
    await f.owner.query(
      "SELECT id FROM app.payroll_results WHERE employment_id=$1",
      [adminEmployment],
    )
  ).rows[0].id;
  rejects(await pay("hr", own, "500"), /own salary/);
});
test("a correction revision takes over the balance and supersedes its predecessor", async () => {
  const correction = ok(
    await cmd("hr", "save", {
      clientId: randomUUID(),
      expectedVersion: 0,
      employmentId: employment,
      periodStart: "2026-03-01",
      periodEnd: "2026-03-31",
      calculation: calculation("3100000"),
      allocations: [{ siteId: ids.dg, paise: "3100000" }],
      attendanceNote: "Explicit approved paid units; no GPS deductions",
      reason,
      previousId: march.id,
    }),
  );
  let r = await step("hr", "validate", correction);
  r = await step("admin", "review", r);
  r = await step("super", "approve", r);
  const pay = (id: string, paise: string) =>
    cmd("admin", "pay", {
      clientId: randomUUID(),
      items: [{ id, paise }],
      method: "cheque",
      reference: "CHQ 000123",
      paidOn: today,
      reason,
    });
  rejects(await pay(march.id, "100"), /newer revision/);
  assert.equal((await find("admin", r.id)).duePaise, "1100000");
  ok(await pay(r.id, "1100000"));
  rejects(await pay(r.id, "1"), /exceeds/);
  r = await step("admin", "publish", r);
  const old = await find("admin", march.id);
  assert.equal(old.superseded, true);
  assert.equal(old.duePaise, null);
  const now = await find("employee", r.id);
  assert.equal(now.duePaise, "0");
  const slip = await f.app.inject({
    url: `/payroll/${r.id}/print?siteId=${ids.dg}`,
    headers: { authorization: `Bearer ${token.employee}` },
  });
  assert.equal(slip.statusCode, 200);
  assert.match(slip.body, /Payments recorded/);
  assert.match(slip.body, /CHQ 000123/);
  const register = (who: string) =>
    f.app.inject({
      url: `/payroll/register/csv?siteId=${ids.dg}&from=2026-03-01&to=2026-03-31`,
      headers: { authorization: `Bearer ${token[who]}` },
    });
  assert.equal((await register("employee")).statusCode, 403);
  const csv = (await register("admin")).body.split("\r\n");
  assert.match(csv[0]!, /^"Employee code","Employee"/);
  assert.equal(
    csv.filter((l) => l.includes('"2026-03-01"') && l.includes('"published"'))
      .length,
    1,
    "superseded revision excluded",
  );
  assert.ok(csv.some((l) => l.includes('"31000.00","31000.00","0.00"')));
});
test("keyset pages are complete, scope-bound and cost a fixed number of queries", async () => {
  await f.owner.query(`
    SET session_replication_role=replica;
    WITH e AS (
      INSERT INTO app.employees(organization_id,employee_code,display_name,work_email)
      SELECT '${ids.org}','PG'||g,'Paged '||g,'pg'||g||'@example.test' FROM generate_series(1,60) g RETURNING id),
    a AS (INSERT INTO app.site_assignments(organization_id,site_id,employee_id,starts_on) SELECT '${ids.org}','${ids.dg}',id,'2024-01-01' FROM e RETURNING employee_id)
    INSERT INTO app.employment_records(organization_id,employee_id,legal_employer_id,starts_on) SELECT '${ids.org}',employee_id,'${ids.employer}','2024-01-01' FROM a;
    WITH r AS (
      INSERT INTO app.payroll_results(organization_id,site_id,employment_id,employee_id,user_id,legal_employer_id,period_start,period_end,status,input,snapshot,allocations,reason,created_by)
      SELECT er.organization_id,'${ids.dg}',er.id,er.employee_id,'${ids.employee}',er.legal_employer_id,make_date(2025,m,1),(make_date(2025,m,1)+interval '1 month -1 day')::date,
        'reviewed','{}',jsonb_build_object('netPaise','100','employeeName',e.display_name,'employeeCode',e.employee_code,'lines','[]'::jsonb),'[]','synthetic','${ids.admin}'
      FROM app.employment_records er JOIN app.employees e ON e.id=er.employee_id AND e.employee_code LIKE 'PG%', generate_series(1,3) m RETURNING id,organization_id,site_id)
    INSERT INTO app.payroll_history(organization_id,site_id,result_id,version,actor_id,event,reason,snapshot) SELECT organization_id,site_id,id,1,'${ids.admin}','save','synthetic','{}' FROM r;
    SET session_replication_role=origin;`);
  const all = (
    await f.owner.query(
      "SELECT count(*)::int n FROM app.payroll_results WHERE site_id=$1",
      [ids.dg],
    )
  ).rows[0].n;
  let queries = 0;
  const original = pg.Client.prototype.query;
  (pg.Client.prototype as any).query = function (...a: any[]) {
    queries++;
    return (original as any).apply(this, a);
  };
  const seen: any[] = [];
  let after: string | undefined,
    pages = 0;
  try {
    do {
      queries = 0;
      const page = await list("admin", { first: 50, ...(after && { after }) });
      assert.ok(queries <= 12, `page ${pages} used ${queries} queries`);
      seen.push(...page.results);
      after = page.endCursor ?? undefined;
      pages++;
    } while (after);
  } finally {
    pg.Client.prototype.query = original;
  }
  assert.equal(pages, Math.ceil(all / 50));
  assert.equal(new Set(seen.map((r) => r.id)).size, all);
  for (let i = 1; i < seen.length; i++)
    assert.ok(seen[i - 1].periodStart >= seen[i].periodStart);
  const first = await list("admin", { first: 50 });
  for (const bad of [
    { first: 50, after: "not-a-cursor" },
    { first: 50, status: "reviewed", after: first.endCursor },
  ]) {
    const r = await gql(
      "admin",
      "query($s:ID!,$i:JSON){payroll(siteId:$s,input:$i)}",
      { s: ids.dg, i: bad },
    );
    assert.equal(r.errors?.[0]?.extensions?.code, "BAD_CURSOR");
  }
  const searched = await list("admin", { search: "Paged 7", summary: true });
  assert.ok(
    searched.results.length >= 3 &&
      searched.results.every((r: any) =>
        /Paged 7/.test(r.snapshot.employeeName),
      ),
  );
  assert.equal(
    searched.summary.find((s: any) => s.status === "reviewed").count,
    searched.results.length,
  );
  assert.equal(
    (await list("employee")).results.every(
      (r: any) => r.status === "published" && r.user_id === ids.employee,
    ),
    true,
  );
});
test("payslip design: managers save versioned designs and every payslip print uses them", async () => {
  const sharp = (await import("sharp")).default;
  const logo = `data:image/jpeg;base64,${(
    await sharp({
      create: { width: 900, height: 300, channels: 3, background: "#1e6b4b" },
    })
      .jpeg()
      .toBuffer()
  ).toString("base64")}`;
  const initial = (await list("employee", { design: true, first: 1 })).design;
  assert.equal(initial.version, 0);
  assert.equal(initial.design.title, "Salary Slip");
  const design = {
    ...initial.design,
    title: "Pay Advice",
    companyName: "Synthetic Garden Co <b>",
    accent: "#123456",
    layout: "modern",
    logo,
  };
  const save = (who: string, expectedVersion: number, d: object = design) =>
    cmd(who, "design", { clientId: randomUUID(), expectedVersion, design: d });
  rejects(await save("employee", 0), /permission/i);
  rejects(await save("hr", 0, { ...design, accent: "red;}" }));
  assert.equal(ok(await save("hr", 0)).version, 1);
  rejects(await save("admin", 0), /changed/);
  assert.equal(
    ok(await save("admin", 1, { ...design, title: "Pay Advice" })).version,
    2,
  );
  const saved = (await list("employee", { design: true, first: 1 })).design;
  assert.equal(saved.version, 2);
  // Re-encoded server-side to a small PNG inside 480×160.
  assert.match(saved.design.logo, /^data:image\/png;base64,/);
  const meta = await sharp(
    Buffer.from(saved.design.logo.split(",")[1], "base64"),
  ).metadata();
  assert.ok(meta.width! <= 480 && meta.height! <= 160);
  const published = (await list("employee")).results.find(
    (r: any) => r.status === "published",
  );
  const slip = await f.app.inject({
    url: `/payroll/${published.id}/print?siteId=${ids.dg}`,
    headers: { authorization: `Bearer ${token.employee}` },
  });
  assert.equal(slip.statusCode, 200);
  assert.match(slip.body, /<h2>Pay Advice<\/h2>/);
  assert.match(slip.body, /Synthetic Garden Co &lt;b&gt;/);
  assert.match(slip.body, /class="modern"/);
  assert.match(
    slip.headers["content-security-policy"] as string,
    /img-src data:/,
  );
  // The design is per site: River Green still has the default.
  const other = await gql(
    "hr",
    "query($s:ID!,$i:JSON){payroll(siteId:$s,input:$i)}",
    { s: ids.rg, i: { design: true, first: 1 } },
  );
  assert.equal(other.data?.payroll?.design?.version ?? 0, 0);
});
test("payroll run suggests pay from attendance: rosters, check-ins, paid and unpaid leave", async () => {
  const q = (sql: string, params: unknown[]) => f.owner.query(sql, params);
  const shift = (
    await q(
      "SELECT id FROM app.site_reference_items WHERE site_id=$1 AND kind='shift' LIMIT 1",
      [ids.dg],
    )
  ).rows[0].id;
  // Synthetic June 2026 (Mon 1 – Sat 6 rostered, 09:00–18:00 IST).
  await q(
    `INSERT INTO app.shift_rosters(organization_id,site_id,employee_id,shift_id,work_date,starts_at,ends_at)
    SELECT $1,$2,$3,$4,d::date,(d::date+time '09:00') AT TIME ZONE 'Asia/Kolkata',(d::date+time '18:00') AT TIME ZONE 'Asia/Kolkata'
    FROM generate_series('2026-06-01'::date,'2026-06-06'::date,interval '1 day') d`,
    [ids.org, ids.dg, ids.employeeProfile, shift],
  );
  const attend = (days: string[], status: string) =>
    q(
      `WITH s AS (INSERT INTO app.duty_sessions(organization_id,site_id,employee_id,user_id,device_id,policy_version,geofence_version,status,opened_at,closed_at)
      SELECT $1,$2,$3,$4,gen_random_uuid(),1,1,'closed',(d+time '09:30') AT TIME ZONE 'Asia/Kolkata',(d+time '18:00') AT TIME ZONE 'Asia/Kolkata' FROM unnest($5::date[]) d RETURNING id,opened_at),
      e AS (INSERT INTO app.duty_events(organization_id,site_id,employee_id,user_id,duty_id,client_event_id,device_id,sequence,kind,captured_at,payload_version,payload_hash,payload)
      SELECT $1,$2,$3,$4,s.id,gen_random_uuid(),gen_random_uuid(),1,'IN',s.opened_at,1,'synthetic','{}' FROM s RETURNING id,captured_at)
      INSERT INTO app.event_verifications(organization_id,site_id,employee_id,event_id,status,reason,effective_at) SELECT $1,$2,$3,e.id,$6,'synthetic',e.captured_at FROM e`,
      [ids.org, ids.dg, ids.employeeProfile, ids.employee, days, status],
    );
  await attend(["2026-06-01", "2026-06-02"], "accepted");
  await attend(["2026-06-03"], "pending_verification");
  const type = async (code: string) =>
    (
      await q(
        "INSERT INTO app.leave_types(organization_id,site_id,code,label,half_days,include_weekends,include_holidays,approver_id) VALUES($1,$2,$3,$3,true,false,false,$4) RETURNING id",
        [ids.org, ids.dg, code, ids.admin],
      )
    ).rows[0].id;
  const leave = (typeId: string, day: string, half: string) =>
    q(
      "INSERT INTO app.leave_requests(organization_id,site_id,employee_id,user_id,client_id,type_id,starts_on,ends_on,half,units,reason,status,approver_id) VALUES($1,$2,$3,$4,gen_random_uuid(),$5,$6,$6,$7,$8,'synthetic','approved',$9)",
      [
        ids.org,
        ids.dg,
        ids.employeeProfile,
        ids.employee,
        typeId,
        day,
        half,
        half === "full" ? 1 : 0.5,
        ids.admin,
      ],
    );
  await leave(await type("CL"), "2026-06-04", "am");
  await leave(await type("LOP"), "2026-06-05", "full");
  const run = ok(
    await cmd("hr", "run", {
      clientId: randomUUID(),
      periodStart: "2026-06-01",
      periodEnd: "2026-06-30",
      attendanceNote: "Synthetic attendance-based suggestion",
      reason,
    }),
  );
  const june = await find(
    "hr",
    run.created.find((x: any) => x.employmentId === employment).id,
  );
  // Absent: half of 4 Jun (paid half leave), 5 Jun (LOP), 6 Jun (no record).
  assert.deepEqual(june.snapshot.attendanceSummary, {
    basis: "roster",
    periodDays: 30,
    employedDays: 30,
    workingDays: 6,
    presentDays: 3,
    pendingDays: 1,
    paidLeaveDays: 0.5,
    unpaidLeaveDays: 1,
    absentDays: 2.5,
    payableDays: 27.5,
    prorated: true,
  });
  assert.equal(june.snapshot.netPaise, "2750000", "30,000 × 27.5 / 30");
  assert.equal(june.input.lines[0].numerator, 55);
  assert.equal(june.input.lines[0].denominator, 60);
  assert.match(
    june.snapshot.attendanceInterpretation,
    /Suggested from attendance/,
  );
});
test("a new salary ends the running one; own salary and duplicate dates are refused", async () => {
  const salary = (who: string, startsOn: string, paise: string) =>
    cmd(who, "structure", {
      clientId: randomUUID(),
      expectedVersion: 0,
      employmentId: adminEmployment,
      startsOn,
      endsOn: null,
      calculation: calculation(paise),
      reason,
    });
  rejects(await salary("hr", "2026-07-01", "4000000"), /own salary/);
  ok(await salary("admin", "2026-07-01", "4000000"));
  ok(await salary("admin", "2026-09-01", "4500000"));
  rejects(await salary("admin", "2026-09-01", "4600000"), /already starts/);
  ok(await salary("admin", "2026-08-01", "4200000"));
  const rows = (
    await f.owner.query(
      "SELECT starts_on::text s,ends_on::text e,components->>'netPaise' net FROM app.salary_structures WHERE employment_id=$1 ORDER BY starts_on",
      [adminEmployment],
    )
  ).rows;
  assert.deepEqual(rows, [
    { s: "2026-07-01", e: "2026-07-31", net: "4000000" },
    { s: "2026-08-01", e: "2026-08-31", net: "4200000" },
    { s: "2026-09-01", e: null, net: "4500000" },
  ]);
  // Only ends_on may move, and only earlier; amounts are fixed.
  await assert.rejects(
    f.owner.query(
      "UPDATE app.salary_structures SET components='{}' WHERE employment_id=$1",
      [adminEmployment],
    ),
    /CONFLICT/,
  );
  const listed = (await list("hr", { salaries: true })).salaries;
  assert.ok(
    listed.some((x: any) => x.employmentId === employment && x.current),
  );
});
test("role defaults: HR prepares and sends for approval, Admin gives the final approval", async () => {
  // Remove the per-person grants from before(): only role templates remain.
  await f.owner.query(
    "DELETE FROM app.access_overrides WHERE user_id=ANY($1) AND key LIKE 'payroll.%'",
    [[ids.admin, ids.siteAdmin]],
  );
  token.junior = (await f.login("junior@example.test")).token;
  const hr = await list("hr");
  assert.equal(hr.canCreate, true);
  assert.equal(hr.canApprove, false);
  assert.equal((await list("junior")).canView, false);
  const run = ok(
    await cmd("hr", "run", {
      clientId: randomUUID(),
      periodStart: "2026-10-01",
      periodEnd: "2026-10-31",
      attendanceNote: "Synthetic role default check",
      reason,
    }),
  );
  let r = await find(
    "hr",
    run.created.find((x: any) => x.employmentId === employment).id,
  );
  r = await step("hr", "validate", r);
  assert.equal(r.status, "validated");
  rejects(
    await cmd("hr", "approve", {
      clientId: randomUUID(),
      id: r.id,
      expectedVersion: r.version,
      reason,
    }),
    /permissions/,
  );
  r = await step("admin", "approve", r);
  assert.equal(r.status, "approved");
  r = await step("admin", "publish", r);
  assert.equal(r.status, "published");
});
