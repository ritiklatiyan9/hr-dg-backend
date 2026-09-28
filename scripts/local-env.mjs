import { randomBytes } from "node:crypto";
import { writeFile, mkdir } from "node:fs/promises";
const secret = () => randomBytes(24).toString("hex");
const owner = secret(),
  runtime = secret(),
  auth = secret(),
  worker = secret();
await mkdir(".local", { recursive: true });
const content = `NODE_ENV=development
PORT=4000
WEB_ORIGIN=http://localhost:5180
COOKIE_SECURE=false
ENCRYPTION_KEY=${randomBytes(32).toString("hex")}
POSTGRES_PASSWORD=${owner}
RUNTIME_DB_PASSWORD=${runtime}
AUTH_DB_PASSWORD=${auth}
WORKER_DB_PASSWORD=${worker}
DATABASE_URL=postgresql://hr_runtime:${runtime}@localhost:55432/hr_local
AUTH_DATABASE_URL=postgresql://hr_auth:${auth}@localhost:55432/hr_local
LOGIN_ORGANIZATION_ID=10000000-0000-4000-8000-000000000001
WORKER_DATABASE_URL=postgresql://hr_worker:${worker}@localhost:55432/hr_local
MIGRATION_DATABASE_URL=postgresql://postgres:${owner}@localhost:55432/hr_local
TEST_MIGRATION_DATABASE_URL=postgresql://postgres:${owner}@localhost:55432/hr_test
TEST_DATABASE_URL=postgresql://hr_runtime:${runtime}@localhost:55432/hr_test
TEST_AUTH_DATABASE_URL=postgresql://hr_auth:${auth}@localhost:55432/hr_test
REDIS_URL=redis://localhost:56379
S3_ENDPOINT=http://localhost:59000
S3_ACCESS_KEY=hr-local
S3_SECRET_KEY=${secret()}
S3_BUCKET=hr-private
SMTP_HOST=localhost
SMTP_PORT=51025
SMTP_FROM=hr@example.test
SEED_PASSWORD=${secret()}
`;
await writeFile(".env", content, { mode: 0o600, flag: "wx" });
await writeFile(".env.test", content, { mode: 0o600, flag: "wx" });
console.log(
  "Created .env and .env.test with random local-only secrets. Existing files are never overwritten.",
);
