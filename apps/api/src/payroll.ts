import { readJson } from "../../../packages/db/src/read-json.js";
import { createHash } from "node:crypto";
import { isDeepStrictEqual } from "node:util";
import { z } from "zod";
import { Dwr } from "./dwr.js";
import { fail, type Actor } from "../../../packages/authz/src/index.js";
import type { Tx } from "../../../packages/db/src/index.js";
import {
  calculatePayroll,
  calculationInput,
  importPayrollCsv,
  paise,
  money,
  csvCell,
  paymentMethods,
} from "../../../packages/contracts/payroll.js";
import sharp from "sharp";
import {
  defaultPayslipDesign,
  payslipDesign,
  renderPayslipHtml,
} from "../../../packages/contracts/payslip.js";
const base = { clientId: z.uuid(), expectedVersion: z.number().int().min(0) };
const reason = z.string().trim().min(8).max(2000);
const allocations = z
  .array(z.object({ siteId: z.uuid(), paise }).strict())
  .min(1)
  .max(20);
const save = z
  .object({
    ...base,
    id: z.uuid().optional(),
    employmentId: z.uuid(),
    periodStart: z.iso.date(),
    periodEnd: z.iso.date(),
    calculation: calculationInput,
    allocations,
    attendanceNote: reason,
    reason,
    previousId: z.uuid().nullable().default(null),
    csv: z.string().max(32000).optional(),
  })
  .strict();
const structure = z
  .object({
    ...base,
    employmentId: z.uuid(),
    startsOn: z.iso.date(),
    // Null: in force until the next salary change or the employment end.
    endsOn: z.iso.date().nullable().default(null),
    calculation: calculationInput,
    reason,
  })
  .strict();
// One result, or up to 100 moved atomically under one reason.
const transition = z.union([
  z.object({ ...base, id: z.uuid(), reason }).strict(),
  z
    .object({
      clientId: z.uuid(),
      items: z
        .array(
          z
            .object({ id: z.uuid(), expectedVersion: base.expectedVersion })
            .strict(),
        )
        .min(1)
        .max(100),
      reason,
    })
    .strict(),
]);
const pay = z
  .object({
    clientId: z.uuid(),
    items: z
      .array(
        z
          .object({ id: z.uuid(), paise: paise.refine((v) => v !== "0") })
          .strict(),
      )
      .min(1)
      .max(100),
    method: z.enum(paymentMethods),
    reference: z
      .string()
      .trim()
      .regex(/^[A-Za-z0-9][A-Za-z0-9 /._-]{0,63}$/),
    paidOn: z.iso.date(),
    reason,
  })
  .strict();
const reverse = z
  .object({ clientId: z.uuid(), paymentId: z.uuid(), reason })
  .strict();
const run = z
  .object({
    clientId: z.uuid(),
    periodStart: z.iso.date(),
    periodEnd: z.iso.date(),
    attendanceNote: reason,
    reason,
  })
  .strict();
const filters = z
  .object({
    status: z
      .enum(["draft", "validated", "reviewed", "approved", "published"])
      .optional(),
    payment: z.enum(["due", "paid"]).optional(),
    from: z.iso.date().optional(),
    to: z.iso.date().optional(),
    search: z.string().trim().max(100).optional(),
    employmentId: z.uuid().optional(),
  })
  .strict();
const listing = filters
  .extend({
    first: z.number().int().min(1).max(100).default(100),
    after: z.string().max(1000).optional(),
    summary: z.boolean().default(false),
    employments: z.boolean().default(false),
    salaries: z.boolean().default(false),
    design: z.boolean().default(false),
  })
  .strict();
// Uploaded logos may be PNG/JPEG/WebP; the server re-encodes them to a small PNG.
const design = z
  .object({
    clientId: z.uuid(),
    expectedVersion: z.number().int().min(0),
    design: payslipDesign.extend({
      logo: z
        .string()
        .max(60000)
        .regex(/^data:image\/(png|jpeg|webp);base64,[A-Za-z0-9+/]+={0,2}$/)
        .nullable(),
    }),
  })
  .strict();
const commands: Record<string, z.ZodType> = {
  save,
  structure,
  validate: transition,
  review: transition,
  approve: transition,
  publish: transition,
  return: transition,
  pay,
  reverse_payment: reverse,
  run,
  design,
};
const permissions: Record<string, string> = {
  structure: "edit",
  publish: "manage",
  pay: "manage",
  reverse_payment: "manage",
  run: "create",
  design: "manage",
  validate: "edit",
  return: "edit",
  review: "review",
  approve: "approve",
};
const stages: Record<string, [string, string]> = {
  validate: ["draft", "validated"],
  review: ["validated", "reviewed"],
  approve: ["reviewed", "approved"],
  publish: ["approved", "published"],
};
// Drafts created per run call; the rest are reported and picked up by rerunning.
const RUN_LIMIT = 100;
// Chain balance (every revision of one employment+period) and replacement state.
const METRICS = `CROSS JOIN LATERAL (SELECT (r.snapshot->>'netPaise')::bigint AS net,
 COALESCE((SELECT sum(CASE x.kind WHEN 'payment' THEN x.amount_paise ELSE -x.amount_paise END) FROM app.payroll_payments x
  WHERE x.organization_id=r.organization_id AND x.employment_id=r.employment_id AND x.period_start=r.period_start AND x.period_end=r.period_end),0)::bigint AS paid,
 EXISTS(SELECT 1 FROM app.payroll_results s WHERE s.previous_id=r.id AND s.status='published') AS superseded,
 r.status IN ('approved','published') AND NOT EXISTS(SELECT 1 FROM app.payroll_results s WHERE s.previous_id=r.id AND s.status IN ('approved','published')) AS payable) m`;
// $1 status, $2 from, $3 to, $4 search pattern, $5 employment, $6 payment state.
const FILTER = `($1::text IS NULL OR r.status=$1) AND ($2::date IS NULL OR r.period_start>=$2::date) AND ($3::date IS NULL OR r.period_start<=$3::date)
 AND ($4::text IS NULL OR r.snapshot->>'employeeName' ILIKE $4 OR r.snapshot->>'employeeCode' ILIKE $4) AND ($5::uuid IS NULL OR r.employment_id=$5::uuid)
 AND ($6::text IS NULL OR (m.payable AND ($6='due')=(m.paid<m.net)))`;
const filterParams = (q: z.infer<typeof filters>) => [
  q.status ?? null,
  q.from ?? null,
  q.to ?? null,
  q.search ? `%${q.search.replace(/[\\%_]/g, "\\$&")}%` : null,
  q.employmentId ?? null,
  q.payment ?? null,
];
const PEOPLE = (table: string, column: string) =>
  `LEFT JOIN app.employees e ON e.organization_id=${table}.organization_id AND e.user_id=${table}.${column}`;
