import { readFile, readdir } from "node:fs/promises";
import { createHash } from "node:crypto";
import { pool, transaction } from "./index.js";
export async function migrate(url: string) {
  const p = pool(url, 1);
  try {
    await transaction(p, async (c) => {
      await c.query("SELECT pg_advisory_xact_lock(726341)");
      await c.query(
        "CREATE TABLE IF NOT EXISTS public.schema_migrations(name text PRIMARY KEY, sha256 text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now())",
      );
      const dir = new URL("../migrations/", import.meta.url);
      for (const name of (await readdir(dir))
        .filter((n) => n.endsWith(".sql"))
        .sort()) {
        const sql = await readFile(new URL(name, dir), "utf8");
        const sha = createHash("sha256").update(sql).digest("hex");
        const { rows } = await c.query(
          "SELECT sha256 FROM public.schema_migrations WHERE name=$1",
          [name],
        );
        if (rows[0]) {
          if (rows[0].sha256 !== sha)
            throw new Error(`Changed applied migration ${name}`);
          continue;
        }
        await c.query(sql);
        await c.query(
          "INSERT INTO public.schema_migrations(name,sha256) VALUES($1,$2)",
          [name, sha],
        );
      }
    });
  } finally {
    await p.end();
  }
}
if (process.argv[1]?.endsWith("/migrate.ts")) {
  if (!process.env.MIGRATION_DATABASE_URL)
    throw new Error("MIGRATION_DATABASE_URL required");
  await migrate(process.env.MIGRATION_DATABASE_URL);
  console.log("Migrations applied");
}
