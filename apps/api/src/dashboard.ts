import { z } from "zod";
import { Analytics } from "./analytics.js";
import type { Actor } from "../../../packages/authz/src/index.js";
import type { DashboardSnapshot } from "../../../packages/contracts/dashboard.js";

const DAYS = 14;
/** YYYY-MM-DD for the `DAYS` site-local dates ending at `today`. */
export function trendDays(today: string) {
  const end = Date.parse(`${today}T00:00:00Z`);
  return Array.from({ length: DAYS }, (_, i) =>
    new Date(end - (DAYS - 1 - i) * 86_400_000).toISOString().slice(0, 10),
  );
}
/** Largest `keep` entries, the rest folded into one "Other" entry. */
export function topWithOther<T extends { name: string }>(
  rows: T[],
  value: keyof T,
  keep = 5,
): T[] {
  if (rows.length <= keep + 1) return rows;
  const other = rows.slice(keep).reduce((sum, r) => sum + Number(r[value]), 0);
  return [...rows.slice(0, keep), { name: "Other", [value]: other } as T];
}

export class Dashboard extends Analytics {
  /**
   * One scoped transaction. HR records, payroll, approvals and "me" read under
   * runtime RLS; the high-volume sections come from app.dashboard_facts(), which
   * applies the same per-employee app.allowed decisions once per employee.
   */
  async dashboard(actor: Actor, siteId: string): Promise<DashboardSnapshot> {
    return this.site(actor, siteId, async (c) => {
      const one = async (sql: string, args: unknown[] = []) =>
        (await c.query(sql, args)).rows[0];
      const all = async (sql: string, args: unknown[] = []) =>
        (await c.query(sql, args)).rows;
      const g = await one(
        `SELECT s.timezone tz,(now() AT TIME ZONE s.timezone)::date::text today,
 app.allowed('expenses.view') expenses,app.allowed('helpdesk.view') helpdesk,
 app.allowed('documents.view') documents,app.allowed('assets.view') assets,
 app.payroll_admin('payroll.view') payroll,app.allowed('inbox.view') inbox,
 app.allowed('my_dwr.view') my_dwr,app.allowed('my_attendance.view') my_attendance
 FROM app.sites s WHERE s.id=app.site_id()`,
      );
      const today = g.today as string,
        tz = g.tz as string,
        days = trendDays(today);
      const out: DashboardSnapshot = {
        workDate: today,
        timezone: tz,
        generatedAt: new Date().toISOString(),
        me: { unread: null, dwrStatus: null, onDuty: null },
        approvals: [],
        approvalsCapped: false,
      };

      const me = await one(
        `SELECT CASE WHEN $2 THEN (SELECT count(*)::int FROM app.inbox_items WHERE user_id=app.actor_id() AND read_at IS NULL) END unread,
 CASE WHEN $3 THEN (SELECT status FROM app.dwr_reports WHERE user_id=app.actor_id() AND work_date=$1::date LIMIT 1) END dwr,
 CASE WHEN $4 THEN EXISTS(SELECT 1 FROM app.duty_sessions WHERE user_id=app.actor_id() AND status='open') END on_duty`,
        [today, g.inbox, g.my_dwr, g.my_attendance],
      );
      out.me = {
        unread: me.unread,
        dwrStatus: g.my_dwr ? (me.dwr ?? "none") : null,
        onDuty: me.on_duty,
      };

      // People, attendance, leave, tasks and DWR: one call that decides each
      // permission per employee instead of per row (see 0046_dashboard_facts).
      const f = (await one("SELECT app.dashboard_facts() f")).f;
      const n = (v: unknown) => Number(v ?? 0);
      if (f.people)
        out.people = {
          headcount: n(f.people.headcount),
          joining: n(f.people.joining),
          departments: topWithOther(
            f.people.departments.map((d: any) => ({
              name: d.name,
              count: n(d.count),
            })),
            "count",
          ),
        };
      if (f.attendance) {
        const at = (rows: any[], day: string) =>
          n(rows.find((r) => r.day === day)?.n);
        out.attendance = {
          rostered: n(f.attendance.rostered),
          checkedIn: n(f.attendance.checkedIn),
          onDuty: n(f.attendance.onDuty),
          pendingVerification: n(f.attendance.pendingVerification),
          trend: days.map((day) => ({
            day,
            rostered: at(f.attendance.roster, day),
            checkedIn: at(f.attendance.seen, day),
          })),
          notCheckedIn: {
            count: n(f.attendance.notCheckedIn.count),
            people: f.attendance.notCheckedIn.people,
          },
          exitNotRecorded: {
            count: n(f.attendance.exitNotRecorded.count),
            people: f.attendance.exitNotRecorded.people,
          },
        };
      }
      if (f.location)
        out.location = {
          now: n(f.location.now),
          today: n(f.location.today),
        };
      if (f.leave)
        out.leave = {
          onLeave: n(f.leave.onLeave),
          pending: n(f.leave.pending),
          upcoming: n(f.leave.upcoming),
          byType: topWithOther(f.leave.byType, "units"),
        };
      if (f.tasks) {
        const rows: any[] = f.tasks;
        out.tasks = {
          open: ["todo", "in_progress", "blocked"].map((status) => ({
            status,
            count: n(rows.find((r) => r.status === status)?.count),
          })),
          overdue: rows.reduce((sum, r) => sum + n(r.overdue), 0),
          dueToday: rows.reduce((sum, r) => sum + n(r.dueToday), 0),
        };
      }
      if (f.dwr) {
        const reports: any[] = f.dwr.reports;
        const count = (day: string, statuses: string[]) =>
          reports
            .filter((r) => r.day === day && statuses.includes(r.status))
            .reduce((sum, r) => sum + n(r.n), 0);
        out.dwr = {
          today: ["draft", "submitted", "returned", "approved"].map(
            (status) => ({ status, count: count(today, [status]) }),
          ),
          awaitingReview: n(f.dwr.waiting),
          trend: days.map((day) => ({
            day,
            filed: count(day, ["submitted", "approved"]),
          })),
        };
      }

      if (g.expenses || g.helpdesk || g.documents || g.assets) {
        // The (kind,status) filter keeps the per-row hr_records policy on the index range.
        const h = await one(
          `SELECT count(*) FILTER(WHERE kind='expense')::int expenses,
 count(*) FILTER(WHERE kind='helpdesk')::int helpdesk,
 count(*) FILTER(WHERE kind='document' AND payload->>'expiresOn' ~ '^\\d{4}-\\d{2}-\\d{2}$' AND (payload->>'expiresOn')::date<=$1::date+30)::int documents,
 count(*) FILTER(WHERE kind='asset')::int assets
 FROM app.hr_records WHERE (kind,status) IN (('expense','submitted'),('helpdesk','submitted'),('helpdesk','in_progress'),('document','approved'),('asset','assigned'),('asset','acknowledged'))`,
          [today],
        );
        out.hr = {
          ...(g.expenses && { expensesPending: h.expenses }),
          ...(g.helpdesk && { helpdeskOpen: h.helpdesk }),
          ...(g.documents && { documentsExpiring: h.documents }),
          ...(g.assets && { assetsAssigned: h.assets }),
        };
      }

      if (g.payroll) {
        // Latest revision per employment for the most recent period.
        const rows = await all(
          `SELECT period_start::text,period_end::text,status,count(*)::int count FROM app.payroll_results r
 WHERE period_start=(SELECT max(period_start) FROM app.payroll_results)
 AND NOT EXISTS(SELECT 1 FROM app.payroll_results n WHERE n.previous_id=r.id)
 GROUP BY 1,2,3 ORDER BY 3`,
        );
        out.payroll = rows.length
          ? {
              periodStart: rows[0].period_start,
              periodEnd: rows[0].period_end,
              statuses: rows.map((r) => ({ status: r.status, count: r.count })),
            }
          : null;
      }

      const queue = await this.approvalRows(c);
      const kinds = new Map<string, number>();
      for (const r of queue) kinds.set(r.kind, (kinds.get(r.kind) ?? 0) + 1);
      out.approvals = [...kinds].map(([kind, count]) => ({ kind, count }));
      // HR record kinds share one 100-row read; the others read 100 each.
      const own = ["payroll", "leave", "attendance", "dwr"];
      out.approvalsCapped =
        queue.filter((r) => !own.includes(r.kind)).length >= 100 ||
        own.some((k) => (kinds.get(k) ?? 0) >= 100);
      return out;
    });
  }
  /** Up to 8 employees the actor may view whose name or code contains `search`. */
  async employeeLookup(actor: Actor, siteId: string, search: unknown) {
    const q = z.string().trim().min(1).max(60).parse(search);
    return this.site(
      actor,
      siteId,
      async (c) =>
        (await c.query("SELECT id,name,code FROM app.employee_lookup($1)", [q]))
          .rows,
    );
  }
}
