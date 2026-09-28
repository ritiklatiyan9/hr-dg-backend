import { test } from "node:test";
import assert from "node:assert/strict";
import { pushText } from "../../apps/worker/src/fcm.js";
test("push text: specific per event family and never record content", () => {
  const cases: [string, string, string][] = [
    ["attendance", "attendance.accepted", "Attendance recorded"],
    ["attendance", "attendance.review_required", "Attendance to review"],
    ["attendance", "adjustment.requested", "Correction to review"],
    ["leave", "leave.decided", "Leave decision"],
    ["tasks", "task.comment.6f1c2e1a-0000-4000-8000-000000000001", "New task comment"],
    ["tasks", "task.updated.done", "Task updated"],
    ["field_duty", "visit.assigned", "Field visit scheduled"],
    ["my_dwr", "dwr.reminder.2026-09-26", "Daily report reminder"],
    ["dwr_review", "dwr.submitted.v3", "DWR to review"],
    ["my_dwr", "dwr.return.v4", "DWR returned"],
    ["my_dwr", "dwr.group.added", "Added to a DWR group"],
    ["my_payroll", "payroll.published", "Payslip published"],
    ["my_payroll", "payroll.paid", "Salary payment recorded"],
    ["helpdesk", "hr.helpdesk.in_progress.v2", "Helpdesk request update"],
    ["announcements", "hr.announcement.published.v1", "New announcement"],
    ["grievances", "hr.grievance.resolved.v3", "Confidential case update"],
    ["my_documents", "hr.document.expiry.2026-10-01", "Document expiring"],
    ["x", "unknown.thing", "Defence Garden HR"],
  ];
  for (const [module, type, title] of cases) {
    const t = pushText(module, type);
    assert.equal(t.title, title, type);
    // Lock screens are public: no ids, dates, versions or amounts.
    assert.doesNotMatch(`${t.title} ${t.body}`, /\d|₹|resolved/, type);
  }
  assert.equal(pushText("helpdesk", "hr.helpdesk.in_progress.v2").body, "A helpdesk request is now in progress.");
});
