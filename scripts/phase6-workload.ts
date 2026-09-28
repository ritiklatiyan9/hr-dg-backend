// Disposable local synthetic workload. Never accepts a production URL.
import { fixture } from "../tests/integration/fixture.js";
import { ids } from "../packages/db/src/seed.js";
import { Analytics } from "../apps/api/src/analytics.js";
import { mkdir, writeFile } from "node:fs/promises";
import { cpus, totalmem, platform, arch } from "node:os";
import { performance } from "node:perf_hooks";
import { randomUUID } from "node:crypto";
const f = await fixture("performance"),
  service = new Analytics(f.runtime);
const report: any = {
  at: new Date().toISOString(),
  hardware: {
    cpu: cpus()[0]?.model,
    logicalCores: cpus().length,
    memoryGiB: Math.round(totalmem() / 2 ** 30),
    platform: platform(),
    arch: arch(),
    node: process.version,
  },
  environment:
    "Loopback Mac → Docker PostGIS linux/amd64; synthetic data; no remote region/network or provider latency",
  window: { from: "2025-09-01", to: "2026-08-31" },
  measurements: [],
  plans: {},
};
const c = await f.owner.connect();
try {
  await c.query("SET statement_timeout='120s'");
  await c.query(
    "CREATE TEMP TABLE perf_people AS SELECT i,md5('perf-user-'||i)::uuid uid,md5('perf-employee-'||i)::uuid eid,CASE WHEN i%2=0 THEN $1::uuid ELSE $2::uuid END site FROM generate_series(1,497) i",
    [ids.dg, ids.rg],
  );
  await c.query(
    "INSERT INTO auth.users(id,organization_id,email,password_hash) SELECT uid,$1,'perf-'||i||'@example.test',(SELECT password_hash FROM auth.users WHERE id=$2) FROM perf_people",
    [ids.org, ids.employee],
  );
  await c.query(
    "INSERT INTO app.organization_memberships SELECT $1,uid,true FROM perf_people ON CONFLICT DO NOTHING",
    [ids.org],
  );
  await c.query(
    "INSERT INTO app.site_memberships SELECT $1,site,uid,true FROM perf_people ON CONFLICT DO NOTHING",
    [ids.org],
  );
  await c.query(
    "INSERT INTO app.access_grants(organization_id,site_id,user_id,role) SELECT $1,site,uid,'employee' FROM perf_people",
    [ids.org],
  );
  await c.query(
    "INSERT INTO app.employees(id,organization_id,user_id,employee_code,display_name,work_email,department) SELECT eid,$1,uid,'PERF-'||i,'Synthetic employee '||i,'perf-'||i||'@example.test',CASE WHEN i%3=0 THEN 'Field' ELSE 'Office' END FROM perf_people",
    [ids.org],
  );
  await c.query(
    "INSERT INTO app.site_assignments(organization_id,site_id,employee_id,starts_on) SELECT $1,site,eid,'2025-01-01' FROM perf_people",
    [ids.org],
  );
  await c.query(
    "INSERT INTO app.employment_records(organization_id,employee_id,legal_employer_id,starts_on) SELECT $1,eid,$2,'2025-01-01' FROM perf_people",
    [ids.org, ids.employer],
  );
  await c.query(
    "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) SELECT $1,s.id,$2,k,'allow','site' FROM app.sites s CROSS JOIN unnest(ARRAY['analytics.view','reports.view','expenses.view','documents.view','documents.field.bank','documents.field.identity']) k WHERE s.organization_id=$1 ON CONFLICT(organization_id,site_id,user_id,key) DO UPDATE SET effect='allow',scope='site'",
    [ids.org, ids.admin],
  );
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
  await c.query(
    "INSERT INTO app.operation_policies(organization_id,site_id,version,rules,reason) SELECT $1,id,1,$2,'SYNTHETIC PERFORMANCE POLICY' FROM app.sites WHERE organization_id=$1",
    [ids.org, rules],
  );
  await c.query(
    "INSERT INTO app.geofence_versions(organization_id,site_id,version,boundary,label,reason) SELECT $1,id,1,ST_GeogFromText('POLYGON((77.19 28.59,77.21 28.59,77.21 28.61,77.19 28.61,77.19 28.59))'),'SYNTHETIC','SYNTHETIC PERFORMANCE ONLY' FROM app.sites WHERE organization_id=$1",
    [ids.org],
  );
  await c.query(
    "INSERT INTO app.dwr_settings(organization_id,site_id,deadline,deadline_day_offset,reminder_minutes,amendments,reason) SELECT $1,id,'18:00',0,30,true,'SYNTHETIC PERFORMANCE ONLY' FROM app.sites WHERE organization_id=$1",
    [ids.org],
  );
  await c.query(
    "CREATE TEMP TABLE perf_days AS SELECT p.*,d::date dt,md5(eid::text||d::date::text)::uuid duty FROM perf_people p CROSS JOIN generate_series('2025-09-01'::date,'2026-08-31'::date,interval '1 day') d WHERE extract(isodow FROM d)<6",
  );
  await c.query(
    "INSERT INTO app.duty_sessions(id,organization_id,site_id,employee_id,user_id,device_id,policy_version,geofence_version,status,opened_at,closed_at,last_sequence) SELECT duty,$1,site,eid,uid,uid,1,1,'closed',(dt+time '09:00') AT TIME ZONE 'Asia/Kolkata',(dt+time '17:00') AT TIME ZONE 'Asia/Kolkata',3 FROM perf_days",
    [ids.org],
  );
  await c.query(
    "INSERT INTO app.shift_rosters(organization_id,site_id,employee_id,shift_id,work_date,starts_at,ends_at) SELECT $1,site,eid,site,dt,(dt+time '09:00') AT TIME ZONE 'Asia/Kolkata',(dt+time '17:00') AT TIME ZONE 'Asia/Kolkata' FROM perf_days",
    [ids.org],
  );
  await c.query(
    "INSERT INTO app.duty_events(id,organization_id,site_id,employee_id,user_id,duty_id,client_event_id,device_id,sequence,kind,captured_at,received_at,payload_version,payload_hash,payload) SELECT md5(duty::text||n)::uuid,$1,site,eid,uid,duty,md5(duty::text||n)::uuid,uid,n,CASE n WHEN 1 THEN 'IN' WHEN 2 THEN 'LOCATION' ELSE 'OUT' END,(dt+time '09:00'+(n-1)*interval '4 hours') AT TIME ZONE 'Asia/Kolkata',(dt+time '09:00'+(n-1)*interval '4 hours') AT TIME ZONE 'Asia/Kolkata',1,'SYNTHETIC','{}' FROM perf_days CROSS JOIN generate_series(1,3)n",
    [ids.org],
  );
  await c.query(
    "INSERT INTO app.event_verifications(organization_id,site_id,employee_id,event_id,status,reason,effective_at) SELECT organization_id,site_id,employee_id,id,'accepted','SYNTHETIC WORKLOAD',captured_at FROM app.duty_events",
  );
  await c.query(
    "INSERT INTO app.geofence_observations(organization_id,site_id,employee_id,event_id,geofence_version,point,accuracy_m,observed_at,classification,reason) SELECT organization_id,site_id,employee_id,id,1,ST_SetSRID(ST_MakePoint(77.2,28.6),4326)::geography,20,captured_at,CASE WHEN sequence=2 THEN 'unknown' ELSE 'inside' END,'SYNTHETIC' FROM app.duty_events",
  );
  await c.query(
    "INSERT INTO app.duty_segments(organization_id,site_id,employee_id,duty_id,revision,engine_version,starts_at,ends_at,kind,source_ids,assumption) SELECT $1,site,eid,duty,1,1,(dt+time '09:00'+n*interval '2 hours') AT TIME ZONE 'Asia/Kolkata',(dt+time '11:00'+n*interval '2 hours') AT TIME ZONE 'Asia/Kolkata',CASE n WHEN 0 THEN 'office' WHEN 1 THEN 'field' WHEN 2 THEN 'break' ELSE 'unknown' END,'[]','SYNTHETIC evidence only' FROM perf_days CROSS JOIN generate_series(0,3)n",
    [ids.org],
  );
  await c.query(
    "INSERT INTO app.dwr_reports(organization_id,site_id,employee_id,user_id,work_date,status,content,submitted_at) SELECT $1,site,eid,uid,dt,CASE WHEN i%5=0 THEN 'submitted' ELSE 'approved' END,'{}',(dt+time '17:30') AT TIME ZONE 'Asia/Kolkata' FROM perf_days WHERE extract(day FROM dt)::int%10<>0",
    [ids.org],
  );
  await c.query(
    "INSERT INTO app.work_tasks(organization_id,site_id,employee_id,assignee_id,author_id,client_id,title,deadline,priority,status) SELECT $1,site,eid,uid,$2,gen_random_uuid(),'Synthetic task',('2026-08-01'::date+n)::timestamp AT TIME ZONE 'Asia/Kolkata','normal',CASE WHEN n%3=0 THEN 'done' ELSE 'todo' END FROM perf_people CROSS JOIN generate_series(1,12)n",
    [ids.org, ids.admin],
  );
  await c.query(
    "INSERT INTO app.hr_records(organization_id,site_id,kind,employee_id,user_id,created_by,status,payload) SELECT $1,site,'expense',eid,uid,uid,'submitted',jsonb_build_object('amountPaise','12500','date','2026-08-15','category','Synthetic','description','Synthetic fixture') FROM perf_people",
    [ids.org],
  );
  await c.query("ANALYZE");
  report.volume = {};
  for (const table of [
    "employees",
    "duty_sessions",
    "duty_events",
    "geofence_observations",
    "duty_segments",
    "shift_rosters",
    "dwr_reports",
    "work_tasks",
    "hr_records",
  ])
    report.volume[table] = (
      await c.query(
        `SELECT count(*)::int n FROM app.${table} WHERE organization_id=$1`,
        [ids.org],
      )
    ).rows[0].n;
  console.log("Synthetic year populated", report.volume);
  const { actor } = await f.login("hr@example.test"),
    employee = await f.login("employee@example.test");
  async function measure(
    name: string,
    fn: () => Promise<unknown>,
    runs = 12,
    concurrency = 1,
  ) {
    const values: number[] = [];
    let errors = 0;
    const codes: string[] = [];
    for (let i = 0; i < runs; i += concurrency)
      await Promise.all(
        Array.from({ length: Math.min(concurrency, runs - i) }, async () => {
          const at = performance.now();
          try {
            await fn();
            values.push(performance.now() - at);
          } catch (e) {
            errors++;
            codes.push((e as any).code ?? (e as Error).message);
          }
        }),
      );
    values.sort((a, b) => a - b);
    report.measurements.push({
      name,
      runs,
      concurrency,
      successful: values.length,
      errors,
      codes: [...new Set(codes)],
      p50Ms: values[Math.floor(values.length * 0.5)] ?? null,
      p95Ms:
        values[
          Math.min(values.length - 1, Math.ceil(values.length * 0.95) - 1)
        ] ?? null,
      condition:
        "Warm DB after synthetic import; service transaction includes permission checks; excludes TLS/internet and login",
    });
    console.log(name, report.measurements.at(-1));
  }
  const input = { from: "2026-08-01", to: "2026-08-31", siteIds: [ids.dg] };
  await measure("directory_20", () => service.list(actor, ids.dg, 20), 12, 2);
  await measure(
    "task_backlog",
    () => service.analyticsSnapshot(actor, ids.dg, input, "getTaskBacklog"),
    12,
    2,
  );
  await measure(
    "attendance_month",
    () =>
      service.analyticsSnapshot(actor, ids.dg, input, "getAttendanceSummary"),
    2,
    1,
  );
  await measure(
    "dwr_compliance",
    () => service.analyticsSnapshot(actor, ids.dg, input, "getDwrCompliance"),
    2,
    1,
  );
  await measure(
    "hr_expenses",
    () => service.hrSnapshot(actor, ids.dg, "expense"),
    6,
    2,
  );
  await measure(
    "dashboard",
    () => service.analyticsSnapshot(actor, ids.dg, input),
    2,
    1,
  );
  await measure(
    "small_task_write",
    () =>
      service.command(actor, ids.dg, "task", {
        clientId: randomUUID(),
        employeeId: ids.employeeProfile,
        title: "Synthetic timed task",
        description: "Synthetic timing",
        deadline: "2026-09-30T12:00:00Z",
        priority: "normal",
      }),
    12,
    2,
  );
  const job = await service.queueExport(actor, ids.dg, [
    "employeeCode",
    "displayName",
  ]);
  await c.query("SELECT app.prepare_exports()");
  await measure(
    "employee_export",
    () => service.download(actor, ids.dg, job.id),
    4,
    1,
  );
  const photo = randomUUID(),
    duty = randomUUID();
  await c.query(
    "INSERT INTO app.private_files(id,organization_id,site_id,employee_id,owner_id,client_id,purpose,declared_type,byte_limit,object_key,status) VALUES($1,$2,$3,$4,$5,$1,'attendance','image/jpeg',1,'synthetic/benchmark-no-object','ready')",
    [photo, ids.org, ids.dg, ids.employeeProfile, ids.employee],
  );
  const event = (kind: string, sequence: number) => ({
    clientEventId: randomUUID(),
    dutyId: duty,
    sequence,
    kind,
    capturedAt: new Date().toISOString(),
    payloadVersion: 1,
    policyVersion: 1,
    geofenceVersion: 1,
    ...(kind === "IN" ? { photoId: photo } : {}),
    location: {
      latitude: 28.6,
      longitude: 77.2,
      accuracyM: 10,
      observedAt: new Date().toISOString(),
      mocked: false,
    },
  });
  await service.command(employee.actor, ids.dg, "event", event("IN", 1));
  let seq = 1;
  await measure(
    "field_location_ingestion",
    () =>
      service.command(
        employee.actor,
        ids.dg,
        "event",
        event("LOCATION", ++seq),
      ),
    12,
    1,
  );
  await service
    .site(actor, ids.dg, async (tx) => {
      report.plans.attendance = (
        await tx.query(
          "EXPLAIN (ANALYZE,BUFFERS,FORMAT JSON) SELECT app.analytics_attendance($1::date,$2::date)",
          [input.from, input.to],
        )
      ).rows;
    })
    .catch((e) => (report.plans.error = (e as any).code ?? "timeout"));
  report.plans.candidateWindowOwnerInspection = (
    await c.query(
      "EXPLAIN (ANALYZE,BUFFERS,FORMAT JSON) SELECT DISTINCT duty_id FROM app.duty_segments WHERE organization_id=$1 AND site_id=$2 AND ends_at>'2026-08-01T00:00:00+05:30' AND starts_at<'2026-09-01T00:00:00+05:30'",
      [ids.org, ids.dg],
    )
  ).rows;
} catch (e) {
  report.failure = {
    code: (e as any).code ?? "ERROR",
    message: (e as Error).message,
  };
  console.log("Workload stopped", report.failure);
  process.exitCode = 1;
} finally {
  await mkdir("docs/evidence/phase6", { recursive: true });
  const label = process.env.PERF_LABEL ?? "baseline";
  if (!/^[a-z0-9-]+$/.test(label)) throw Error("Invalid label");
  await writeFile(
    `docs/evidence/phase6/performance-${label}.json`,
    JSON.stringify(report, null, 2),
  );
  c.release();
  await f.close();
}
