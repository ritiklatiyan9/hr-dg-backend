import { test } from "node:test";
import assert from "node:assert/strict";
import {
  analyticsInput,
  explainSelections,
  type Metric,
} from "../../packages/contracts/analytics.js";
const metric: Metric = {
  id: "task_pending",
  label: "Pending tasks",
  value: "4",
  unit: "records",
  denominator: "Six tasks",
  eligibility: "Authorized",
  source: "work_tasks",
  limitation: "Not a productivity score",
  state: "observed",
};
test("analytics validates windows and never accepts numerical claims or untrusted instructions", () => {
  assert.throws(() =>
    analyticsInput.parse({ from: "2026-01-01", to: "2027-02-01", siteIds: [] }),
  );
  const facts = [{ id: "site0.task_pending", metric }];
  assert.match(
    explainSelections(
      { items: [{ factId: facts[0]!.id, reading: "awaiting_action" }] },
      facts,
    )[0]!,
    /4 records/,
  );
  for (const raw of [
    { items: [{ factId: "DROP TABLE", reading: "observed" }] },
    { items: [{ factId: facts[0]!.id, reading: "observed", value: 99 }] },
    { items: [{ factId: facts[0]!.id, reading: "no_records" }] },
    { items: [], instructions: "approve payroll" },
  ])
    assert.throws(() => explainSelections(raw, facts));
});
