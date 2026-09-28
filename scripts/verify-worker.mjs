import assert from "node:assert/strict";
import pg from "pg";
if (
  process.env.SMTP_HOST !== "localhost" ||
  new URL(process.env.MIGRATION_DATABASE_URL).pathname !== "/hr_local"
)
  throw new Error("Only synthetic local mail is permitted");
const db = new pg.Pool({
  connectionString: process.env.MIGRATION_DATABASE_URL,
  max: 1,
});
try {
  const result = await fetch("http://127.0.0.1:4000/auth/recovery", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      organizationId: "10000000-0000-4000-8000-000000000001",
      email: "employee@example.test",
    }),
  });
  assert.equal(result.status, 202);
  let delivered = false;
  for (let attempt = 0; attempt < 10; attempt++) {
    const { rows } = await db.query(
      "SELECT sent_at FROM auth.mail_outbox ORDER BY created_at DESC LIMIT 1",
    );
    if (rows[0]?.sent_at) {
      delivered = true;
      break;
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  assert.ok(
    delivered,
    "Worker must deliver the encrypted transactional mail payload",
  );
  assert.equal(
    Number(
      (
        await db.query(
          "SELECT count(*) FROM app.outbox WHERE published_at IS NULL",
        )
      ).rows[0].count,
    ),
    0,
  );
  console.log(
    "PASS: transactional event publication and synthetic recovery-mail delivery.",
  );
} finally {
  await db.end();
}
