import test from "node:test";
import assert from "node:assert/strict";
import {
  humanize,
  statusTone,
} from "../../apps/hr-web/src/components/shared/status.js";
test("HR status badges humanize machine values without touching dates or free text", () => {
  assert.equal(humanize("in_progress"), "In progress");
  assert.equal(humanize("pending_verification"), "Pending verification");
  assert.equal(humanize("task.assigned"), "Task assigned");
  assert.equal(humanize("2026-09-26"), "2026-09-26");
  assert.equal(humanize("Unread"), "Unread");
  assert.equal(humanize("helpdesk · submitted"), "helpdesk · submitted");
  assert.equal(statusTone("approved"), "success");
  assert.equal(statusTone("Pending verification"), "warning");
  assert.equal(statusTone("blocked"), "danger");
  assert.equal(statusTone("in_progress"), "info");
  assert.equal(statusTone("todo"), "neutral");
});
