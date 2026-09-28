import { writeFile } from "node:fs/promises";
import { randomUUID } from "node:crypto";
import pg from "pg";
import { decrypt, totp } from "../apps/api/src/security.ts";
if (
  !process.env.SEED_PASSWORD ||
  new URL(process.env.MIGRATION_DATABASE_URL ?? "").pathname != "/hr_local"
)
  throw Error("Synthetic local credentials required");
const db = new pg.Pool({
  connectionString: process.env.MIGRATION_DATABASE_URL,
});
try {
  const row = (
    await db.query(
      "SELECT u.mfa_secret,u.last_totp_step FROM auth.users u JOIN app.organizations o ON o.id=u.organization_id WHERE o.slug='defence-garden-demo' AND u.email='superadmin@example.test'",
    )
  ).rows[0];
  if (!row) throw Error("Seed the synthetic Super Admin first");
  async function post(path, body, access) {
    const r = await fetch(`http://127.0.0.1:4000${path}`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        ...(access ? { authorization: `Bearer ${access}` } : {}),
      },
      body: JSON.stringify(body),
    });
    const data = await r.json();
    if (!r.ok) throw Error(data.code ?? "Local test authentication failed");
    return data;
  }
  const session = await post("/auth/login", {
    organizationId: "10000000-0000-4000-8000-000000000001",
    email: "superadmin@example.test",
    password: process.env.SEED_PASSWORD,
    kind: "mobile",
    deviceId: randomUUID(),
  });
  if (session.mfaRequired) {
    const secret = session.enrollmentRequired
      ? (await post("/auth/mfa/setup", {}, session.accessToken)).secret
      : decrypt(row.mfa_secret, process.env.ENCRYPTION_KEY);
    const delay = (Number(row.last_totp_step) + 1) * 30000 - Date.now() + 100;
    if (delay > 0 && delay < 31000)
      await new Promise((resolve) => setTimeout(resolve, delay));
    await post(
      "/auth/mfa/verify",
      { code: totp(secret).generate() },
      session.accessToken,
    );
  }
  await writeFile(
    ".local/mobile-test.json",
    JSON.stringify({
      TEST_PASSWORD: process.env.SEED_PASSWORD,
      TEST_ADMIN_ACCESS: session.accessToken,
      TEST_ADMIN_REFRESH: session.refreshToken,
    }),
    { mode: 0o600 },
  );
  console.log(
    "Protected local mobile test credentials prepared; Super Admin completed normal MFA.",
  );
} finally {
  await db.end();
}
