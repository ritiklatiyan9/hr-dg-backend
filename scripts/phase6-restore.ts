import { fixture } from "../tests/integration/fixture.js";
import { pool, scoped, assertRuntimeRole } from "../packages/db/src/index.js";
import { ids } from "../packages/db/src/seed.js";
import { randomBytes, createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { mkdir, writeFile } from "node:fs/promises";
import assert from "node:assert/strict";

// The fixture refuses non-loopback or non-hr_test control databases.
const f = await fixture("restore"),
  control = pool(process.env.TEST_MIGRATION_DATABASE_URL!, 1);
const restoreName = `hr_test_${randomBytes(8).toString("hex")}`;
let restored: ReturnType<typeof pool> | undefined,
  runtime: ReturnType<typeof pool> | undefined;
try {
  const container = execFileSync(
    "docker",
    [
      "compose",
      "--env-file",
      ".env",
      "-f",
      "infra/compose.yaml",
      "ps",
      "-q",
      "postgres",
    ],
    { encoding: "utf8" },
  ).trim();
  assert.match(container, /^[a-f0-9]+$/);
  const markerAt = new Date().toISOString();
  await f.owner.query(
    "UPDATE app.employees SET display_name='Restore drill marker' WHERE id=$1",
    [ids.employeeProfile],
  );
  const started = performance.now();
  const archive = execFileSync(
    "docker",
    ["exec", container, "pg_dump", "-U", "postgres", "-Fc", f.dbName],
    { maxBuffer: 32 * 1024 * 1024 },
  );
  const dumpMs = performance.now() - started;
  await control.query(`CREATE DATABASE ${restoreName}`);
  const restoreStart = performance.now();
  execFileSync(
    "docker",
    [
      "exec",
      "-i",
      container,
      "pg_restore",
      "-U",
      "postgres",
      "--exit-on-error",
      "-d",
      restoreName,
    ],
    { input: archive, maxBuffer: 1024 * 1024 },
  );
  const restoreMs = performance.now() - restoreStart;
  const url = (base: string) => {
    const u = new URL(base);
    u.pathname = `/${restoreName}`;
    return u.toString();
  };
  restored = pool(url(process.env.TEST_MIGRATION_DATABASE_URL!), 1);
  runtime = pool(url(process.env.TEST_DATABASE_URL!), 1);
  const counts = async (db: ReturnType<typeof pool>) =>
    (
      await db.query(
        "SELECT (SELECT count(*) FROM app.employees)::int employees,(SELECT count(*) FROM auth.users)::int users,(SELECT count(*) FROM app.access_overrides)::int overrides,(SELECT count(*) FROM app.sites)::int sites",
      )
    ).rows[0];
  assert.deepEqual(await counts(restored), await counts(f.owner));
  assert.equal(
    (
      await restored.query(
        "SELECT display_name FROM app.employees WHERE id=$1",
        [ids.employeeProfile],
      )
    ).rows[0].display_name,
    "Restore drill marker",
  );
  await assertRuntimeRole(runtime, "hr_runtime");
  const { actor } = await f.login("employee@example.test");
  const visible = await scoped(
    runtime,
    actor,
    ids.dg,
    async (c) => (await c.query("SELECT id FROM app.employees")).rows,
  );
  assert.deepEqual(
    visible.map((x) => x.id),
    [ids.employeeProfile],
  );
  assert.equal(
    (await runtime.query("SELECT count(*)::int n FROM app.employees")).rows[0]
      .n,
    0,
  );
  const report = {
    at: new Date().toISOString(),
    environment: "Local Docker PostGIS, isolated synthetic fixture only",
    archiveBytes: archive.length,
    sha256: createHash("sha256").update(archive).digest("hex"),
    markerAt,
    dumpMs,
    restoreMs,
    verifiedCounts: await counts(restored),
    checks: [
      "schema/data restored",
      "committed marker recovered",
      "runtime non-owner / non-BYPASSRLS",
      "own-record RLS preserved",
      "pooled connection has no residual scope",
    ],
    result: "PASS",
    limitation:
      "In-memory logical snapshot; not PITR, object-storage restore, cloud failover or production RPO/RTO. Archive is discarded when this process exits.",
  };
  await mkdir("docs/evidence/phase6", { recursive: true });
  await writeFile(
    "docs/evidence/phase6/restore.json",
    JSON.stringify(report, null, 2),
  );
  console.log(JSON.stringify(report, null, 2));
} finally {
  await runtime?.end();
  await restored?.end();
  await control.query(`DROP DATABASE IF EXISTS ${restoreName}`);
  await control.end();
  await f.close();
}
