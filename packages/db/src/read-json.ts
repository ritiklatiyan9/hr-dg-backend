import type { Tx } from "./index.js";

/** Batch independent JSON response reads on the same RLS-scoped connection.
 * SQL is application-owned; all values remain bound parameters. Dates inside
 * these JSON rows are strings, so use ordinary queries for Date-based logic.
 * Never pass mutations: every entry must be a SELECT.
 */
export async function readJson<K extends string>(
  c: Tx,
  reads: Record<K, readonly [sql: string, values?: readonly unknown[]]>,
): Promise<Record<K, any[]>> {
  const values: unknown[] = [];
  const columns = Object.entries(reads).map(([key, spec]) => {
    if (!/^[a-zA-Z][a-zA-Z0-9_]*$/.test(key)) throw Error("Invalid read key");
    const [sql, params = []] = spec as [
      sql: string,
      values?: readonly unknown[],
    ];
    const offset = values.length;
    values.push(...params);
    const text = sql.replace(/\$(\d+)\b/g, (_, n) => `$${Number(n) + offset}`);
    return `(SELECT COALESCE(json_agg(row),'[]'::json) FROM (${text}) row) AS "${key}"`;
  });
  if (!columns.length) return {} as Record<K, any[]>;
  return (await c.query(`SELECT ${columns.join(",")}`, values)).rows[0];
}
