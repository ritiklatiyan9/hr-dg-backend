import pg from "pg";
const url = process.env.MIGRATION_DATABASE_URL;
if (!url || new URL(url).pathname != "/hr_local")
  throw Error("Only synthetic hr_local is allowed");
const db = new pg.Pool({ connectionString: url });
try {
  const result = await db.query(
    "DELETE FROM app.profile_requests r USING app.organizations o,auth.users u WHERE r.organization_id=o.id AND r.requester_id=u.id AND o.slug='defence-garden-demo' AND u.email='employee@example.test' AND r.reason IN ('Flutter device verification only','Flutter live API verification only')",
  );
  console.log(
    `Removed ${result.rowCount} synthetic mobile verification requests.`,
  );
} finally {
  await db.end();
}
