type Environment = Record<string, string | undefined>;

export function required(env: Environment, key: string): string {
  const value = env[key]?.trim();
  if (!value) throw new Error(`${key} is required`);
  return value;
}

export function remoteUrl(
  value: string,
  key: string,
  protocols: string[],
): URL {
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new Error(`${key} must be a valid URL`);
  }
  if (!protocols.includes(url.protocol))
    throw new Error(`${key} has an unsupported protocol`);
  const host = url.hostname.toLowerCase();
  if (
    !host ||
    host === "localhost" ||
    host.endsWith(".localhost") ||
    host.endsWith(".local") ||
    host === "host.docker.internal" ||
    host === "[::1]" ||
    host === "[::]" ||
    host.startsWith("127.") ||
    host === "0.0.0.0"
  )
    throw new Error(`${key} must use a cloud host`);
  return url;
}

export function cloudDatabase(value: string, key: string, role?: string): URL {
  const url = remoteUrl(value, key, ["postgres:", "postgresql:"]);
  if (
    [...url.searchParams.keys()].some(
      (k) => !["sslmode", "sslrootcert"].includes(k),
    )
  )
    throw new Error(`${key} contains unsupported connection overrides`);
  if (
    url.searchParams.get("sslmode") !== "verify-full" ||
    !url.searchParams.get("sslrootcert") ||
    url.searchParams.has("ssl") ||
    url.searchParams.has("uselibpqcompat")
  )
    throw new Error(
      `${key} requires sslmode=verify-full and sslrootcert, without TLS overrides`,
    );
  if (
    !url.username ||
    !url.password ||
    url.pathname.length < 2 ||
    (role && decodeURIComponent(url.username) !== role)
  )
    throw new Error(
      `${key} requires the correct database role, password and database name`,
    );
  return url;
}

// Opt-in deployment contract: existing development/test environments stay isolated.
export function validateCloudEnvironment(
  env: Environment,
  kind: "api" | "worker",
) {
  if (env.DEPLOYMENT_TARGET !== "render-rds") return;
  if (env.NODE_ENV !== "production")
    throw new Error("Cloud deployment requires NODE_ENV=production");
  for (const key of [
    "MIGRATION_DATABASE_URL",
    "POSTGRES_PASSWORD",
    "AWS_RDS_ADMIN_PASSWORD",
    "SOURCE_DATABASE_URL",
  ])
    if (env[key])
      throw new Error(`${key} must not be available to cloud runtime services`);
  if (!/^[a-f0-9]{64}$/.test(required(env, "ENCRYPTION_KEY")))
    throw new Error(
      "ENCRYPTION_KEY must be the original 32-byte hex encryption key",
    );
  if (kind === "api") {
    const business = cloudDatabase(
      required(env, "DATABASE_URL"),
      "DATABASE_URL",
      "hr_runtime",
    );
    const auth = cloudDatabase(
      required(env, "AUTH_DATABASE_URL"),
      "AUTH_DATABASE_URL",
      "hr_auth",
    );
    if (business.host !== auth.host || business.pathname !== auth.pathname)
      throw new Error("API database roles must connect to the same database");
    const origin = remoteUrl(required(env, "WEB_ORIGIN"), "WEB_ORIGIN", [
      "https:",
    ]);
    if (origin.origin !== env.WEB_ORIGIN || env.COOKIE_SECURE !== "true")
      throw new Error(
        "WEB_ORIGIN must be an HTTPS origin without a trailing slash; secure cookies are required",
      );
    required(env, "LOGIN_ORGANIZATION_ID");
  } else {
    cloudDatabase(
      required(env, "WORKER_DATABASE_URL"),
      "WORKER_DATABASE_URL",
      "hr_worker",
    );
    const host = required(env, "SMTP_HOST");
    remoteUrl(`https://${host}`, "SMTP_HOST", ["https:"]);
    if (
      !["465", "587"].includes(required(env, "SMTP_PORT")) ||
      env.SMTP_SECURE !== (env.SMTP_PORT === "465" ? "true" : "false")
    )
      throw new Error(
        "SMTP requires port 465 with TLS or port 587 with STARTTLS",
      );
    for (const key of ["SMTP_USER", "SMTP_PASSWORD", "SMTP_FROM"])
      required(env, key);
  }
  remoteUrl(required(env, "REDIS_URL"), "REDIS_URL", ["redis:", "rediss:"]);
  // Explicit web-only preview while the operator has deferred S3 migration.
  // The worker must always have durable object storage for retention jobs.
  if (env.FILE_STORAGE_DISABLED === "true") {
    if (kind !== "api")
      throw new Error("FILE_STORAGE_DISABLED is only supported for the API");
  } else {
    remoteUrl(required(env, "S3_ENDPOINT"), "S3_ENDPOINT", ["https:"]);
    for (const key of [
      "S3_REGION",
      "S3_BUCKET",
      "S3_ACCESS_KEY",
      "S3_SECRET_KEY",
    ])
      required(env, key);
  }
}