export type AttendanceSummary = {
  basis: "roster" | "weekdays" | "no_attendance" | "not_visible";
  periodDays: number;
  employedDays: number;
  workingDays: number | null;
  presentDays: number | null;
  pendingDays: number | null;
  paidLeaveDays: number | null;
  unpaidLeaveDays: number | null;
  absentDays: number;
  payableDays: number;
  prorated: boolean;
};
/** Earnings scale by payable/period days (half-day exact); deductions,
 *  overtime, bonuses and reimbursements keep the salary's own amounts. */
export function prorate(
  line: { kind: string; numerator?: number; denominator?: number },
  s: Pick<AttendanceSummary, "payableDays" | "periodDays">,
) {
  if (line.kind !== "earning" || s.payableDays === s.periodDays) return line;
  const numerator = (line.numerator ?? 1) * Math.round(s.payableDays * 2),
    denominator = (line.denominator ?? 1) * s.periodDays * 2;
  if (denominator > 100000) throw Error("Salary ratio too fine to prorate");
  return { ...line, numerator, denominator };
}
export class Payroll extends Dwr {
  async payrollAccess(c: Tx, permission: string, employee?: string) {
    if (
      !(
        await c.query("SELECT app.payroll_admin($1,$2) ok", [
          permission,
          employee ?? null,
        ])
      ).rows[0].ok
    )
      fail(
        "FORBIDDEN",
        "Site payroll and salary-field permissions are required",
        403,
      );
  }
  async hrReceipt(
    c: Tx,
    actor: Actor,
    site: string,
    operation: string,
    p: any,
    authorize: () => Promise<void>,
    fn: () => Promise<any>,
  ) {
    await authorize();
    await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
      `${actor.organizationId}:${actor.id}:hr:${p.clientId}`,
    ]);
    const digest = createHash("sha256")
      .update(JSON.stringify({ site, operation, p }))
      .digest("hex");
    const prior = (
      await c.query(
        "SELECT digest,result FROM app.hr_receipts WHERE client_id=$1",
        [p.clientId],
      )
    ).rows[0];
    if (prior) {
      if (prior.digest !== digest)
        fail("CONFLICT", "Request ID already used with different content", 409);
      return prior.result;
    }
    const result = await fn();
    // Receipts retain IDs/version/status only, never salary or confidential content.
    await c.query(
      "INSERT INTO app.hr_receipts VALUES(app.org_id(),app.site_id(),app.actor_id(),$1,$2,$3)",
      [p.clientId, digest, JSON.stringify(result)],
    );
    return result;
  }
  /** One page of results with history, payments and actions in a fixed number
   * of queries, independent of page size. */
  async payrollSnapshot(actor: Actor, site: string, raw: unknown = {}) {
    const q = listing.parse(raw ?? {});
    const binding = createHash("sha256")
      .update(
        JSON.stringify([
          site,
          actor.id,
          actor.permissionVersion,
          filterParams(q),
        ]),
      )
      .digest("base64url");
    let cursor: { p: string; id: string } | null = null;
    if (q.after) {
      try {
        const c = JSON.parse(Buffer.from(q.after, "base64url").toString());
        if (c.b !== binding) throw Error();
        cursor = { p: z.iso.date().parse(c.p), id: z.uuid().parse(c.id) };
      } catch {
        fail("BAD_CURSOR", "Invalid pagination cursor");
      }
    }
    return this.site(actor, site, async (c) => {
      const can = (
        await c.query(
          "SELECT app.payroll_admin('payroll.view') AS view,app.payroll_admin('payroll.create') AS create,app.payroll_admin('payroll.edit') AS edit,app.payroll_admin('payroll.review') AS review,app.payroll_admin('payroll.approve') AS approve,app.payroll_admin('payroll.manage') AS manage,app.payroll_admin('payroll.export') AS export,app.allowed('my_payroll.view') AND app.allowed('my_payroll.field.salary') AS own",
        )
      ).rows[0];
      if (!can.view && !can.own) fail("FORBIDDEN", "Payroll unavailable", 403);
      // Site-level grants equal per-employee ones here: a non-own row is only
      // visible through payroll.view, which already includes employees.view.
      const adminActions = [
        "edit",
        "review",
        "approve",
        "manage",
        "export",
      ].filter((a) => can[a]);
      const params = filterParams(q);
      const rows = (
        await c.query(
          `WITH page AS MATERIALIZED (
 SELECT r.id,r.organization_id,r.site_id,r.employment_id,r.employee_id,r.user_id,r.legal_employer_id,r.period_start,r.period_end,
  r.period_start::text AS "periodStart",r.period_end::text AS "periodEnd",r.revision,r.previous_id,r.status,r.version,r.input,
  r.snapshot-'{segments,attendance,structures,attendancePolicies}'::text[] AS snapshot,r.allocations,r.reason,r.created_by,
  r.reviewed_by,r.approved_by,r.published_at,r.created_at,r.updated_at,m.net,m.paid,m.superseded,m.payable
 FROM app.payroll_results r ${METRICS}
 WHERE ${FILTER} AND ($7::date IS NULL OR (r.period_start,r.id)<($7::date,$8::uuid))
 ORDER BY r.period_start DESC,r.id DESC LIMIT $9)
SELECT page.*,
 CASE WHEN page.user_id=app.actor_id() THEN app.payroll_own(page.employee_id,'my_payroll.export') END AS "ownExport",
 COALESCE((SELECT jsonb_agg(jsonb_build_object('version',h.version,'event',h.event,'reason',h.reason,'actor_id',h.actor_id,'actorName',e.display_name,'created_at',h.created_at) ORDER BY h.version)
  FROM app.payroll_history h ${PEOPLE("h", "actor_id")} WHERE h.result_id=page.id),'[]') AS history,
 COALESCE((SELECT jsonb_agg(jsonb_build_object('id',x.id,'resultId',x.result_id,'kind',x.kind,'paise',x.amount_paise::text,'method',x.method,'reference',x.reference,'paidOn',x.paid_on,'reversesId',x.reverses_id,'reason',x.reason,'actorId',x.created_by,'actorName',e.display_name,'createdAt',x.created_at) ORDER BY x.created_at)
  FROM app.payroll_payments x ${PEOPLE("x", "created_by")} WHERE x.organization_id=page.organization_id AND x.employment_id=page.employment_id AND x.period_start=page.period_start AND x.period_end=page.period_end),'[]') AS payments
FROM page ORDER BY page.period_start DESC,page.id DESC`,
          [...params, cursor?.p ?? null, cursor?.id ?? null, q.first + 1],
        )
      ).rows;
      const more = rows.length > q.first;
      const results = rows.slice(0, q.first).map((r) => {
        const { net, paid, ownExport, period_start, period_end, ...rest } = r;
        const isSelf = r.user_id === actor.id;
        return {
          ...rest,
          isSelf,
          actions: isSelf ? (ownExport ? ["export"] : []) : adminActions,
          paidPaise: String(paid),
          duePaise: r.payable ? String(BigInt(net) - BigInt(paid)) : null,
        };
      });
      const last = rows[q.first - 1];
      const summary = !q.summary
        ? null
        : (
            await c.query(
              `SELECT r.status,count(*)::int AS count,sum(m.net)::text AS "netPaise",COALESCE(sum(m.paid) FILTER (WHERE m.payable),0)::text AS "paidPaise",
 COALESCE(sum(GREATEST(m.net-m.paid,0)) FILTER (WHERE m.payable),0)::text AS "duePaise"
 FROM app.payroll_results r ${METRICS} WHERE ${FILTER} AND NOT m.superseded GROUP BY r.status`,
              params,
            )
          ).rows;
      // Editor choices: employments ever assigned to this site.
      const employments =
        can.create && q.employments
          ? (
              await c.query(
                'SELECT er.id,e.id AS "employeeId",e.display_name AS name,e.employee_code AS code,l.name AS "legalEmployer",er.starts_on::text AS "startsOn",er.ends_on::text AS "endsOn" FROM app.employment_records er JOIN app.employees e ON e.id=er.employee_id JOIN app.legal_employers l ON l.id=er.legal_employer_id WHERE EXISTS(SELECT 1 FROM app.site_assignments a WHERE a.site_id=app.site_id() AND a.employee_id=er.employee_id) ORDER BY e.display_name,er.starts_on DESC LIMIT 1000',
              )
            ).rows
          : [];
      return {
        results,
        summary,
        hasMore: more,
        endCursor: more
          ? Buffer.from(
              JSON.stringify({ p: last.periodStart, id: last.id, b: binding }),
            ).toString("base64url")
          : null,
        structures: (
          await c.query(
            'SELECT id,employment_id,employee_id,starts_on::text AS "startsOn",ends_on::text AS "endsOn",version,components,reason,created_at FROM app.salary_structures ORDER BY starts_on DESC LIMIT 100',
          )
        ).rows,
        employments,
        salaries: can.view && q.salaries ? await this.salaries(c) : undefined,
        design: q.design ? await this.payslipDesign(c) : undefined,
        canView: can.view,
        canCreate: can.create,
        canEdit: can.edit,
        canApprove: can.approve,
        canManage: can.manage,
        canExport: can.export,
        limit: q.first,
      };
    });
  }
  async payrollCommand(
    actor: Actor,
    site: string,
    operation: string,
    raw: unknown,
  ) {
    const schema = commands[operation];
    if (!schema) fail("BAD_INPUT", "Unknown payroll command");
    const p: any = schema.parse(raw);
    const items: { id: string; expectedVersion: number }[] | undefined =
      p.items;
    if (items && new Set(items.map((x) => x.id)).size !== items.length)
      fail("BAD_INPUT", "Each payroll result may appear once");
    const permission =
      operation === "save"
        ? p.id
          ? "edit"
          : "create"
        : permissions[operation];
    return this.site(actor, site, async (c) =>
      this.hrReceipt(
        c,
        actor,
        site,
        `payroll.${operation}`,
        p,
        () => this.payrollAccess(c, `payroll.${permission}`),
        async () => {
          if (operation === "structure")
            return this.payrollStructure(c, p, actor);
          if (operation === "save") {
            const r = await this.payrollSave(c, site, p, permission!);
            return { id: r.id, status: r.status, version: r.version };
          }
          if (operation === "run") return this.payrollRun(c, site, p);
          if (operation === "design") return this.saveDesign(c, site, p);
          if (operation === "pay") return this.payrollPay(c, actor, p);
          if (operation === "reverse_payment")
            return this.payrollReverse(c, actor, p);
          const out = await this.payrollTransitions(
            c,
            actor,
            operation,
            items ?? [p],
            p.reason,
            !!items,
          );
          return items ? { results: out } : out[0];
        },
      ),
    );
  }
  async payrollStructure(c: Tx, p: any, actor: Actor) {
    const e = await this.payEmployment(c, p.employmentId);
    await this.payrollAccess(c, "payroll.edit", e.employee_id);
    if (e.user_id === actor.id)
      fail("FORBIDDEN", "Your own salary is set by another payroll user", 403);
    if (
      p.expectedVersion !== 0 ||
      p.startsOn < e.starts_on ||
      (e.ends_on && p.startsOn > e.ends_on) ||
      (p.endsOn &&
        (p.endsOn < p.startsOn || (e.ends_on && p.endsOn > e.ends_on)))
    )
      fail("BAD_INPUT", "Salary dates must fall within the employment");
    // One salary change at a time per employment.
    await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,736))", [
      e.id,
    ]);
    const around = (
      await c.query(
        `SELECT EXISTS(SELECT 1 FROM app.salary_structures WHERE employment_id=$1 AND starts_on=$2::date) same,
        (SELECT (min(starts_on)-1)::text FROM app.salary_structures WHERE employment_id=$1 AND starts_on>$2::date) before_next`,
        [e.id, p.startsOn],
      )
    ).rows[0];
    if (around.same)
      fail(
        "CONFLICT",
        "A salary already starts on this date. Choose another effective date.",
        409,
      );
    // Ends before a later saved salary, else at the requested or employment end.
    const ends = [p.endsOn ?? e.ends_on, around.before_next]
      .filter(Boolean)
      .sort()[0] as string | undefined;
    // The running salary ends the day before; its amounts never change.
    const closed = (
      await c.query(
        "UPDATE app.salary_structures SET ends_on=$2::date-1 WHERE employment_id=$1 AND starts_on<$2::date AND COALESCE(ends_on,'infinity')>=$2::date RETURNING id",
        [e.id, p.startsOn],
      )
    ).rows;
    const calc = this.calculate(p.calculation);
    const r = (
      await c.query(
        'INSERT INTO app.salary_structures(organization_id,site_id,employment_id,employee_id,starts_on,ends_on,components,reason,created_by) VALUES(app.org_id(),app.site_id(),$1,$2,$3,$4,$5,$6,app.actor_id()) RETURNING id,version,starts_on::text AS "startsOn",ends_on::text AS "endsOn"',
        [e.id, e.employee_id, p.startsOn, ends ?? null, calc, p.reason],
      )
    ).rows[0];
    await this.auditOperation(c, "salary.structure", r.id, [
      "effectiveDates",
      "components",
      ...(closed.length ? ["previousEnded"] : []),
    ]);
    return { ...r, closed: closed.map((x) => x.id) };
  }
  /** Salaries page: every employment at this site with its latest salary
   *  (current or ended) and the next scheduled change. */
  async salaries(c: Tx) {
    return (
      await c.query(
        `WITH today AS (SELECT (now() AT TIME ZONE timezone)::date d FROM app.sites WHERE id=app.site_id())
SELECT er.id AS "employmentId",e.id AS "employeeId",e.display_name AS name,e.employee_code AS code,e.job_title AS "jobTitle",
 l.name AS "legalEmployer",er.starts_on::text AS "startsOn",er.ends_on::text AS "endsOn",e.user_id IS NOT NULL AS "hasAccount",e.user_id=app.actor_id() AS "isSelf",
 (SELECT jsonb_build_object('id',s.id,'startsOn',s.starts_on::text,'endsOn',s.ends_on::text,'components',s.components,'reason',s.reason,'createdAt',s.created_at)
  FROM app.salary_structures s WHERE s.employment_id=er.id AND s.starts_on<=(SELECT d FROM today) ORDER BY s.starts_on DESC LIMIT 1) AS current,
 (SELECT jsonb_build_object('id',s.id,'startsOn',s.starts_on::text,'endsOn',s.ends_on::text,'components',s.components)
  FROM app.salary_structures s WHERE s.employment_id=er.id AND s.starts_on>(SELECT d FROM today) ORDER BY s.starts_on LIMIT 1) AS upcoming
FROM app.employment_records er JOIN app.employees e ON e.id=er.employee_id JOIN app.legal_employers l ON l.id=er.legal_employer_id
WHERE (er.ends_on IS NULL OR er.ends_on>=(SELECT d FROM today)-62) AND app.allowed('employees.view',er.employee_id)
 AND EXISTS(SELECT 1 FROM app.site_assignments a WHERE a.site_id=app.site_id() AND a.employee_id=er.employee_id AND (a.ends_on IS NULL OR a.ends_on>=(SELECT d FROM today)-62))
ORDER BY e.display_name,er.starts_on DESC LIMIT 500`,
      )
    ).rows;
  }
  async payrollSave(
    c: Tx,
    site: string,
    p: any,
    permission: string,
    event = "save",
  ) {
    let r: any = p.id
      ? (
          await c.query(
            "SELECT *,period_start::text AS period_start,period_end::text AS period_end FROM app.payroll_results WHERE id=$1 FOR UPDATE",
            [p.id],
          )
        ).rows[0]
      : null;
    if (p.id && !r) fail("NOT_FOUND", "Payroll result unavailable", 404);
    if ((r?.version ?? 0) !== p.expectedVersion)
      fail("CONFLICT", "Payroll changed; reload before continuing", 409);
    if (r && r.status !== "draft")
      fail("CONFLICT", "Return this result to draft before editing", 409);
    const e = await this.payEmployment(c, p.employmentId);
    await this.payrollAccess(c, `payroll.${permission}`, e.employee_id);
    if (
      r &&
      (r.employment_id !== e.id ||
        String(r.period_start).slice(0, 10) !== p.periodStart ||
        String(r.period_end).slice(0, 10) !== p.periodEnd ||
        r.previous_id !== p.previousId)
    )
      fail("CONFLICT", "Employment, period and revision are fixed");
    if (p.periodEnd < p.periodStart)
      fail("BAD_INPUT", "Pay period end precedes start");
    if (p.csv) {
      try {
        p.calculation.lines = importPayrollCsv(p.csv);
      } catch {
        fail(
          "BAD_INPUT",
          "CSV rejected. Check header, integer paise and every row.",
        );
      }
    }
    const calc = this.calculate(p.calculation);
    if (
      new Set(p.allocations.map((a: any) => a.siteId)).size !==
        p.allocations.length ||
      p.allocations.reduce((n: bigint, a: any) => n + BigInt(a.paise), 0n) !==
        BigInt(calc.netPaise)
    )
      fail(
        "BAD_INPUT",
        "Site allocations must uniquely reconcile to net paise",
      );
    if (
      !(
        await c.query(
          "SELECT NOT EXISTS(SELECT 1 FROM unnest($1::uuid[]) site WHERE app.payroll_allocation(site,$2,$3,$4) IS NOT TRUE) ok",
          [
            p.allocations.map((a: any) => a.siteId),
            e.employee_id,
            p.periodStart,
            p.periodEnd,
          ],
        )
      ).rows[0].ok
    )
      fail(
        "FORBIDDEN",
        "Allocation needs an authorized historical site assignment",
        403,
      );
    const data = await readJson(c, {
      structures: [
        "SELECT id,version,components,starts_on::text,ends_on::text FROM app.salary_structures WHERE employment_id=$1 AND starts_on<=$3::date AND COALESCE(ends_on,'infinity')>=$2::date",
        [e.id, p.periodStart, p.periodEnd],
      ],
      attendance: [
        "SELECT id,kind,starts_at,ends_at,reason,status FROM app.attendance_adjustments WHERE employee_id=$1 AND status='approved' AND starts_at<(($3::date+1)::timestamp AT TIME ZONE (SELECT timezone FROM app.sites WHERE id=app.site_id())) AND ends_at>=($2::date::timestamp AT TIME ZONE (SELECT timezone FROM app.sites WHERE id=app.site_id()))",
        [e.employee_id, p.periodStart, p.periodEnd],
      ],
      attendancePolicies: [
        "SELECT id,version,created_at FROM app.operation_policies ORDER BY version",
      ],
      segments: [
        "SELECT s.id,s.duty_id,s.revision,s.engine_version,s.starts_at,s.ends_at,s.kind,s.assumption FROM app.duty_segments s WHERE s.employee_id=$1 AND s.revision=(SELECT max(t.revision) FROM app.duty_segments t WHERE t.duty_id=s.duty_id) AND s.starts_at<(($3::date+1)::timestamp AT TIME ZONE (SELECT timezone FROM app.sites WHERE id=app.site_id())) AND s.ends_at>=($2::date::timestamp AT TIME ZONE (SELECT timezone FROM app.sites WHERE id=app.site_id())) LIMIT 2001",
        [e.employee_id, p.periodStart, p.periodEnd],
      ],
      attendanceVisible: [
        "SELECT app.allowed('attendance.view',$1) OR app.allowed('my_attendance.view',$1) ok",
        [e.employee_id],
      ],
    });
    const structures = data.structures;
    const attendance = data.attendance;
    const attendancePolicies = data.attendancePolicies;
    const segments = data.segments;
    if (segments.length > 2000)
      fail(
        "BAD_INPUT",
        "Attendance snapshot exceeds 2,000 segments; use a shorter pay period",
      );
    const attendanceVisible = data.attendanceVisible[0].ok;
    const snapshot = {
      ...calc,
      employeeName: e.display_name,
      employeeCode: e.employee_code,
      legalEmployer: e.legal_employer,
      employmentStarts: e.starts_on,
      employmentEnds: e.ends_on,
      structures,
      attendance,
      attendancePolicies,
      segments,
      attendanceVisible,
      attendanceScope: site,
      attendanceNote: p.attendanceNote,
      attendanceSummary:
        p.attendanceSummary ?? r?.snapshot?.attendanceSummary ?? null,
      attendanceInterpretation: (
        p.attendanceSummary ?? r?.snapshot?.attendanceSummary
      )?.prorated
        ? "Suggested from attendance: earnings prorated by payable days, reviewed by HR and approved; unknown GPS is not unpaid time."
        : "Manual accountant-reviewed inputs; unknown GPS is not unpaid time.",
      capturedAt: new Date().toISOString(),
    };
    let revision = 1;
    if (p.previousId) {
      const prev = (
        await c.query(
          "SELECT revision,status FROM app.payroll_results WHERE id=$1",
          [p.previousId],
        )
      ).rows[0];
      if (!prev || prev.status !== "published")
        fail("CONFLICT", "Revision requires a published predecessor");
      revision = prev.revision + 1;
    }
    if (r)
      r = (
        await c.query(
          "UPDATE app.payroll_results SET input=$2,snapshot=$3,allocations=$4,reason=$5,version=version+1,updated_at=now() WHERE id=$1 RETURNING *",
          [
            r.id,
            p.calculation,
            snapshot,
            JSON.stringify(p.allocations),
            p.reason,
          ],
        )
      ).rows[0];
    else
      r = (
        await c.query(
          "INSERT INTO app.payroll_results(organization_id,site_id,employment_id,employee_id,user_id,legal_employer_id,period_start,period_end,revision,previous_id,input,snapshot,allocations,reason,created_by) VALUES(app.org_id(),app.site_id(),$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,app.actor_id()) RETURNING *",
          [
            e.id,
            e.employee_id,
            e.user_id,
            e.legal_employer_id,
            p.periodStart,
            p.periodEnd,
            revision,
            p.previousId,
            p.calculation,
            snapshot,
            JSON.stringify(p.allocations),
            p.reason,
          ],
        )
      ).rows[0];
    await this.payrollRecord(c, r, event, p.reason);
    return r;
  }
  async payrollTransitions(
    c: Tx,
    actor: Actor,
    operation: string,
    items: { id: string; expectedVersion: number }[],
    reason: string,
    bulk: boolean,
  ) {
    const ids = items.map((it) => it.id);
    const rows = (
      await c.query(
        "SELECT *,app.payroll_admin($2,employee_id) AS allowed FROM app.payroll_results WHERE id=ANY($1::uuid[]) ORDER BY id FOR UPDATE",
        [ids, `payroll.${permissions[operation]}`],
      )
    ).rows;
    const byId = new Map(rows.map((r) => [r.id, r]));
    for (const [i, it] of items.entries()) {
      const r = byId.get(it.id);
      try {
        if (!r) fail("NOT_FOUND", "Payroll result unavailable", 404);
        if (r.version !== it.expectedVersion)
          fail("CONFLICT", "Payroll changed; reload before continuing", 409);
        if (!r.allowed)
          fail(
            "FORBIDDEN",
            "Site payroll and salary-field permissions are required",
            403,
          );
        if (operation === "return") {
          if (!["validated", "reviewed"].includes(r.status))
            fail("CONFLICT", "Only pending review may return to draft");
        } else if (
          r.status !== stages[operation]![0] &&
          !(operation === "approve" && r.status === "validated")
        )
          fail("CONFLICT", "Payroll stage changed", 409);
        if (
          ["review", "approve"].includes(operation) &&
          (r.user_id === actor.id ||
            r.created_by === actor.id ||
            (operation === "approve" && r.reviewed_by === actor.id))
        )
          fail(
            "FORBIDDEN",
            "Creator, reviewer, approver and beneficiary separation is required",
            403,
          );
        if (operation === "validate") {
          const calc = this.calculate(r.input);
          if (
            !isDeepStrictEqual(
              calc,
              Object.fromEntries(
                Object.keys(calc).map((k) => [k, r.snapshot[k]]),
              ),
            )
          )
            fail("CONFLICT", "Calculation snapshot mismatch");
        }
      } catch (e: any) {
        if (bulk && e?.extensions?.code)
          fail(
            e.extensions.code,
            `Result ${i + 1} of ${items.length}: ${e.message}`,
            e.statusCode,
          );
        throw e;
      }
    }
    const changed = (
      await c.query(
        "UPDATE app.payroll_results SET status=$2,version=version+1,reviewed_by=CASE WHEN $3='review' THEN app.actor_id() WHEN $3='return' THEN NULL ELSE reviewed_by END,approved_by=CASE WHEN $3='approve' THEN app.actor_id() ELSE approved_by END,published_at=CASE WHEN $3='publish' THEN now() ELSE published_at END,updated_at=now() WHERE id=ANY($1::uuid[]) RETURNING id,status,version",
        [
          ids,
          operation === "return" ? "draft" : stages[operation]![1],
          operation,
        ],
      )
    ).rows;
    await c.query(
      `INSERT INTO app.payroll_history(organization_id,site_id,result_id,version,actor_id,event,reason,snapshot)
        SELECT app.org_id(),app.site_id(),id,version,app.actor_id(),$2,$3,
          jsonb_build_object('calculation',snapshot,'status',status,'allocations',allocations,'createdBy',created_by,'reviewedBy',reviewed_by,'approvedBy',approved_by)
        FROM app.payroll_results WHERE id=ANY($1::uuid[])`,
      [ids, operation, reason],
    );
    await c.query(
      `INSERT INTO app.audit_records(organization_id,site_id,actor_id,action,entity_id,metadata)
        SELECT app.org_id(),app.site_id(),app.actor_id(),$2,id,'{"fields":["status","version"]}'::jsonb FROM unnest($1::uuid[]) id`,
      [ids, `operations.payroll.${operation}`],
    );
    if (operation === "publish")
      await c.query(
        "SELECT app.operation_notify(user_id,'my_payroll',id,'payroll.published') FROM app.payroll_results WHERE id=ANY($1::uuid[])",
        [ids],
      );
    const result = new Map(changed.map((r) => [r.id, r]));
    return ids.map((id) => result.get(id)!);
  }
  async payrollRecord(c: Tx, r: any, event: string, reason: string) {
    await c.query(
      "INSERT INTO app.payroll_history(organization_id,site_id,result_id,version,actor_id,event,reason,snapshot) VALUES(app.org_id(),app.site_id(),$1,$2,app.actor_id(),$3,$4,$5)",
      [
        r.id,
        r.version,
        event,
        reason,
        {
          calculation: r.snapshot,
          status: r.status,
          allocations: r.allocations,
          createdBy: r.created_by,
          reviewedBy: r.reviewed_by,
          approvedBy: r.approved_by,
        },
      ],
    );
    await this.auditOperation(c, `payroll.${event}`, r.id, [
      "status",
      "version",
    ]);
  }
  /** Drafts every employment at this site whose single effective salary
   * structure covers the whole period. Anything needing judgement (joiners,
   * leavers, mid-period revisions) is skipped with a reason, never prorated. */
  async payrollRun(c: Tx, site: string, p: any) {
    if (p.periodEnd < p.periodStart)
      fail("BAD_INPUT", "Pay period end precedes start");
    const rows = (
      await c.query(
        `SELECT er.id,e.id AS "employeeId",e.user_id,er.starts_on::text AS "startsOn",er.ends_on::text AS "endsOn",
 (SELECT json_agg(json_build_object('startsOn',s.starts_on::text,'endsOn',s.ends_on::text,'components',s.components)) FROM app.salary_structures s
  WHERE s.employment_id=er.id AND s.starts_on<=LEAST($2::date,COALESCE(er.ends_on,$2::date)) AND COALESCE(s.ends_on,'infinity')>=GREATEST($1::date,er.starts_on)) AS structures,
 EXISTS(SELECT 1 FROM app.payroll_results r WHERE r.employment_id=er.id AND r.period_start<=$2::date AND r.period_end>=$1::date) AS prepared
FROM app.employment_records er JOIN app.employees e ON e.id=er.employee_id
WHERE er.starts_on<=$2::date AND COALESCE(er.ends_on,'infinity')>=$1::date AND app.allowed('employees.view',er.employee_id)
 AND EXISTS(SELECT 1 FROM app.site_assignments a WHERE a.site_id=app.site_id() AND a.employee_id=er.employee_id AND a.starts_on<=$2::date AND COALESCE(a.ends_on,'infinity')>=$1::date)
ORDER BY e.display_name,er.id LIMIT 500`,
        [p.periodStart, p.periodEnd],
      )
    ).rows;
    const created: any[] = [],
      skipped: { employmentId: string; reason: string }[] = [];
    for (const e of rows) {
      const s = e.structures ?? [];
      // Joiners and leavers are paid for their employed days only.
      const from = [p.periodStart, e.startsOn].sort()[1]!,
        to = [p.periodEnd, e.endsOn ?? p.periodEnd].sort()[0]!;
      const skip = e.prepared
        ? "exists"
        : !e.user_id
          ? "no_account"
          : !s.length
            ? "no_structure"
            : s.length > 1 ||
                s[0].startsOn > from ||
                (s[0].endsOn && s[0].endsOn < to)
              ? "structure_partial"
              : created.length >= RUN_LIMIT
                ? "batch_limit"
                : null;
      if (skip) {
        skipped.push({ employmentId: e.id, reason: skip });
        continue;
      }
      await c.query("SAVEPOINT payroll_run_item");
      try {
        const {
          lines,
          rounding,
          accountantReview,
          policyVersion,
          assumptions,
        } = s[0].components;
        const summary = await this.attendanceSummary(
          c,
          e.employeeId,
          p.periodStart,
          p.periodEnd,
          from,
          to,
        );
        const calculation = {
          lines: lines.map(({ calculatedPaise: _, ...l }: any) =>
            prorate(l, summary),
          ),
          rounding,
          accountantReview,
          policyVersion,
          assumptions,
        };
        const r = await this.payrollSave(
          c,
          site,
          {
            expectedVersion: 0,
            employmentId: e.id,
            periodStart: p.periodStart,
            periodEnd: p.periodEnd,
            calculation,
            allocations: [
              { siteId: site, paise: this.calculate(calculation).netPaise },
            ],
            attendanceNote: p.attendanceNote,
            attendanceSummary: summary,
            reason: p.reason,
            previousId: null,
          },
          "create",
          "run",
        );
        await c.query("RELEASE SAVEPOINT payroll_run_item");
        created.push({
          id: r.id,
          employmentId: e.id,
          status: r.status,
          version: r.version,
        });
      } catch (err: any) {
        await c.query("ROLLBACK TO SAVEPOINT payroll_run_item");
        skipped.push({
          employmentId: e.id,
          reason:
            err?.extensions?.code ??
            (err?.code === "P0001" ? err.message : "rejected"),
        });
      }
    }
    return { created, skipped, truncated: rows.length === 500 };
  }
  /** Payable days for one employee over [from,to] inside the pay period, from
   *  check-ins, approved leave, rosters and holidays. A suggestion for HR to
   *  review: pending check-ins count as present, approved leave is paid except
   *  types coded LOP/LWP, and no check-ins at all means "not tracked", never
   *  "absent the whole month". Days outside the employment are not payable. */
  async attendanceSummary(
    c: Tx,
    employee: string,
    periodStart: string,
    periodEnd: string,
    from: string,
    to: string,
  ): Promise<AttendanceSummary> {
    const r = (
      await c.query(
        `WITH tz AS (SELECT timezone FROM app.sites WHERE id=app.site_id()),
 days AS (SELECT d::date AS day FROM generate_series($2::date,$3::date,interval '1 day') d),
 rostered AS (SELECT DISTINCT work_date AS day FROM app.shift_rosters WHERE employee_id=$1 AND work_date BETWEEN $2::date AND $3::date),
 holidays AS (SELECT (details->>'date')::date AS day FROM app.site_reference_items WHERE kind='holiday' AND active AND details->>'date' BETWEEN $2::text AND $3::text),
 working AS (SELECT day FROM rostered UNION SELECT day FROM days WHERE NOT EXISTS(SELECT 1 FROM rostered) AND extract(dow FROM day)<>0 AND day NOT IN (SELECT day FROM holidays)),
 attended AS (SELECT (s.opened_at AT TIME ZONE (SELECT timezone FROM tz))::date AS day,bool_and(v.status<>'accepted') AS pending
  FROM app.duty_sessions s JOIN app.duty_events e ON e.duty_id=s.id AND e.kind='IN' JOIN app.event_verifications v ON v.event_id=e.id
  WHERE s.employee_id=$1 AND v.status IN ('accepted','pending_verification')
   AND s.opened_at>=($2::date::timestamp AT TIME ZONE (SELECT timezone FROM tz)) AND s.opened_at<(($3::date+1)::timestamp AT TIME ZONE (SELECT timezone FROM tz))
  GROUP BY 1),
 leave AS (SELECT d::date AS day,max(CASE WHEN l.half='full' THEN 1.0 ELSE 0.5 END) AS portion,bool_or(upper(t.code) IN ('LOP','LWP')) AS unpaid
  FROM app.leave_requests l JOIN app.leave_types t ON t.id=l.type_id
  CROSS JOIN LATERAL generate_series(GREATEST(l.starts_on,$2::date),LEAST(l.ends_on,$3::date),interval '1 day') d
  WHERE l.employee_id=$1 AND l.status='approved' AND l.starts_on<=$3::date AND l.ends_on>=$2::date GROUP BY 1)
SELECT app.allowed('attendance.view',$1) AND app.allowed('leave.view',$1) AS visible,
 EXISTS(SELECT 1 FROM rostered) AS rostered,(SELECT count(*) FROM attended)::int AS attended,
 count(w.day)::int AS working,count(a.day)::int AS present,count(*) FILTER (WHERE a.pending)::int AS pending,
 COALESCE(sum(lv.portion) FILTER (WHERE a.day IS NULL AND NOT lv.unpaid),0)::float AS paid_leave,
 COALESCE(sum(lv.portion) FILTER (WHERE a.day IS NULL AND lv.unpaid),0)::float AS unpaid_leave,
 COALESCE(sum(CASE WHEN a.day IS NOT NULL THEN 0 WHEN lv.day IS NOT NULL AND NOT lv.unpaid THEN 1-lv.portion ELSE 1 END),0)::float AS absent
FROM working w LEFT JOIN attended a ON a.day=w.day LEFT JOIN leave lv ON lv.day=w.day`,
        [employee, from, to],
      )
    ).rows[0];
    const days = (a: string, b: string) =>
      Math.round((Date.parse(b) - Date.parse(a)) / 86400000) + 1;
    const periodDays = days(periodStart, periodEnd),
      employedDays = days(from, to);
    const basis = !r.visible
      ? "not_visible"
      : !r.attended
        ? "no_attendance"
        : r.rostered
          ? "roster"
          : "weekdays";
    const counted = basis === "roster" || basis === "weekdays";
    const absentDays = counted ? r.absent : 0;
    const payableDays = Math.max(0, employedDays - absentDays);
    return {
      basis,
      periodDays,
      employedDays,
      workingDays: counted ? r.working : null,
      presentDays: counted ? r.present : null,
      pendingDays: counted ? r.pending : null,
      paidLeaveDays: counted ? r.paid_leave : null,
      unpaidLeaveDays: counted ? r.unpaid_leave : null,
      absentDays,
      payableDays,
      prorated: payableDays !== periodDays,
    };
  }
  async payrollPay(c: Tx, actor: Actor, p: any) {
    const today = (
      await c.query(
        "SELECT (now() AT TIME ZONE timezone)::date::text AS d FROM app.sites WHERE id=app.site_id()",
      )
    ).rows[0].d;
    if (p.paidOn > today)
      fail("BAD_INPUT", "Payment date cannot be in the future");
    const payments = [];
    for (const it of p.items) {
      const r = await this.payable(c, actor, it.id);
      try {
        payments.push(
          (
            await c.query(
              "INSERT INTO app.payroll_payments(organization_id,site_id,result_id,employment_id,employee_id,period_start,period_end,kind,amount_paise,method,reference,paid_on,reason,created_by) VALUES(app.org_id(),app.site_id(),$1,$2,$3,$4,$5,'payment',$6,$7,$8,$9,$10,app.actor_id()) RETURNING id,result_id AS \"resultId\"",
              [
                r.id,
                r.employment_id,
                r.employee_id,
                r.ps,
                r.pe,
                it.paise,
                p.method,
                p.reference,
                p.paidOn,
                p.reason,
              ],
            )
          ).rows[0],
        );
      } catch (e: any) {
        if (
          e?.code === "P0001" &&
          ["OVERPAYMENT", "CONFLICT"].includes(e.message)
        )
          fail(
            "CONFLICT",
            e.message === "OVERPAYMENT"
              ? `${r.name} (${r.ps}): payment exceeds the balance due`
              : `${r.name} (${r.ps}): a newer revision replaced this result`,
            409,
          );
        throw e;
      }
      await this.auditOperation(c, "payroll.pay", r.id, ["payment"]);
      if (r.status === "published")
        await this.notify(c, r.user_id, "my_payroll", r.id, "payroll.paid");
    }
    return { payments };
  }
  async payrollReverse(c: Tx, actor: Actor, p: any) {
    const o = (
      await c.query(
        "SELECT * FROM app.payroll_payments WHERE id=$1 AND kind='payment'",
        [p.paymentId],
      )
    ).rows[0];
    if (!o) fail("NOT_FOUND", "Payment unavailable", 404);
    const r = await this.payable(c, actor, o.result_id, true);
    if (
      (
        await c.query(
          "SELECT 1 FROM app.payroll_payments WHERE reverses_id=$1",
          [o.id],
        )
      ).rowCount
    )
      fail("CONFLICT", "This payment is already reversed", 409);
    const row = (
      await c.query(
        "INSERT INTO app.payroll_payments(organization_id,site_id,result_id,employment_id,employee_id,period_start,period_end,kind,amount_paise,method,reference,paid_on,reverses_id,reason,created_by) SELECT app.org_id(),app.site_id(),$1,$2,$3,$4,$5,'reversal',$6,$7,$8,(now() AT TIME ZONE timezone)::date,$9,$10,app.actor_id() FROM app.sites WHERE id=app.site_id() RETURNING id",
        [
          r.id,
          r.employment_id,
          r.employee_id,
          r.ps,
          r.pe,
          o.amount_paise,
          o.method,
          o.reference,
          o.id,
          p.reason,
        ],
      )
    ).rows[0];
    await this.auditOperation(c, "payroll.reverse_payment", r.id, ["payment"]);
    return { id: row.id, reverses: o.id };
  }
  async payable(c: Tx, actor: Actor, id: string, reversal = false) {
    const r = (
      await c.query(
        "SELECT id,employment_id,employee_id,user_id,status,period_start::text AS ps,period_end::text AS pe,snapshot->>'employeeName' AS name FROM app.payroll_results WHERE id=$1",
        [id],
      )
    ).rows[0];
    if (!r) fail("NOT_FOUND", "Payroll result unavailable", 404);
    await this.payrollAccess(c, "payroll.manage", r.employee_id);
    if (r.user_id === actor.id)
      fail("FORBIDDEN", "You cannot record payments of your own salary", 403);
    if (!reversal && !["approved", "published"].includes(r.status))
      fail(
        "CONFLICT",
        `${r.name} (${r.ps}): only approved or published payroll can be paid`,
        409,
      );
    return r;
  }
  /** The site's payslip design, or the default (version 0) before any save. */
  async payslipDesign(c: Tx) {
    const row = (
      await c.query(
        'SELECT design,version,updated_at AS "updatedAt" FROM app.payslip_designs',
      )
    ).rows[0];
    const parsed = payslipDesign.safeParse(row?.design);
    return parsed.success
      ? { design: parsed.data, version: row.version, updatedAt: row.updatedAt }
      : {
          design: defaultPayslipDesign,
          version: row?.version ?? 0,
          updatedAt: null,
        };
  }
  async saveDesign(c: Tx, site: string, p: any) {
    let logo: string | null = null;
    if (p.design.logo) {
      try {
        const png = await sharp(
          Buffer.from(p.design.logo.split(",")[1], "base64"),
          { limitInputPixels: 16_000_000 },
        )
          .resize(480, 160, { fit: "inside", withoutEnlargement: true })
          .png({ palette: true, compressionLevel: 9 })
          .toBuffer();
        logo = `data:image/png;base64,${png.toString("base64")}`;
      } catch {
        fail("BAD_INPUT", "The logo could not be read as an image");
      }
      if (logo.length > 60000)
        fail("BAD_INPUT", "Use a simpler or smaller logo image");
    }
    const value = payslipDesign.parse({ ...p.design, logo });
    const r = (
      await c.query(
        p.expectedVersion === 0
          ? "INSERT INTO app.payslip_designs(organization_id,site_id,design,updated_by) VALUES(app.org_id(),app.site_id(),$1,app.actor_id()) ON CONFLICT DO NOTHING RETURNING version"
          : "UPDATE app.payslip_designs SET design=$1,version=version+1,updated_by=app.actor_id(),updated_at=now() WHERE version=$2 RETURNING version",
        p.expectedVersion === 0 ? [value] : [value, p.expectedVersion],
      )
    ).rows[0];
    if (!r)
      fail("CONFLICT", "The payslip design changed; reload before saving", 409);
    await this.auditOperation(c, "payroll.design", site, ["payslipDesign"]);
    return { version: r.version };
  }
  calculate(input: unknown) {
    try {
      return calculatePayroll(input);
    } catch {
      fail(
        "BAD_INPUT",
        "Check exact amounts, component codes, ratios and accountant-reviewed policy",
      );
    }
  }
  async payEmployment(c: Tx, id: string) {
    const e = (
      await c.query(
        "SELECT er.*,er.starts_on::text,er.ends_on::text,e.user_id,e.display_name,e.employee_code,l.name legal_employer FROM app.employment_records er JOIN app.employees e ON e.id=er.employee_id JOIN app.legal_employers l ON l.id=er.legal_employer_id WHERE er.id=$1",
        [id],
      )
    ).rows[0];
    if (!e || !e.user_id) fail("NOT_FOUND", "Employment unavailable", 404);
    return e;
  }
  /** Current (non-superseded) results as a CSV payroll register with payment
   * balances. Bounded; narrow the period for larger sites. */
  async payrollRegister(actor: Actor, site: string, raw: unknown) {
    const q = filters.parse(raw);
    return this.site(actor, site, async (c) => {
      await this.payrollAccess(c, "payroll.export");
      const rows = (
        await c.query(
          `SELECT r.snapshot->>'employeeCode' AS code,r.snapshot->>'employeeName' AS name,r.snapshot->>'legalEmployer' AS employer,
 r.period_start::text AS ps,r.period_end::text AS pe,r.revision,r.status,r.snapshot->>'grossPaise' AS gross,r.snapshot->>'deductionPaise' AS deductions,
 m.net::text AS net,m.paid::text AS paid,m.payable,
 (SELECT max(x.paid_on)::text FROM app.payroll_payments x WHERE x.organization_id=r.organization_id AND x.employment_id=r.employment_id AND x.period_start=r.period_start AND x.period_end=r.period_end AND x.kind='payment'
  AND NOT EXISTS(SELECT 1 FROM app.payroll_payments v WHERE v.reverses_id=x.id)) AS "paidOn",
 (SELECT string_agg(x.reference,'; ' ORDER BY x.created_at) FROM app.payroll_payments x WHERE x.organization_id=r.organization_id AND x.employment_id=r.employment_id AND x.period_start=r.period_start AND x.period_end=r.period_end AND x.kind='payment'
  AND NOT EXISTS(SELECT 1 FROM app.payroll_payments v WHERE v.reverses_id=x.id)) AS refs
FROM app.payroll_results r ${METRICS} WHERE ${FILTER} AND NOT m.superseded ORDER BY r.period_start,name,r.id LIMIT 5001`,
          filterParams(q),
        )
      ).rows;
      if (rows.length > 5000)
        fail("BAD_INPUT", "Register exceeds 5,000 rows; narrow the period");
      await this.auditOperation(c, "payroll.register", site, ["register"]);
      return [
        [
          "Employee code",
          "Employee",
          "Legal employer",
          "Period start",
          "Period end",
          "Revision",
          "Status",
          "Gross INR",
          "Deductions INR",
          "Net INR",
          "Paid INR",
          "Due INR",
          "Last paid on",
          "Payment references",
        ],
        ...rows.map((r) => [
          r.code,
          r.name,
          r.employer,
          r.ps,
          r.pe,
          r.revision,
          r.status,
          money(r.gross),
          money(r.deductions),
          money(r.net),
          money(r.paid),
          r.payable ? signedMoney(BigInt(r.net) - BigInt(r.paid)) : "",
          r.paidOn ?? "",
          r.refs ?? "",
        ]),
      ]
        .map((row) => row.map(csvCell).join(","))
        .join("\r\n");
    });
  }
  async payrollDownload(
    actor: Actor,
    site: string,
    id: string,
    format: string,
  ) {
    return this.site(actor, site, async (c) => {
      const r = (
        await c.query(
          "SELECT *,period_start::text AS start,period_end::text AS finish FROM app.payroll_results WHERE id=$1 AND status='published'",
          [z.uuid().parse(id)],
        )
      ).rows[0];
      if (!r) fail("NOT_FOUND", "Published payslip unavailable", 404);
      if (r.user_id === actor.id) {
        if (
          !(
            await c.query("SELECT app.payroll_own($1,'my_payroll.export') ok", [
              r.employee_id,
            ])
          ).rows[0].ok
        )
          fail("FORBIDDEN", "Download is not permitted", 403);
      } else await this.payrollAccess(c, "payroll.export", r.employee_id);
      await this.auditOperation(c, "payroll.download", id, [
        "publishedRevision",
      ]);
      const payments = (
        await c.query(
          'SELECT kind,amount_paise::text AS paise,method,reference,paid_on::text AS "paidOn" FROM app.payroll_payments WHERE organization_id=$1 AND employment_id=$2 AND period_start=$3 AND period_end=$4 ORDER BY created_at',
          [r.organization_id, r.employment_id, r.start, r.finish],
        )
      ).rows;
      const paid = payments.reduce(
        (n, x) => n + (x.kind === "payment" ? 1n : -1n) * BigInt(x.paise),
        0n,
      );
      const extra = (
        await c.query(
          'SELECT e.department,e.job_title AS "jobTitle",(SELECT timezone FROM app.sites WHERE id=app.site_id()) AS timezone FROM (SELECT 1) x LEFT JOIN app.employees e ON e.id=$1',
          [r.employee_id],
        )
      ).rows[0];
      if (format === "json")
        return {
          type: "application/json",
          body: JSON.stringify({
            id: r.id,
            start: r.start,
            finish: r.finish,
            revision: r.revision,
            publishedAt: r.published_at,
            snapshot: r.snapshot,
            payments,
            paidPaise: paid.toString(),
            department: extra.department,
            jobTitle: extra.jobTitle,
            // Site-local calendar date, so clients need no timezone database.
            publishedOn: new Intl.DateTimeFormat("en-CA", {
              timeZone: extra.timezone,
            }).format(new Date(r.published_at)),
          }),
        };
      if (format === "csv")
        return {
          type: "text/csv; charset=utf-8",
          body: [
            [
              "Employee",
              "Period start",
              "Period end",
              "Revision",
              "Component",
              "Kind",
              "INR",
            ],
            ...r.snapshot.lines.map((l: any) => [
              r.snapshot.employeeName,
              r.start,
              r.finish,
              r.revision,
              l.label,
              l.kind,
              money(l.calculatedPaise),
            ]),
          ]
            .map((row) => row.map(csvCell).join(","))
            .join("\r\n"),
        };
      return {
        type: "text/html; charset=utf-8",
        body: renderPayslipHtml((await this.payslipDesign(c)).design, {
          id: r.id,
          start: r.start,
          finish: r.finish,
          revision: r.revision,
          publishedAt: r.published_at?.toISOString?.() ?? r.published_at,
          snapshot: r.snapshot,
          payments,
          paidPaise: paid.toString(),
          ...extra,
        }),
      };
    });
  }
}
function signedMoney(v: bigint) {
  return v < 0n ? `-${money((-v).toString())}` : money(v.toString());
}
