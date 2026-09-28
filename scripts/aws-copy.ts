import { createHash } from "node:crypto";
import { spawn } from "node:child_process";
import { createReadStream } from "node:fs";
import {
  chmod,
  mkdir,
  mkdtemp,
  readFile,
  rm,
  writeFile,
} from "node:fs/promises";
import { resolve, join } from "node:path";
import { parseEnv } from "node:util";
import pg from "pg";
import { cloudDatabase } from "../packages/config/src/cloud.js";
import { assertRuntimeRole, pool } from "../packages/db/src/index.js";

const command = process.argv[2];
const option = (key: string) =>
  process.argv.find((v) => v.startsWith(`--${key}=`))?.slice(key.length + 3);
const directory = resolve(option("archive") ?? ".local/aws-rds/copy");
const quote = (v: string) => `"${v.replaceAll('"', '""')}"`;
const required = (e: Record<string, string | undefined>, key: string) => {
  if (!e[key]) throw new Error(`${key} is required`);
  return e[key]!;
};
async function digest(file: string) {
  const hash = createHash("sha256");
  for await (const chunk of createReadStream(file)) hash.update(chunk);
  return hash.digest("hex");
}
async function run(binary: string, args: string[], url: string) {
  const connection = new URL(url);
  if (!["postgres:", "postgresql:"].includes(connection.protocol))
    throw new Error("PostgreSQL connection URL required");
  const subprocessEnv = {
    PATH: process.env.PATH,
    PGHOST: connection.hostname,
    PGPORT: connection.port || "5432",
    PGDATABASE: decodeURIComponent(connection.pathname.slice(1)),
    PGUSER: decodeURIComponent(connection.username),
    PGPASSWORD: decodeURIComponent(connection.password),
    PGCONNECT_TIMEOUT: "10",
    ...(connection.searchParams.get("sslmode")
      ? { PGSSLMODE: connection.searchParams.get("sslmode")! }
      : {}),
    ...(connection.searchParams.get("sslrootcert")
      ? { PGSSLROOTCERT: connection.searchParams.get("sslrootcert")! }
      : {}),
  };
  await new Promise<void>((done, reject) => {
    // No credentials in argv, terminal output, shell expansion or driver diagnostics.
    const child = spawn(join(process.env.PG_BIN ?? "", binary), args, {
      env: subprocessEnv,
      stdio: "ignore",
    });
    child.once("error", () =>
      reject(new Error(`${binary} could not start; configure PG_BIN`)),
    );
    child.once("exit", (code) =>
      code === 0
        ? done()
        : reject(new Error(`${binary} failed; raw database output suppressed`)),
    );
  });
}
async function counts(client: pg.Client) {
  const tables = (
    await client.query<{
      schema: string;
      name: string;
    }>(`SELECT n.nspname AS schema,c.relname AS name
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relkind='r' AND (n.nspname IN ('app','auth') OR (n.nspname='public' AND c.relname='schema_migrations'))
    ORDER BY n.nspname,c.relname`)
  ).rows;
  const result: Record<string, string> = {};
  for (const t of tables)
    result[`${t.schema}.${t.name}`] = (
      await client.query(
        `SELECT count(*)::text AS n FROM ${quote(t.schema)}.${quote(t.name)}`,
      )
    ).rows[0].n;
  if (!result["public.schema_migrations"] || !result["auth.users"])
    throw new Error("Expected HR schema and migration ledger are missing");
  return result;
}
async function security(client: pg.Client) {
  return (
    await client.query(`SELECT n.nspname AS schema,c.relname AS name,c.relrowsecurity AS rls,
    c.relforcerowsecurity AS force_rls,(SELECT count(*)::int FROM pg_policy p WHERE p.polrelid=c.oid) AS policies
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE c.relkind='r' AND n.nspname IN ('app','auth') ORDER BY n.nspname,c.relname`)
  ).rows;
}
async function backup() {
  if (!process.argv.includes("--writers-stopped"))
    throw new Error(
      "Stop source API/worker writes and pass --writers-stopped for a final copy",
    );
  const source = parseEnv(
    await readFile(option("source-env") ?? ".env", "utf8"),
  );
  const url = required(source, "MIGRATION_DATABASE_URL");
  const key = required(source, "ENCRYPTION_KEY");
  if (!/^[0-9a-f]{64}$/.test(key))
    throw new Error("Original encryption key is invalid");
  const client = new pg.Client({
    connectionString: url,
    connectionTimeoutMillis: 8000,
  });
  await client.connect();
  try {
    await client.query("BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY");
    const snapshot = (await client.query("SELECT pg_export_snapshot() AS id"))
      .rows[0].id;
    const version = (await client.query("SHOW server_version_num")).rows[0]
      .server_version_num;
    const tableCounts = await counts(client);
    const tableSecurity = await security(client);
    // Exclusive directory creation refuses to overwrite a previous backup.
    await mkdir(resolve(directory, ".."), { recursive: true, mode: 0o700 });
    await mkdir(directory, { mode: 0o700 });
    await chmod(directory, 0o700);
    for (const [name, selection] of [
      ["application.dump", ["--schema=app", "--schema=auth"]],
      ["migrations.dump", ["--table=public.schema_migrations"]],
    ] as const) {
      await writeFile(join(directory, name), "", { mode: 0o600, flag: "wx" });
      await run(
        "pg_dump",
        [
          "--format=custom",
          "--no-owner",
          `--snapshot=${snapshot}`,
          `--file=${join(directory, name)}`,
          ...selection,
        ],
        url,
      );
      await chmod(join(directory, name), 0o600);
    }
    const hashes = Object.fromEntries(
      await Promise.all(
        ["application.dump", "migrations.dump"].map(async (file) => [
          file,
          await digest(join(directory, file)),
        ]),
      ),
    );
    await writeFile(
      join(directory, "source-key.env"),
      `ENCRYPTION_KEY=${key}\n`,
      { mode: 0o600, flag: "wx" },
    );
    await writeFile(
      join(directory, "manifest.json"),
      JSON.stringify({
        version: 1,
        createdAt: new Date().toISOString(),
        serverVersion: Number(version),
        hashes,
        counts: tableCounts,
        security: tableSecurity,
      }),
      { mode: 0o600, flag: "wx" },
    );
    await client.query("COMMIT");
    console.log(
      "Backup complete: snapshot-consistent application schema, data, grants, migration ledger and original key. Files are private; source was read-only.",
    );
  } finally {
    await client.end();
  }
}
async function target(restore: boolean) {
  const url = required(process.env, "MIGRATION_DATABASE_URL");
  const parsed = cloudDatabase(url, "MIGRATION_DATABASE_URL");
  if (!parsed.hostname.endsWith(".rds.amazonaws.com"))
    throw new Error("Target must be the reviewed RDS endpoint");
  if (option("target") !== decodeURIComponent(parsed.pathname.slice(1)))
    throw new Error("Pass --target= with the exact destination database name");
  if (
    ["postgres", "template0", "template1", "hr_local", "hr_test"].includes(
      option("target")!,
    )
  )
    throw new Error("Refusing a system or local database target");
  const manifest = JSON.parse(
    await readFile(join(directory, "manifest.json"), "utf8"),
  );
  if (manifest.version !== 1) throw new Error("Unsupported manifest version");
  for (const file of ["application.dump", "migrations.dump"])
    if ((await digest(join(directory, file))) !== manifest.hashes[file])
      throw new Error("Archive checksum mismatch");
  const client = new pg.Client({
    connectionString: url,
    connectionTimeoutMillis: 8000,
  });
  await client.connect();
  try {
    if (restore) {
      if (!process.argv.includes("--writers-stopped"))
        throw new Error(
          "Keep source and target writers stopped and pass --writers-stopped",
        );
      const existing =
        await client.query(`SELECT 1 FROM pg_namespace WHERE nspname IN ('app','auth')
        UNION ALL SELECT 1 FROM pg_class WHERE oid=to_regclass('public.schema_migrations')`);
      if (existing.rowCount)
        throw new Error(
          "Target is not empty; refusing to overwrite or merge HR data",
        );
      const version = Number(
        (await client.query("SHOW server_version_num")).rows[0]
          .server_version_num,
      );
      if (version < manifest.serverVersion)
        throw new Error("Target PostgreSQL must not be older than the source");
      const extensions = (
        await client.query(
          "SELECT extname FROM pg_extension WHERE extname IN ('postgis','pgcrypto','btree_gist')",
        )
      ).rows;
      if (extensions.length !== 3)
        throw new Error("Run aws:db:prepare-copy before restoring");
      // Restore both archives through one psql transaction. ACLs are retained; all
      // objects are owned by the migration account, never an application role.
      const sqlDirectory = await mkdtemp(join(directory, "restore-"));
      try {
        for (const file of ["application", "migrations"]) {
          await writeFile(join(sqlDirectory, `${file}.sql`), "", {
            mode: 0o600,
            flag: "wx",
          });
          await run(
            "pg_restore",
            [
              "--no-owner",
              `--file=${join(sqlDirectory, `${file}.sql`)}`,
              join(directory, `${file}.dump`),
            ],
            url,
          );
        }
        await run(
          "psql",
          [
            "-X",
            "--single-transaction",
            "--set=ON_ERROR_STOP=1",
            `--file=${join(sqlDirectory, "application.sql")}`,
            `--file=${join(sqlDirectory, "migrations.sql")}`,
          ],
          url,
        );
      } finally {
        await rm(sqlDirectory, { recursive: true, force: true });
      }
    }
    await client.query("BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY");
    const actual = await counts(client);
    if (JSON.stringify(actual) !== JSON.stringify(manifest.counts))
      throw new Error(
        "Table counts differ; keep deployment paused and investigate",
      );
    if (
      JSON.stringify(await security(client)) !==
      JSON.stringify(manifest.security)
    )
      throw new Error("RLS flags or policy counts differ from source");
    const unsafe =
      await client.query(`SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname IN ('app','auth') AND c.relkind='r' AND
      c.relowner IN (SELECT oid FROM pg_roles WHERE rolname IN ('hr_runtime','hr_auth','hr_worker'))`);
    if (unsafe.rowCount)
      throw new Error("Restored table ownership or RLS check failed");
    const exposed =
      await client.query(`SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='app' AND c.relkind='r' AND has_table_privilege('hr_auth',c.oid,'SELECT')`);
    if (exposed.rowCount)
      throw new Error("Authentication role can read business tables");
    await client.query("ROLLBACK");
    const aws = parseEnv(await readFile(".env.aws", "utf8"));
    const sourceKey = parseEnv(
      await readFile(join(directory, "source-key.env"), "utf8"),
    );
    if (aws.ENCRYPTION_KEY !== sourceKey.ENCRYPTION_KEY)
      throw new Error(
        "Set .env.aws ENCRYPTION_KEY to the preserved source-key.env value before deploying",
      );
    for (const [role, key] of [
      ["hr_runtime", "RUNTIME_DB_PASSWORD"],
      ["hr_auth", "AUTH_DB_PASSWORD"],
      ["hr_worker", "WORKER_DB_PASSWORD"],
    ]) {
      const runtimeUrl = new URL(url);
      runtimeUrl.username = role!;
      runtimeUrl.password = required(aws, key!);
      const runtime = pool(runtimeUrl.toString(), 1);
      try {
        await assertRuntimeRole(runtime, role!);
      } finally {
        await runtime.end();
      }
    }
    console.log(
      "PASS: archive hashes, all table counts, RLS, ownership, auth isolation, role logins and original encryption key. No record contents printed.",
    );
  } finally {
    await client.end();
  }
}
try {
  if (command === "backup") await backup();
  else if (command === "restore" || command === "verify")
    await target(command === "restore");
  else
    throw new Error(
      "Usage: aws-copy.ts backup|restore|verify [--archive=path] [--target=database] [--writers-stopped]",
    );
} catch (error) {
  // Driver errors may contain row values; report only our explicit operator errors.
  const message =
    error instanceof Error && !("code" in error) && !("query" in error)
      ? error.message
      : "Database or filesystem operation failed; check connectivity, credentials and private archive files";
  console.error(message);
  process.exitCode = 1;
}
