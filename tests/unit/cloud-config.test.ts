import test from "node:test";
import assert from "node:assert/strict";
import {
  cloudDatabase,
  validateCloudEnvironment,
} from "../../packages/config/src/cloud.js";
const db = (role: string) =>
  `postgresql://${role}:private%40password@db.rds.amazonaws.com/hr?sslmode=verify-full&sslrootcert=/etc/secrets/rds-ca.pem`;
const base = {
  DEPLOYMENT_TARGET: "render-rds",
  NODE_ENV: "production",
  ENCRYPTION_KEY: "a".repeat(64),
  REDIS_URL: "redis://queue.internal:6379",
  S3_ENDPOINT: "https://s3.ap-south-1.amazonaws.com",
  S3_REGION: "ap-south-1",
  S3_BUCKET: "private-bucket",
  S3_ACCESS_KEY: "access",
  S3_SECRET_KEY: "secret",
  DATABASE_URL: db("hr_runtime"),
  AUTH_DATABASE_URL: db("hr_auth"),
  WORKER_DATABASE_URL: db("hr_worker"),
  WEB_ORIGIN: "https://hr.onrender.com",
  COOKIE_SECURE: "true",
  LOGIN_ORGANIZATION_ID: "10000000-0000-4000-8000-000000000001",
  SMTP_HOST: "smtp.example.net",
  SMTP_PORT: "465",
  SMTP_SECURE: "true",
  SMTP_FROM: "hr@example.net",
  SMTP_USER: "user",
  SMTP_PASSWORD: "password",
};
test("Render API and worker accept remote dependencies with restricted database roles", () => {
  validateCloudEnvironment(base, "api");
  validateCloudEnvironment(base, "worker");
  validateCloudEnvironment(
    { ...base, SMTP_PORT: "587", SMTP_SECURE: "false" },
    "worker",
  );
});
test("Explicit web-only preview can defer S3 without permitting worker storage gaps", () => {
  const {
    S3_ENDPOINT,
    S3_REGION,
    S3_BUCKET,
    S3_ACCESS_KEY,
    S3_SECRET_KEY,
    ...withoutS3
  } = base;
  const preview = { ...withoutS3, FILE_STORAGE_DISABLED: "true" };
  validateCloudEnvironment(preview, "api");
  assert.throws(() => validateCloudEnvironment(preview, "worker"));
  assert.throws(() => validateCloudEnvironment(withoutS3, "api"));
  assert.throws(() =>
    validateCloudEnvironment({ ...preview, REDIS_URL: "" }, "api"),
  );
});
test("Cloud deployment rejects local fallbacks, owner credentials and incomplete configuration", () => {
  for (const override of [
    { DATABASE_URL: db("postgres") },
    { AUTH_DATABASE_URL: db("hr_runtime") },
    {
      DATABASE_URL: db("hr_runtime").replace(
        "db.rds.amazonaws.com",
        "localhost",
      ),
    },
    { REDIS_URL: "redis://127.0.0.1:6379" },
    { S3_ENDPOINT: "http://localhost:59000" },
    { WEB_ORIGIN: "https://hr.onrender.com/" },
    { S3_BUCKET: "" },
    { COOKIE_SECURE: "false" },
    { MIGRATION_DATABASE_URL: db("postgres") },
    { AWS_RDS_ADMIN_PASSWORD: "private" },
    { AUTH_DATABASE_URL: db("hr_auth").replace("/hr?", "/another?") },
  ])
    assert.throws(() =>
      validateCloudEnvironment({ ...base, ...override }, "api"),
    );
  assert.throws(() =>
    validateCloudEnvironment({ ...base, SMTP_HOST: "localhost" }, "worker"),
  );
  assert.throws(() =>
    validateCloudEnvironment(
      { ...base, WORKER_DATABASE_URL: db("postgres") },
      "worker",
    ),
  );
});
test("TLS and connection overrides cannot weaken verification or change the checked role", () => {
  for (const url of [
    db("hr_runtime").replace("verify-full", "require"),
    db("hr_runtime") + "&ssl=false",
    db("hr_runtime") + "&host=localhost",
    db("hr_runtime") + "&user=postgres",
    db("hr_runtime").replace(/&sslrootcert=.*/, ""),
  ])
    assert.throws(() => cloudDatabase(url, "DATABASE_URL", "hr_runtime"));
  assert.throws(() => cloudDatabase("private-password", "DATABASE_URL"), {
    message: "DATABASE_URL must be a valid URL",
  });
});
test("Existing isolated development environments do not opt into the cloud contract", () => {
  validateCloudEnvironment({ NODE_ENV: "test" }, "api");
});
