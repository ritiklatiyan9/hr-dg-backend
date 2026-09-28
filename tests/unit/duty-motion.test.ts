import { test } from "node:test";
import assert from "node:assert/strict";
import {
  DutyMotion,
  motionPlan,
  turn,
  type MotionFix,
  type Position,
} from "../../apps/hr-web/src/duty-motion.js";

const instant = 1800000000000;
const iso = (offset: number) => new Date(instant + offset).toISOString();
const fix = (offset: number, longitude = 77.2): MotionFix => ({
  latitude: 28.6,
  longitude,
  accuracy_m: 5,
  status: "fresh",
  observed_at: iso(offset),
  received_at: iso(offset + 1000),
});
function harness() {
  let time = 0,
    seq = 0;
  const pending = new Map<number, (time: number) => void>();
  const frames: { position: Position; bearing?: number; moving: boolean }[] =
    [];
  const animator = new DutyMotion({
    now: () => time,
    request: (callback) => {
      pending.set(++seq, callback);
      return seq;
    },
    cancel: (id) => {
      pending.delete(id);
    },
  });
  const render = (
    position: Position,
    bearing: number | undefined,
    moving: boolean,
  ) => frames.push({ position, bearing, moving });
  return {
    animator,
    frames,
    pending,
    render,
    step(next: number) {
      time = next;
      const work = [...pending.values()];
      pending.clear();
      for (const frame of work) frame(time);
    },
    update(point: MotionFix, animate = true, key = "employee") {
      animator.update(
        key,
        point,
        render,
        animate,
        Date.parse(point.observed_at) + 1000,
      );
    },
  };
}
test("marker glides between known endpoints, stops exactly, and never extrapolates", () => {
  const h = harness();
  h.update(fix(0));
  h.update(fix(30000, 77.201));
  assert.equal(h.pending.size, 1);
  h.step(1000);
  const mid = h.frames.at(-1)!;
  assert.ok(mid.position[1] > 77.2 && mid.position[1] < 77.201);
  assert.equal(mid.moving, true);
  assert.ok(Math.abs(mid.bearing! - 90) < 0.1);
  h.step(3000);
  assert.deepEqual(h.frames.at(-1)!.position, [28.6, 77.201]);
  assert.equal(h.frames.at(-1)!.moving, false);
  assert.equal(h.pending.size, 0);
  const count = h.frames.length;
  h.step(60000);
  assert.equal(h.frames.length, count);
});
test("mid-flight retarget starts at rendered position and duplicate refresh does not restart", () => {
  const h = harness();
  h.update(fix(0));
  h.update(fix(15000, 77.201));
  h.step(500);
  const from = h.frames.at(-1)!.position;
  h.update(fix(30000, 77.202));
  assert.deepEqual(h.frames.at(-1)!.position, from);
  assert.equal(h.pending.size, 1);
  h.step(1400);
  h.update(fix(30000, 77.202));
  h.step(3000);
  assert.equal(h.frames.at(-1)!.moving, false);
  assert.deepEqual(h.frames.at(-1)!.position, [28.6, 77.202]);
});
test("stale, delayed, imprecise, old, implausible and noise-sized updates do not animate", () => {
  const a = fix(0),
    b = fix(30000, 77.201),
    now = instant + 31000;
  for (const changed of [
    { ...b, status: "stale" },
    { ...b, status: "off_duty" },
    { ...b, received_at: iso(120000) },
    { ...b, received_at: undefined },
    { ...b, accuracy_m: 200 },
    { ...b, accuracy_m: NaN },
    { ...b, observed_at: iso(0) },
    { ...b, observed_at: iso(-1) },
    { ...b, longitude: 78 },
    { ...b, longitude: 77.20000001 },
  ])
    assert.equal(motionPlan(a, changed, now).duration, 0);
  assert.equal(motionPlan(a, b, instant + 200000).duration, 0);
  assert.equal(
    motionPlan(a, fix(150000, 77.201), instant + 150000).duration,
    0,
  );
  assert.equal(motionPlan(a, fix(1000, 77.215), instant + 1000).duration, 0);
});
test("one scheduler serves multiple employees; hide, reduced motion, removal and disposal cancel it", () => {
  const h = harness();
  for (const key of ["one", "two"]) {
    h.update(fix(0), true, key);
    h.update(fix(30000, 77.201), true, key);
  }
  assert.equal(h.pending.size, 1);
  h.animator.settle();
  assert.equal(h.pending.size, 0);
  assert.deepEqual(h.frames.at(-1)!.position, [28.6, 77.201]);
  h.update(fix(60000, 77.202), false, "one");
  assert.equal(h.pending.size, 0);
  h.update(fix(90000, 77.203), true, "one");
  h.animator.remove("one");
  assert.equal(h.pending.size, 0);
  h.update(fix(60000, 77.202), true, "two");
  h.animator.dispose();
  assert.equal(h.pending.size, 0);
});
test("out-of-order responses cannot rewind; fresh-to-stale stops active motion", () => {
  const h = harness();
  h.update(fix(0));
  h.update(fix(30000, 77.201));
  h.step(500);
  const p = h.frames.at(-1)!.position;
  h.update(fix(0));
  assert.deepEqual(h.frames.at(-1)!.position, p);
  h.update({ ...fix(30000, 77.201), status: "stale" });
  assert.equal(h.pending.size, 0);
  assert.deepEqual(h.frames.at(-1)!.position, [28.6, 77.201]);
  assert.equal(turn(359, 1), 2);
  assert.equal(turn(1, 359), -2);
});
