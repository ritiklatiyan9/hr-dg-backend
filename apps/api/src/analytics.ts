import { z } from "zod";
import { Hr } from "./hr.js";
import { fail, type Actor } from "../../../packages/authz/src/index.js";
import type { Tx } from "../../../packages/db/src/index.js";
import {
  analyticsInput,
  analyticsTools,
  type AnalyticsInput,
  type AnalyticsTool,
  type AnalyticsSite,
  type AnalyticsSnapshot,
  type Metric,
  explainSelections,
} from "../../../packages/contracts/analytics.js";
import {
  AnalyticsProvider,
  AnalyticsProviderError,
  analyticsSetup,
} from "./analytics-provider.js";

const capability: Record<AnalyticsTool, string> = {
  getWorkforceSummary: "employees.view",
  getAttendanceSummary: "attendance.view",
  getDwrCompliance: "dwr_review.view",
  getApprovalBacklog: "analytics.view",
  getTaskBacklog: "tasks.view",
  getHrSummary: "analytics.view",
  getPayrollSummary: "payroll.view",
};
export class Analytics extends Hr {
  async authorizeAnalytics(c: Tx, anchor: string, p: AnalyticsInput) {
    await this.allowed(c, "analytics.view");
    if (!p.siteIds.includes(anchor))
      fail("BAD_INPUT", "Include the selected workspace site");
    if (p.siteIds.length > 1) {
      const r = (
        await c.query(
          "SELECT app.decision('analytics.view') a,app.decision('reports.view') r",
        )
      ).rows[0];
      if (r.a.scope !== "organization" || r.r.scope !== "organization")
        fail(
          "FORBIDDEN",
          "Multiple sites require explicitly authorized organization reporting",
          403,
        );
    }
  }
  async analyticsSnapshot(
    actor: Actor,
    siteId: string,
    raw: unknown,
    tool?: AnalyticsTool,
  ): Promise<AnalyticsSnapshot> {
    const p = analyticsInput.parse(raw);
    if (tool) z.enum(analyticsTools).parse(tool);
    if (p.siteIds.length > 1)
      await this.site(actor, siteId, (c) =>
        this.authorizeAnalytics(c, siteId, p),
      );
    const sites: AnalyticsSite[] = [];
    for (const selected of [...p.siteIds].sort()) {
      sites.push(
        await this.site(actor, selected, async (c) => {
          if (p.siteIds.length === 1)
            await this.authorizeAnalytics(c, siteId, p);
          else await this.allowed(c, "analytics.view");
          const s = (
            await c.query(
              "SELECT id,name,timezone,(now() AT TIME ZONE timezone)::date::text today,transaction_timestamp() AS now FROM app.sites WHERE id=$1",
              [selected],
            )
          ).rows[0];
          if (p.to > s.today)
            fail("BAD_INPUT", "Analytics dates cannot be in the future");
          const result: AnalyticsSite = {
            id: s.id,
            name: s.name,
            timezone: s.timezone,
            from: p.from,
            to: p.to,
            asOf: new Date(s.now).toISOString(),
            metrics: [],
            evidence: [],
          };
          const selectedTools = tool ? [tool] : analyticsTools;
          const grants = (
            await c.query(
              "SELECT key,app.allowed(key) ok FROM unnest($1::text[]) key",
              [[...new Set(selectedTools.map((t) => capability[t]))]],
            )
          ).rows;
          const allowed = new Map(grants.map((g) => [g.key, g.ok]));
          for (const t of selectedTools)
            await this.analyticsTool(
              c,
              p,
              result,
              t,
              allowed.get(capability[t]) === true,
            );
          await this.auditOperation(c, "analytics.read", selected, [
            tool ?? "dashboard",
          ]);
          if (
            p.siteIds.length === 1 &&
            !(
              await c.query(
                "SELECT app.check_request($1,$2) AND app.allowed('analytics.view') ok",
                [actor.sessionId, actor.permissionVersion],
              )
            ).rows[0].ok
          )
            fail(
              "SCOPE_CHANGED",
              "Access changed. Reload your workspace.",
              409,
            );
          return result;
        }),
      );
    }
    // A multi-site read is not an atomic cross-site snapshot; recheck every scope before returning.
    for (const selected of p.siteIds.length > 1 ? p.siteIds : [])
      await this.site(actor, selected, (c) =>
        this.allowed(c, "analytics.view"),
      );
    return {
      version: "analytics-v1",
      sites,
      generatedAt: new Date().toISOString(),
      explanation: {
        mode: analyticsSetup().configured ? "available" : "setup_required",
        statements: [],
      },
    };
  }
  async analyticsTool(
    c: Tx,
    p: AnalyticsInput,
    out: AnalyticsSite,
    tool: AnalyticsTool,
    gate: boolean,
  ) {
    const add = (
      id: string,
      label: string,
      value: unknown,
      denominator: string,
      source: string,
      limitation: string,
      unit: Metric["unit"] = "records",
      state?: Metric["state"],
    ) =>
      out.metrics.push({
        id,
        label,
        value: value == null ? null : String(value),
        unit,
        denominator,
        source,
        limitation,
        eligibility:
          "Current analytics and source-record permissions; effective site assignments; selected site-local date window",
        state:
          state ??
          (value == null
            ? "not_configured"
            : String(value) === "0"
              ? "no_records"
              : "observed"),
      });
    if (!gate) {
      add(
        tool,
        "Source access required",
        null,
        "Not calculated",
        capability[tool],
        "Analytics permission does not grant access to underlying records",
        "records",
        "not_authorized",
      );
      return;
    }
    const args = [p.from, p.to, out.timezone];
    // All queries remain under the existing runtime RLS on the checked-out scoped connection.
    const window =
      "WITH w AS (SELECT $1::date f,$2::date t,$1::date::timestamp AT TIME ZONE $3 lo,($2::date+1)::timestamp AT TIME ZONE $3 hi) ";
    const permitted = "app.allowed('analytics.view',employee_id)";
    const evidence = async (
      table: string,
      module: string,
      date: string,
      where: string,
    ) => {
      const rows = (
        await c.query(
          `${window} SELECT id,${date}::text date,status FROM app.${table},w WHERE ${where} AND ${permitted} ORDER BY ${date} DESC,id DESC LIMIT 5`,
          args,
        )
      ).rows;
      out.evidence.push(...rows.map((r) => ({ ...r, module })));
    };
    if (tool === "getWorkforceSummary") {
      const r = (
        await c.query(
          `${window} SELECT count(DISTINCT e.id)::int n FROM app.employees e,w WHERE app.allowed('analytics.view',e.id) AND app.allowed('employees.view',e.id) AND EXISTS(SELECT 1 FROM app.site_assignments a WHERE a.employee_id=e.id AND a.site_id=app.site_id() AND a.starts_on<=w.t AND (a.ends_on IS NULL OR a.ends_on>=w.f))`,
          args,
        )
      ).rows[0];
      add(
        "workforce",
        "Assigned workforce",
        r.n,
        "Distinct authorized employees assigned at any time in window",
        "employees + site_assignments",
        "Site counts overlap when an employee has multiple assignments; do not sum sites as organization headcount",
        "people",
      );
    }
    if (tool === "getAttendanceSummary") {
      const aggregate = (
        await c.query(
          "SELECT app.analytics_attendance($1::date,$2::date) result",
          [p.from, p.to],
        )
      ).rows[0].result;
      const r = aggregate.roster;
      const den = `${r.rostered} authorized rostered employee-days`;
      for (const [id, label, key] of [
        ["attendance_rostered", "Rostered employee-days", "rostered"],
        ["attendance_observed", "Roster days with recorded duty", "observed"],
        [
          "attendance_unobserved",
          "Roster days without recorded duty",
          "unobserved",
        ],
        ["attendance_late", "Late starts", "late"],
        ["attendance_early", "Early exits", "early"],
      ])
        add(
          id!,
          label!,
          r[key!],
          den,
          "shift_rosters + duty_sessions + versioned operation_policies",
          "Recorded duty is not biometric proof. Missing records and unknown GPS are not absence. Late/early use each duty policy grace; overnight shifts belong to start date.",
        );
      const h: { kind: string; seconds: string }[] = aggregate.hours;
      for (const kind of ["office", "field", "break", "outside", "unknown"])
        add(
          `hours_${kind}`,
          `${kind} evidence time`,
          h.find((x) => x.kind === kind)?.seconds ?? "0",
          "Seconds in latest non-overlapping duty-segment revisions, clipped to window",
          "duty_segments",
          "Gaps without segments are not counted; corrections and approved overtime remain separate. Office/field are evidence classifications, not automatic paid hours.",
          "seconds",
        );
      const pending = { n: aggregate.pending };
      add(
        "attendance_unverified",
        "Events pending verification",
        pending.n,
        "Authorized raw events received in window",
        "event_verifications + duty_events",
        "Capture time can differ from received time; pending evidence is not absence.",
      );
      await evidence(
        "duty_sessions",
        "operations",
        "opened_at",
        "opened_at>=w.lo AND opened_at<w.hi AND app.allowed('attendance.view',employee_id)",
      );
    }
    if (tool === "getDwrCompliance") {
      const setting = (
        await c.query(
          "SELECT deadline::text,deadline_day_offset FROM app.dwr_settings",
        )
      ).rows[0];
      if (!setting) {
        add(
          "dwr_overdue",
          "Overdue DWR",
          null,
          "Requires configured site deadline and roster",
          "dwr_settings + shift_rosters",
          "No deadline is invented",
        );
        return;
      }
      const r = (
        await c.query(
          "SELECT app.analytics_workload($1,$2::date,$3::date) result",
          ["dwr", p.from, p.to],
        )
      ).rows[0].result;
      add(
        "dwr_overdue",
        "Overdue DWR",
        r.overdue,
        `${r.expected} authorized roster days past configured deadline`,
        "shift_rosters + dwr_reports + dwr_settings",
        `${r.submitted} currently submitted/approved. Days without rosters are not assumed expected; drafts are not submissions; counts are not productivity scores.`,
      );
      await evidence(
        "dwr_reports",
        "dwr",
        "work_date",
        "work_date BETWEEN w.f AND w.t AND app.allowed('dwr_review.view',employee_id)",
      );
    }
    if (tool === "getTaskBacklog") {
      const r = (
        await c.query(
          "SELECT app.analytics_workload($1,$2::date,$3::date) result",
          ["tasks", p.from, p.to],
        )
      ).rows[0].result;
      add(
        "task_pending",
        "Open tasks",
        r.pending,
        `${r.total} authorized tasks due in window`,
        "work_tasks",
        "Current status at read time, not a historical status reconstruction.",
      );
      add(
        "task_overdue",
        "Overdue tasks",
        r.overdue,
        `${r.total} authorized tasks due in window`,
        "work_tasks",
        "Current unfinished tasks whose deadlines have passed.",
      );
      await evidence(
        "work_tasks",
        "operations",
        "deadline",
        "deadline>=w.lo AND deadline<w.hi",
      );
    }
    if (tool === "getApprovalBacklog") {
      const queue = await c.query(
        `${window} SELECT 'leave' kind,count(*)::int n FROM app.leave_requests,w WHERE created_at>=w.lo AND created_at<w.hi AND status='pending' AND ${permitted} AND approver_id=app.actor_id() AND user_id<>app.actor_id() AND app.allowed('leave.approve',employee_id) UNION ALL SELECT 'attendance',count(*)::int FROM app.attendance_adjustments,w WHERE created_at>=w.lo AND created_at<w.hi AND status='pending' AND ${permitted} AND requester_id<>app.actor_id() AND app.allowed('attendance.approve',employee_id) AND (SELECT rules->>'attendanceApproverId' FROM app.operation_policies ORDER BY version DESC LIMIT 1)=app.actor_id()::text UNION ALL SELECT 'dwr',count(*)::int FROM app.dwr_reports,w WHERE created_at>=w.lo AND created_at<w.hi AND status='submitted' AND ${permitted} AND user_id<>app.actor_id() AND app.allowed('dwr_review.approve',employee_id) UNION ALL SELECT 'hr',count(*)::int FROM app.hr_records,w WHERE created_at>=w.lo AND created_at<w.hi AND kind<>'grievance' AND status='submitted' AND ${permitted} AND created_by<>app.actor_id() AND user_id<>app.actor_id() AND app.hr_visible(id,'approve')`,
        args,
      );
      for (const r of queue.rows)
        add(
          `approval_${r.kind}_pending`,
          `${r.kind} approval backlog`,
          r.n,
          "Current authorized pending requests created in window",
          "leave_requests / attendance_adjustments / dwr_reports / hr_records",
          "Only permitted independent decisions; confidential grievances are excluded.",
        );
    }
    if (tool === "getHrSummary") {
      const grants = (
        await c.query(
          "SELECT app.allowed('leave.view') leave,app.allowed('documents.view') documents,app.allowed('expenses.view') expenses",
        )
      ).rows[0];
      const leaves = (
        await c.query(
          `${window} SELECT status,count(*)::int n,sum(units)::text units FROM app.leave_requests,w WHERE starts_on<=w.t AND ends_on>=w.f AND ${permitted} AND app.allowed('leave.view',employee_id) GROUP BY status`,
          args,
        )
      ).rows;
      for (const status of ["pending", "approved", "rejected"])
        add(
          `leave_${status}`,
          `${status} leave requests`,
          grants.leave
            ? (leaves.find((x) => x.status === status)?.n ?? 0)
            : null,
          "Requests overlapping date window",
          "leave_requests",
          "Counts requests, not days or absence; half-days and balances remain in the leave ledger.",
          "records",
          grants.leave ? undefined : "not_authorized",
        );
      const docs = (
        await c.query(
          `${window} SELECT count(*)::int n,count(*) FILTER(WHERE status='approved')::int approved,count(*) FILTER(WHERE payload->>'expiresOn' IS NOT NULL AND (payload->>'expiresOn')::date<w.t)::int expired FROM app.hr_records,w WHERE kind='document' AND created_at<w.hi AND ${permitted} AND app.allowed('documents.view',employee_id)`,
          args,
        )
      ).rows[0];
      add(
        "documents_expired",
        "Documents expired by window end",
        grants.documents ? docs.expired : null,
        `${docs.n} visible documents created by window end; ${docs.approved} currently approved`,
        "hr_records(document)",
        "Sensitive category permissions still apply. No document content or employee names are aggregated.",
        "records",
        grants.documents ? undefined : "not_authorized",
      );
      const expenses = (
        await c.query(
          `${window} SELECT count(*)::int n,count(*) FILTER(WHERE status='submitted')::int pending,count(*) FILTER(WHERE status='settled')::int settled FROM app.hr_records,w WHERE kind='expense' AND (payload->>'date')::date BETWEEN w.f AND w.t AND ${permitted} AND app.allowed('expenses.view',employee_id)`,
          args,
        )
      ).rows[0];
      add(
        "expenses_pending",
        "Expenses awaiting decision",
        grants.expenses ? expenses.pending : null,
        `${expenses.n} authorized expense records dated in window`,
        "hr_records(expense)",
        `${expenses.settled} marked settled; this is not bank-payment confirmation.`,
        "records",
        grants.expenses ? undefined : "not_authorized",
      );
    }
    if (tool === "getPayrollSummary") {
      const allowed = (
        await c.query(
          "SELECT app.payroll_admin('payroll.view') AND app.allowed('analytics.field.salary') AND app.decision('analytics.view')->>'scope' IN ('site','organization') AND app.decision('analytics.field.salary')->>'scope'='site' ok",
        )
      ).rows[0].ok;
      const month = new Date(
        Date.UTC(Number(p.from.slice(0, 4)), Number(p.from.slice(5, 7)), 0),
      )
        .toISOString()
        .slice(0, 10);
      if (
        !allowed ||
        !p.from.endsWith("-01") ||
        p.to !== month ||
        p.to >= new Date(out.asOf).toISOString().slice(0, 10)
      ) {
        add(
          "payroll_net",
          "Published net payroll",
          null,
          "Only a complete past calendar month; site payroll + analytics salary grants",
          "payroll_results",
          "Team, employee filters and arbitrary salary date windows are prohibited",
          "paise",
          "suppressed",
        );
        return;
      }
      const r = (
        await c.query(
          `${window}, latest AS (SELECT DISTINCT ON(employment_id,period_start,period_end) * FROM app.payroll_results,w WHERE status='published' AND period_start=w.f AND period_end=w.t AND ${permitted} AND app.payroll_admin('payroll.view',employee_id) ORDER BY employment_id,period_start,period_end,revision DESC) SELECT count(DISTINCT employee_id)::int n,COALESCE(sum((snapshot->>'netPaise')::numeric),0)::text total FROM latest`,
          args,
        )
      ).rows[0];
      add(
        "payroll_net",
        "Published net payroll",
        r.n >= 10 ? r.total : null,
        "At least ten distinct authorized employees with full-period published results",
        "payroll_results.latest published revision",
        "No employee names, minimum/maximum, site allocations or salary values are sent to AI. Totals use controlling-site canonical results.",
        "paise",
        r.n >= 10 ? "observed" : "suppressed",
      );
    }
  }
  async explainAnalytics(
    actor: Actor,
    siteId: string,
    raw: unknown,
    provider: Pick<AnalyticsProvider, "explain"> = new AnalyticsProvider(),
  ) {
    const p = analyticsInput.parse(raw),
      snapshot = await this.analyticsSnapshot(actor, siteId, p);
    if (!analyticsSetup().configured) return snapshot;
    const facts = snapshot.sites.flatMap((s, i) =>
      (Number(s.metrics.find((m) => m.id === "workforce")?.value ?? 0) >= 10
        ? s.metrics
        : []
      )
        .filter(
          (m) =>
            m.value !== null &&
            m.unit !== "paise" &&
            m.source !== "hr_records(document)",
        )
        .map((m) => ({ id: `site${i}.${m.id}`, metric: m })),
    );
    if (!facts.length) {
      snapshot.explanation = { mode: "insufficient_evidence", statements: [] };
      return snapshot;
    }
    const lease = await this.site(actor, siteId, async (c) => {
      await this.authorizeAnalytics(c, siteId, p);
      return (
        await c.query("SELECT app.analytics_reserve($1,$2,$3) id", [
          analyticsSetup().userCalls,
          analyticsSetup().orgCalls,
          analyticsSetup().concurrency,
        ])
      ).rows[0].id;
    });
    if (!lease) {
      snapshot.explanation = { mode: "budget_exhausted", statements: [] };
      return snapshot;
    }
    try {
      const output = await provider.explain(facts, AbortSignal.timeout(8000));
      const statements = explainSelections(output, facts);
      // No business transaction remains checked out during the provider request.
      for (const id of p.siteIds)
        await this.site(actor, id, (c) => this.allowed(c, "analytics.view"));
      snapshot.explanation = {
        mode: "explained",
        statements,
        model: analyticsSetup().model,
        promptVersion: "facts-only-v1",
      };
    } catch (error) {
      if (error instanceof AnalyticsProviderError && error.retryAfter)
        await this.site(actor, siteId, async (c) => {
          await c.query(
            "UPDATE app.analytics_usage SET retry_after=now()+$2*interval '1 second' WHERE id=$1",
            [lease, error.retryAfter],
          );
        });
      snapshot.explanation = { mode: "recoverable_error", statements: [] };
    } finally {
      await this.site(actor, siteId, async (c) => {
        await c.query(
          "UPDATE app.analytics_usage SET finished_at=now() WHERE id=$1",
          [lease],
        );
      }).catch(() => {});
    }
    // Never return the pre-provider data after a role downgrade, membership change or expired session.
    for (const id of p.siteIds)
      await this.site(actor, id, (c) => this.allowed(c, "analytics.view"));
    return snapshot;
  }
}
