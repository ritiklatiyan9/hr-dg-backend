import { chmod, mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import pg from "pg";
import { assertRuntimeRole, pool } from "../packages/db/src/index.js";
import { migrate } from "../packages/db/src/migrate.js";
import { validateCloudEnvironment } from "../packages/config/src/cloud.js";

const command = process.argv[2];
if (
  !new Set([
    "check",
    "render",
    "render-cloud",
    "prepare-copy",
    "provision",
  ]).has(command ?? "")
)
  throw new Error(
    "Usage: aws-rds.ts <check|render|render-cloud|prepare-copy|provision>",
  );

const required = (name: string) => {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`${name} is required in .env.aws`);
  return value;
};
const host = required("AWS_RDS_HOST");
if (!/^[a-z0-9.-]+\.rds\.amazonaws\.com$/.test(host))
  throw new Error("AWS_RDS_HOST must be an Amazon RDS endpoint hostname");
const port = Number(process.env.AWS_RDS_PORT ?? "5432");
if (!Number.isInteger(port) || port < 1 || port > 65535)
  throw new Error("AWS_RDS_PORT must be a valid port");
const adminDatabase = required("AWS_RDS_ADMIN_DATABASE");
const applicationDatabase = required("AWS_RDS_DATABASE");
if (!/^[a-z][a-z0-9_]{0,62}$/.test(applicationDatabase))
  throw new Error(
    "AWS_RDS_DATABASE must be a simple lowercase PostgreSQL identifier",
  );
if (
  ["postgres", "template0", "template1", "hr_local", "hr_test"].includes(
    applicationDatabase,
  )
)
  throw new Error("AWS_RDS_DATABASE must be a dedicated application database");
const caPath = resolve(required("AWS_RDS_CA_FILE"));
const ca = await readFile(caPath, "utf8").catch(() => {
  throw new Error("RDS CA bundle missing; run npm run aws:rds:ca first");
});
if (!ca.includes("-----BEGIN CERTIFICATE-----"))
  throw new Error("AWS_RDS_CA_FILE does not contain a PEM certificate");

const adminUser = required("AWS_RDS_ADMIN_USER");
// Rendering runtime secrets never requires the RDS master password.
const adminPassword = ["render", "render-cloud"].includes(command ?? "")
  ? ""
  : required("AWS_RDS_ADMIN_PASSWORD");
const connection = (database: string, user: string, password: string) => ({
  host,
  port,
  database,
  user,
  password,
  ssl: { ca, rejectUnauthorized: true },
  connectionTimeoutMillis: 8_000,
  statement_timeout: 30_000,
  application_name: "defence-garden-hr-setup",
});
const url = (
  database: string,
  user: string,
  password: string,
  rootCert = caPath,
) => {
  const value = new URL("postgresql://placeholder");
  value.hostname = host;
  value.port = String(port);
  value.pathname = `/${applicationDatabase === database ? applicationDatabase : database}`;
  value.username = user;
  value.password = password;
  value.searchParams.set("sslmode", "verify-full");
  value.searchParams.set("sslrootcert", rootCert);
  return value.toString();
};

async function check() {
  const client = new pg.Client(
    connection(adminDatabase, adminUser, adminPassword),
  );
  await client.connect();
  try {
    await client.query("BEGIN READ ONLY");
    const { rows } = await client.query(`SELECT current_database() AS database,
      current_user AS user, current_setting('server_version') AS server_version,
      current_setting('rds.force_ssl', true) AS force_ssl,
      s.ssl, s.version AS tls_version, s.cipher,
      r.rolcreatedb, r.rolcreaterole,
      (SELECT default_version FROM pg_available_extensions WHERE name='postgis') AS postgis_available
      FROM pg_stat_ssl s JOIN pg_roles r ON r.rolname=current_user
      WHERE s.pid=pg_backend_pid()`);
    await client.query("ROLLBACK");
    const result = rows[0];
    if (!result?.ssl) throw new Error("RDS connection did not negotiate TLS");
    if (!result.postgis_available)
      throw new Error("RDS must support PostGIS for this application");
    console.log(
      JSON.stringify({ status: "connected-read-only", ...result }, null, 2),
    );
  } finally {
    await client.end();
  }
}

const roleNames = ["hr_runtime", "hr_auth", "hr_worker"] as const;
type RoleName = (typeof roleNames)[number];
const rolePassword = (role: RoleName) =>
  required(
    role === "hr_runtime"
      ? "RUNTIME_DB_PASSWORD"
      : role === "hr_auth"
        ? "AUTH_DB_PASSWORD"
        : "WORKER_DB_PASSWORD",
  );

async function roleSql(
  client: pg.Client,
  role: RoleName,
  password: string,
  alter: boolean,
) {
  const verb = alter ? "ALTER ROLE" : "CREATE ROLE";
  const suffix = alter
    ? "PASSWORD %L"
    : "LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS PASSWORD %L";
  const { rows } = await client.query(
    "SELECT format($1, $2::text, $3::text) AS sql",
    [`${verb} %I ${suffix}`, role, password],
  );
  await client.query(rows[0].sql);
}

