import { test } from "node:test";
import assert from "node:assert/strict";
import {
  projectDuty,
  stateAfter,
  type DutyEvent,
} from "../../packages/attendance/src/engine.js";
const at = (seconds: number) =>
  new Date(Date.UTC(2026, 8, 20, 23, 59) + seconds * 1000).toISOString();
const event = (
  id: string,
  kind: string,
  t: number,
  observation?: DutyEvent["observation"],
): DutyEvent => ({
  id,
  kind,
  effectiveAt: at(t),
  status: "accepted",
  observation,
});
const policy = { gapSeconds: 60, maxSessionHours: 12 };
test("unknown sample immediately replaces earlier inside evidence; no inferred absence", () => {
  const p = projectDuty(
    [
      event("a", "IN", 0, "inside"),
      event("b", "LOCATION", 20, "unknown"),
      event("c", "OUT", 90, "inside"),
    ],
    at(100),
    policy,
  );
  assert.equal(p.segments[0]?.kind, "office");
  assert.equal(p.segments[0]?.endsAt, at(20));
  assert.ok(p.segments.slice(1).every((s) => s.kind === "unknown"));
  assert.equal(
    p.segments.reduce(
      (n, s) => n + Date.parse(s.endsAt) - Date.parse(s.startsAt),
      0,
    ),
    90000,
  );
  assert.equal(p.open, false);
});
test("overnight projection retains gaps and non-overlapping independent adjustments", () => {
  const p = projectDuty(
    [event("a", "IN", 0, "inside"), event("b", "OUT", 3600)],
    at(4000),
    policy,
    [{ id: "review", startsAt: at(120), endsAt: at(180), kind: "field" }],
  );
  assert.ok(p.segments.some((s) => s.kind === "unknown"));
  assert.ok(
    p.segments.some((s) => s.kind === "field" && s.sourceIds[0] === "review"),
  );
  for (let i = 1; i < p.segments.length; i++)
    assert.equal(p.segments[i - 1]!.endsAt, p.segments[i]!.startsAt);
  assert.equal(p.segments.at(-1)?.endsAt, at(3600));
});
test("missed exit caps projection, pending clock anomalies do not rewrite evidence", () => {
  const p = projectDuty(
    [
      event("a", "IN", 0, "inside"),
      { ...event("bad", "OUT", 100), status: "pending_verification" },
    ],
    at(72000),
    policy,
  );
  assert.equal(p.open, true);
  assert.equal(p.segments.at(-1)?.endsAt, at(43200));
  assert.ok(p.gaps.includes("Raw events await verification"));
});
test("visit and break state machine prevents nested arrivals, orphan exits and closing active visits", () => {
  assert.equal(stateAfter(["IN", "FIELD_START", "VISIT_END"]), null);
  assert.equal(
    stateAfter(["IN", "FIELD_START", "VISIT_START", "VISIT_START"]),
    null,
  );
  assert.equal(
    stateAfter(["IN", "FIELD_START", "VISIT_START", "FIELD_END"]),
    null,
  );
  assert.equal(
    stateAfter(["IN", "FIELD_START", "BREAK_START", "BREAK_END"]),
    "field",
  );
  assert.equal(
    stateAfter([
      "IN",
      "FIELD_START",
      "VISIT_START",
      "VISIT_END",
      "FIELD_END",
      "OUT",
    ]),
    "off",
  );
});
