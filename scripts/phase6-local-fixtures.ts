import { pool } from "../packages/db/src/index.js";
import { migrate } from "../packages/db/src/migrate.js";
import { ids } from "../packages/db/src/seed.js";
const url = process.env.MIGRATION_DATABASE_URL!;
if (
  new URL(url).pathname != "/hr_local" ||
  !["localhost", "127.0.0.1"].includes(new URL(url).hostname)
)
  throw Error("Synthetic localhost hr_local database required");
await migrate(url);
const db = pool(url, 1);
try {
  for (const user of [ids.admin, ids.siteAdmin, ids.superAdmin])
    for (const key of ["analytics.view", "reports.view"])
      await db.query(
        "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,$4,'allow',$5) ON CONFLICT(organization_id,site_id,user_id,key) DO UPDATE SET effect='allow',scope=excluded.scope",
        [
          ids.org,
          ids.dg,
          user,
          key,
          user === ids.superAdmin && key === "reports.view"
            ? "organization"
            : "site",
        ],
      );
  console.log("Synthetic local analytics grants and migrations ready.");
} finally {
  await db.end();
}
