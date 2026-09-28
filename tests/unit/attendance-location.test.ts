import { test } from "node:test";
import assert from "node:assert/strict";
import { verifiedInside } from "../../apps/hr-web/src/attendance-location.js";
const now = Date.parse("2026-09-26T10:00:00Z");
const rules = { maxAccuracyM: 100, freshnessSeconds: 60 };
const fence = {
  type: "Polygon",
  coordinates: [
    [
      [77.19, 28.59],
      [77.21, 28.59],
      [77.21, 28.61],
      [77.19, 28.61],
      [77.19, 28.59],
    ],
  ],
};
const fix = {
  latitude: 28.6,
  longitude: 77.2,
  accuracyM: 10,
  observedAt: new Date(now).toISOString(),
  mocked: false,
};
test("reason prompt distinguishes safely inside from outside and boundary uncertainty", () => {
  assert.equal(verifiedInside(fence, fix, rules, now), true);
  for (const location of [
    undefined,
    { ...fix, longitude: 78 },
    { ...fix, longitude: 77.19001 },
    { ...fix, accuracyM: 101 },
    { ...fix, mocked: true },
    { ...fix, observedAt: new Date(now - 16000).toISOString() },
  ])
    assert.equal(verifiedInside(fence, location, rules, now), false);
  assert.equal(verifiedInside(null, fix, rules, now), false);
  assert.equal(
    verifiedInside(
      { ...fence, coordinates: [...fence.coordinates, fence.coordinates[0]] },
      fix,
      rules,
      now,
    ),
    false,
  );
});
