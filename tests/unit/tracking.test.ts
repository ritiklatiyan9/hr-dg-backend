import { test } from "node:test";
import assert from "node:assert/strict";
import { trackingStatus } from "../../packages/attendance/src/tracking.js";
test("live status never represents an old, future, missing or off-duty sample as current", () => {
  const base = {
    enabled: true,
    eligible: true,
    now: 1000000,
    staleSeconds: 60,
  };
  assert.equal(
    trackingStatus({ ...base, observedAt: new Date(990000) }),
    "fresh",
  );
  assert.equal(
    trackingStatus({ ...base, observedAt: new Date(930000) }),
    "stale",
  );
  assert.equal(
    trackingStatus({ ...base, observedAt: new Date(1100000) }),
    "stale",
  );
  assert.equal(trackingStatus({ ...base, observedAt: "invalid" }), "stale");
  assert.equal(trackingStatus(base), "missing");
  assert.equal(trackingStatus({ ...base, eligible: false }), "off_duty");
  assert.equal(trackingStatus({ ...base, enabled: false }), "disabled");
});
test("a connected phone without a new fix is idle, not lost; location-off is reported", () => {
  const base = {
    enabled: true,
    eligible: true,
    now: 1000000,
    staleSeconds: 60,
    observedAt: new Date(700000),
  };
  assert.equal(trackingStatus({ ...base, seenAt: new Date(990000) }), "idle");
  assert.equal(trackingStatus({ ...base, seenAt: new Date(930000) }), "stale");
  assert.equal(trackingStatus({ ...base, seenAt: "invalid" }), "stale");
  assert.equal(
    trackingStatus({ ...base, seenAt: new Date(990000), locationOff: true }),
    "location_off",
  );
  // An old location-off report does not hide a later loss of contact.
  assert.equal(
    trackingStatus({ ...base, seenAt: new Date(930000), locationOff: true }),
    "stale",
  );
  assert.equal(
    trackingStatus({
      ...base,
      observedAt: new Date(995000),
      seenAt: new Date(995000),
    }),
    "fresh",
  );
  assert.equal(
    trackingStatus({ ...base, observedAt: null, seenAt: new Date(990000) }),
    "missing",
  );
  assert.equal(
    trackingStatus({ ...base, eligible: false, seenAt: new Date(990000) }),
    "off_duty",
  );
});
