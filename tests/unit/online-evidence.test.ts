import { test } from "node:test";
import assert from "node:assert/strict";
import { onlineEvidenceTimely } from "../../packages/attendance/src/online-evidence.js";

test("online photo upload time does not turn a fresh capture into a delayed event", () => {
  const capture = Date.parse("2026-09-29T06:00:00Z");
  assert.equal(
    onlineEvidenceTimely(capture, capture + 90_000, capture + 2_000, 5),
    true,
  );
  assert.equal(onlineEvidenceTimely(capture, capture + 4_000, null, 5), true);
});

test("old intent, long upload, and offline replay still require review", () => {
  const capture = Date.parse("2026-09-29T06:00:00Z");
  assert.equal(onlineEvidenceTimely(capture, capture + 90_000, null, 5), false);
  assert.equal(
    onlineEvidenceTimely(capture, capture + 90_000, capture + 6_000, 5),
    false,
  );
  assert.equal(
    onlineEvidenceTimely(capture, capture + 301_000, capture, 5),
    false,
  );
  assert.equal(
    onlineEvidenceTimely(capture, capture + 90_000, capture + 91_000, 5),
    false,
  );
});
