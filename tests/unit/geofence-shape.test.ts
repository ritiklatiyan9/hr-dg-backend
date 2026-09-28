import { test } from "node:test";
import assert from "node:assert/strict";
import { boundary, circle } from "../../apps/hr-web/src/geofence-shape.js";

test("circle is a closed ring whose area is close to pi r^2", () => {
  const ring = circle([77.209, 28.6139], 100);
  assert.deepEqual(ring[0], ring.at(-1));
  // Shoelace area in metres around the centre latitude.
  const k = 111320,
    c = Math.cos((28.6139 * Math.PI) / 180);
  let a = 0;
  for (let i = 0; i < ring.length - 1; i++) {
    const [x1, y1] = ring[i]!,
      [x2, y2] = ring[i + 1]!;
    a += x1 * k * c * (y2 * k) - x2 * k * c * (y1 * k);
  }
  const area = Math.abs(a) / 2;
  assert.ok(Math.abs(area - Math.PI * 100 ** 2) / (Math.PI * 100 ** 2) < 0.01);
});
test("boundary needs one centre or three corners and closes polygons", () => {
  assert.equal(boundary([], 100), null);
  assert.equal(
    boundary(
      [
        [1, 1],
        [2, 2],
      ],
      100,
    ),
    null,
  );
  assert.equal(boundary([[77, 28]], 50)!.length, 33);
  assert.deepEqual(
    boundary(
      [
        [0, 0],
        [0, 1],
        [1, 1],
      ],
      100,
    ),
    [
      [0, 0],
      [0, 1],
      [1, 1],
      [0, 0],
    ],
  );
});
