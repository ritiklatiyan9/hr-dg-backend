import pg from "pg";
import { drizzle } from "drizzle-orm/node-postgres";
import { fail, type Actor } from "../../authz/src/index.js";
export type Tx = pg.PoolClient;
export function pool(url: string, max = 10) {
  const connectionPool = new pg.Pool({
    connectionString: url,
    max,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 5_000,
    statement_timeout: 8_000,
    query_timeout: 10_000,
    application_name: "defence-garden-hr",
  });
  connectionPool.on("error", () => {
    // Idle connection failures must not crash the process or expose connection
    // strings through raw driver errors. New checkouts reconnect normally.
    console.error(
      JSON.stringify({ level: "error", code: "DATABASE_CONNECTION_LOST" }),
    );
  });
  return connectionPool;
}
export async function transaction<T>(
  p: pg.Pool,
  fn: (c: Tx) => Promise<T>,
): Promise<T> {
  const c = await p.connect();
  try {
    await c.query("BEGIN");
    const result = await fn(c);
    await c.query("COMMIT");
    return result;
  } catch (e) {
    await c.query("ROLLBACK");
    throw e;
  } finally {
    c.release();
  }
}
export async function scoped<T>(
  p: pg.Pool,
  actor: Actor,
  siteId: string | null,
  fn: (c: Tx) => Promise<T>,
  verifySession = false,
) {
  return transaction(p, async (c) => {
    await c.query(
      "SELECT set_config('app.organization_id',$1,true),set_config('app.actor_id',$2,true),set_config('app.site_id',$3,true)",
      [actor.organizationId, actor.id, siteId ?? ""],
    );
    if (verifySession) {
      // Context is already installed on this connection before either check.
      const { rows } = await c.query(
        "SELECT ($1::uuid IS NULL OR app.has_site($1)) AS allowed,app.check_request($2,$3) AS current",
        [siteId, actor.sessionId, actor.permissionVersion],
      );
      if (!rows[0]?.allowed) fail("FORBIDDEN", "Site access denied", 403);
      if (!rows[0]?.current)
        fail("SCOPE_CHANGED", "Access changed. Reload your workspace.", 409);
    } else if (siteId) {
      const { rows } = await c.query("SELECT app.has_site($1) AS allowed", [
        siteId,
      ]);
      if (!rows[0]?.allowed) fail("FORBIDDEN", "Site access denied", 403);
    }
    return fn(c);
  });
}
export const orm = (c: Tx) => drizzle(c);
export async function assertRuntimeRole(p: pg.Pool, expected: string) {
  const { rows } =
    await p.query(`SELECT current_user AS name,rolsuper,rolbypassrls,
 EXISTS(SELECT 1 FROM pg_class WHERE relowner=(SELECT oid FROM pg_roles WHERE rolname=current_user) AND relnamespace IN ('app'::regnamespace,'auth'::regnamespace)) AS owns,
 EXISTS(SELECT 1 FROM pg_roles inherited WHERE inherited.rolname<>current_user AND pg_has_role(current_user,inherited.oid,'MEMBER') AND (inherited.rolsuper OR inherited.rolbypassrls OR EXISTS(SELECT 1 FROM pg_class t WHERE t.relowner=inherited.oid AND t.relnamespace IN ('app'::regnamespace,'auth'::regnamespace)))) AS privileged_membership
 FROM pg_roles WHERE rolname=current_user`);
  const r = rows[0];
  if (
    !r ||
    r.name !== expected ||
    r.rolsuper ||
    r.rolbypassrls ||
    r.owns ||
    r.privileged_membership
  )
    throw new Error(`Unsafe runtime database role: expected ${expected}`);
}

/** Business API entry point: verify the session and selected site together. */
export function verifiedScoped<T>(
  p: pg.Pool,
  actor: Actor,
  siteId: string | null,
  fn: (c: Tx) => Promise<T>,
) {
  return scoped(p, actor, siteId, fn, true);
}