function quoteIdentifier(value: string) {
  return `"${value.replaceAll('"', '""')}"`;
}

async function provision(copyOnly = false) {
  const client = new pg.Client(
    connection(adminDatabase, adminUser, adminPassword),
  );
  await client.connect();
  try {
    const rotate = process.env.AWS_RDS_ROTATE_APP_ROLE_PASSWORDS === "true";
    for (const role of roleNames) {
      const { rows } = await client.query(
        "SELECT rolsuper,rolcreatedb,rolcreaterole,rolinherit,rolreplication,rolbypassrls FROM pg_roles WHERE rolname=$1",
        [role],
      );
      if (!rows[0]) await roleSql(client, role, rolePassword(role), false);
      else {
        const r = rows[0];
        if (
          r.rolsuper ||
          r.rolcreatedb ||
          r.rolcreaterole ||
          r.rolinherit ||
          r.rolreplication ||
          r.rolbypassrls
        )
          throw new Error(
            `Existing ${role} has unsafe attributes; refusing to continue`,
          );
        if (rotate) await roleSql(client, role, rolePassword(role), true);
      }
    }
    const exists = await client.query(
      "SELECT 1 FROM pg_database WHERE datname=$1",
      [applicationDatabase],
    );
    if (!exists.rowCount)
      await client.query(
        `CREATE DATABASE ${quoteIdentifier(applicationDatabase)} TEMPLATE template0 ENCODING 'UTF8'`,
      );
  } finally {
    await client.end();
  }

  const migrationUrl = url(applicationDatabase, adminUser, adminPassword);
  if (copyOnly) {
    const target = new pg.Client(
      connection(applicationDatabase, adminUser, adminPassword),
    );
    await target.connect();
    try {
      const existing =
        await target.query(`SELECT 1 FROM pg_namespace WHERE nspname IN ('app','auth')
        UNION ALL SELECT 1 FROM pg_class WHERE oid=to_regclass('public.schema_migrations')`);
      if (existing.rowCount)
        throw new Error(
          "Copy target already contains application objects; refusing to change it",
        );
      await target.query(
        "CREATE EXTENSION IF NOT EXISTS pgcrypto; CREATE EXTENSION IF NOT EXISTS postgis; CREATE EXTENSION IF NOT EXISTS btree_gist; REVOKE ALL ON SCHEMA public FROM PUBLIC; GRANT USAGE ON SCHEMA public TO hr_runtime",
      );
    } finally {
      await target.end();
    }
    // Do not migrate/seed here: restore includes the original schema and ledger.
    await writeEnv(resolve(".local/aws-rds/migration.env"), {
      MIGRATION_DATABASE_URL: migrationUrl,
    });
    console.log(
      "Prepared empty RDS copy target and roles; no application schema or seed data written.",
    );
    return;
  }
  await migrate(migrationUrl);
  const checks = await Promise.all(
    roleNames.map(async (role) => {
      const p = pool(url(applicationDatabase, role, rolePassword(role)), 1);
      try {
        await assertRuntimeRole(p, role);
        return role;
      } finally {
        await p.end();
      }
    }),
  );
  await render();
  console.log(
    `Provisioned ${applicationDatabase}; verified ${checks.join(", ")}. No seed data was written.`,
  );
}

