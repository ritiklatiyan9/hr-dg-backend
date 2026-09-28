import { test } from "node:test";
import assert from "node:assert/strict";
import { randomBytes } from "node:crypto";
import {
  passwordHash,
  passwordValid,
  encrypt,
  decrypt,
  token,
  digest,
} from "../../apps/api/src/security.js";
import { workDate, requireActor } from "../../packages/authz/src/index.js";
import { ScopeBoundary, scopeKey } from "../../apps/hr-web/src/scope.js";
test("password hashes are salted and verify without plaintext persistence", async () => {
  const secret = token(),
    one = await passwordHash(secret),
    two = await passwordHash(secret);
  assert.notEqual(one, two);
  assert.ok(await passwordValid(secret, one));
  assert.equal(await passwordValid("wrong", one), false);
  assert.equal(await passwordValid(secret, null), false);
});
test("encrypted MFA and mail payloads reject tampering and wrong keys", () => {
  const key = randomBytes(32).toString("hex");
  const value = encrypt("private", key);
  assert.equal(decrypt(value, key), "private");
  assert.throws(() => decrypt(value, randomBytes(32).toString("hex")));
  assert.throws(() => decrypt(value.slice(0, -5), key));
});
test("site calendar dates follow timezone around UTC midnight", () => {
  assert.equal(
    workDate(new Date("2026-01-01T19:00:00Z"), "Asia/Kolkata"),
    "2026-01-02",
  );
  assert.equal(workDate(new Date("2026-01-01T19:00:00Z"), "UTC"), "2026-01-01");
});
test("absent actors and incomplete privileged MFA fail closed", () => {
  assert.throws(() => requireActor(null));
  assert.throws(() =>
    requireActor({
      id: "a",
      organizationId: "o",
      permissionVersion: 1,
      sessionId: "s",
      kind: "web",
      csrfHash: "x",
      requiresMfa: true,
      mfaVerified: false,
    }),
  );
});
test("site switch aborts old reads and rejects late responses", async () => {
  const scope = new ScopeBoundary();
  const old = scope.ticket();
  let resolve!: (value: string) => void;
  const slow = new Promise<string>((r) => (resolve = r));
  scope.change();
  const next = scope.ticket();
  resolve("Defence Garden private data");
  await slow;
  assert.equal(old.signal.aborted, true);
  assert.equal(old.isCurrent(), false);
  assert.equal(next.isCurrent(), true);
  old.release();
  next.release();
});
test("scope keys vary by organization actor site and access version; tabs stay independent", () => {
  const base = scopeKey("o", "a", 1, "dg");
  for (const key of [
    scopeKey("o2", "a", 1, "dg"),
    scopeKey("o", "b", 1, "dg"),
    scopeKey("o", "a", 2, "dg"),
    scopeKey("o", "a", 1, "rg"),
  ])
    assert.notDeepEqual(base, key);
  const tabA = new ScopeBoundary(),
    tabB = new ScopeBoundary(),
    readB = tabB.ticket();
  tabA.change();
  assert.equal(readB.isCurrent(), true);
});
test("opaque session identifiers have independent hashes", () => {
  assert.notEqual(digest(token()), digest(token()));
});
