import type pg from "pg";
import { setTimeout } from "node:timers/promises";
import { transaction } from "../../../packages/db/src/index.js";
import { AgentError, HttpDwrAgent, agentSetup } from "./dwr-provider.js";

/** Worker-only DB connection; no request can claim jobs or supply job identity. */
export async function runDwrAgent(
  db: pg.Pool,
  stop: AbortSignal,
  agent: Pick<HttpDwrAgent, "prepare"> = new HttpDwrAgent(),
  getSetup = agentSetup,
) {
  let heartbeatAt = 0;
  while (!stop.aborted) {
    const setup = getSetup();
    try {
      if (Date.now() - heartbeatAt >= 25_000) {
        await db.query("SELECT app.dwr_agent_heartbeat($1,$2)", [
          setup.configured,
          setup.model,
        ]);
        heartbeatAt = Date.now();
      }
      if (setup.configured) {
        const jobs = (
          await transaction(db, (c) =>
            c.query("SELECT * FROM app.dwr_agent_claim(3,$1,$2)", [
              setup.userDaily,
              setup.orgDaily,
            ]),
          )
        ).rows;
        // All three 60-second leases start together. Serial provider calls could
        // expire the last lease before it was stored. Bound concurrency at three.
        await Promise.allSettled(
          jobs.map(async (job) => {
            const key = [
              job.organization_id,
              job.site_id,
              job.employee_id,
              job.work_date,
            ];
            try {
              const result = await agent.prepare(
                job.messages,
                job.timezone,
                AbortSignal.any([stop, AbortSignal.timeout(30_000)]),
              );
              await transaction(db, (c) =>
                c.query("SELECT app.dwr_agent_store($1,$2,$3,$4,$5,$6,$7,$8)", [
                  ...key,
                  job.lease,
                  job.source_hash,
                  result.content,
                  result.provenance,
                ]),
              );
            } catch (e) {
              const error =
                e instanceof AgentError
                  ? e
                  : new AgentError("RECOVERABLE_ERROR", 60);
              console.error(
                JSON.stringify({
                  level: "warn",
                  code: `DWR_AGENT_${error.code}`,
                }),
              );
              await db.query(
                "SELECT app.dwr_agent_fail($1,$2,$3,$4,$5,$6,$7)",
                [...key, job.lease, error.code, error.retryAfter],
              );
            }
          }),
        );
      }
    } catch {
      console.error("DWR agent polling failed; retry scheduled");
    }
    await setTimeout(setup.configured ? 1000 : 15000, undefined, {
      signal: stop,
    }).catch(() => {});
  }
}