const envValue = (value: string) => {
  if (/[\r\n]/.test(value))
    throw new Error("Environment values cannot contain newlines");
  for (const quote of ['"', "'", "`"])
    if (!value.includes(quote)) return `${quote}${value}${quote}`;
  throw new Error(
    "Environment value contains every supported quote delimiter; set it directly in the service dashboard",
  );
};
const pick = (name: string, fallback = "") => process.env[name] ?? fallback;
async function writeEnv(path: string, entries: Record<string, string>) {
  await mkdir(dirname(path), { recursive: true, mode: 0o700 });
  const body = `${Object.entries(entries)
    .map(([key, value]) => `${key}=${envValue(value)}`)
    .join("\n")}\n`;
  await writeFile(path, body, { encoding: "utf8", mode: 0o600 });
  await chmod(path, 0o600);
}
async function render(cloud = false) {
  const runtimePassword = rolePassword("hr_runtime");
  const authPassword = rolePassword("hr_auth");
  const workerPassword = rolePassword("hr_worker");
  const output = resolve(cloud ? ".local/aws-rds/render" : ".local/aws-rds");
  const runtimeCa = cloud ? "/app/rds-ca.pem" : caPath;
  const shared = {
    ...(cloud ? { DEPLOYMENT_TARGET: "render-rds" } : {}),
    NODE_ENV: "production",
    ENCRYPTION_KEY: required("ENCRYPTION_KEY"),
    REDIS_URL: pick("REDIS_URL", "redis://localhost:6379"),
    S3_ENDPOINT: pick("S3_ENDPOINT"),
    S3_REGION: pick("S3_REGION", cloud ? "" : "ap-south-1"),
    S3_ACCESS_KEY: pick("S3_ACCESS_KEY"),
    S3_SECRET_KEY: pick("S3_SECRET_KEY"),
    S3_BUCKET: pick("S3_BUCKET", cloud ? "" : "hr-private"),
  };
  // The DWR agent runs in the worker; the API keeps the key for analytics only.
  const agent = Object.fromEntries(
    [
      "OPENROUTER_API_KEY",
      "OPENROUTER_DWR_MODEL",
      "OPENROUTER_DWR_PROVIDER",
      "DWR_AGENT_USER_DAILY_CALLS",
      "DWR_AGENT_ORG_DAILY_CALLS",
    ].map((key) => [key, pick(key)]),
  );
  const api = {
    ...shared,
    OPENROUTER_API_KEY: pick("OPENROUTER_API_KEY"),
    PORT: pick("PORT", "4000"),
    WEB_ORIGIN: required("WEB_ORIGIN"),
    COOKIE_SECURE: "true",
    SERVE_WEB: "true",
    DATABASE_URL: url(
      applicationDatabase,
      "hr_runtime",
      runtimePassword,
      runtimeCa,
    ),
    AUTH_DATABASE_URL: url(
      applicationDatabase,
      "hr_auth",
      authPassword,
      runtimeCa,
    ),
    LOGIN_ORGANIZATION_ID: required("LOGIN_ORGANIZATION_ID"),
    CLAMAV_HOST: pick("CLAMAV_HOST"),
    CLAMAV_PORT: pick("CLAMAV_PORT", "3310"),
    ...Object.fromEntries(
      [
        "OPENROUTER_ANALYTICS_MODEL",
        "OPENROUTER_ANALYTICS_PROVIDER",
        "ANALYTICS_PROVIDER_REVIEWED_AT",
        "ANALYTICS_USER_DAILY_CALLS",
        "ANALYTICS_ORG_DAILY_CALLS",
        "ANALYTICS_CONCURRENCY",
      ]
        .filter((k) => pick(k))
        .map((k) => [k, pick(k)]),
    ),
  };
  const worker = {
    ...shared,
    ...agent,
    WORKER_DATABASE_URL: url(
      applicationDatabase,
      "hr_worker",
      workerPassword,
      runtimeCa,
    ),
    SMTP_HOST: pick("SMTP_HOST", "localhost"),
    SMTP_PORT: pick("SMTP_PORT", "25"),
    SMTP_FROM: pick("SMTP_FROM", "hr@example.com"),
    SMTP_SECURE: pick("SMTP_SECURE", "false"),
    SMTP_USER: pick("SMTP_USER"),
    SMTP_PASSWORD: pick("SMTP_PASSWORD"),
    FCM_SERVICE_ACCOUNT_FILE: pick("FCM_SERVICE_ACCOUNT_FILE"),
  };
  if (cloud) {
    validateCloudEnvironment(api, "api");
    validateCloudEnvironment(worker, "worker");
  }
  await writeEnv(resolve(output, "api.env"), api);
  await writeEnv(resolve(output, "worker.env"), worker);
  if (adminPassword)
    await writeEnv(resolve(output, "migration.env"), {
      MIGRATION_DATABASE_URL: url(
        applicationDatabase,
        adminUser,
        adminPassword,
      ),
    });
  console.log(
    `Rendered role-separated mode-0600 environments in ${cloud ? ".local/aws-rds/render/" : ".local/aws-rds/"}.`,
  );
}

try {
  if (command === "check") await check();
  else if (command === "render") await render();
  else if (command === "render-cloud") await render(true);
  else if (command === "prepare-copy") await provision(true);
  else await provision();
} catch (error) {
  const code =
    error instanceof Error && /timeout|timed out/i.test(error.message)
      ? "ETIMEDOUT"
      : error && typeof error === "object" && "code" in error
        ? String(error.code)
        : "SETUP_FAILED";
  const hints: Record<string, string> = {
    ETIMEDOUT:
      "Connection timed out. Allow this machine or app host on the RDS security group for TCP 5432.",
    ECONNREFUSED:
      "RDS refused the connection. Confirm endpoint, port, instance status and security-group routing.",
    "28P01": "RDS rejected the username or password.",
    "3D000":
      "The requested database does not exist; run the explicit provision command.",
  };
  console.error(
    JSON.stringify({
      status: "failed",
      code,
      hint:
        hints[code] ??
        (code === "SETUP_FAILED" && error instanceof Error
          ? error.message
          : "Review the local setup values; secrets were not printed."),
    }),
  );
  process.exitCode = 1;
}
