import { config } from "../../../packages/config/src/index.js";
import { pool, assertRuntimeRole } from "../../../packages/db/src/index.js";
import { createApp } from "./app.js";
import {
  cloudDatabase,
  renderDatabaseUrl,
} from "../../../packages/config/src/cloud.js";
import { runDwrAgent } from "./dwr-agent-runner.js";
const cfg = config(),
  business = pool(cfg.DATABASE_URL),
  auth = pool(cfg.AUTH_DATABASE_URL, 5);
await assertRuntimeRole(business, "hr_runtime");
await assertRuntimeRole(auth, "hr_auth");
const app = await createApp(cfg, business, auth);
// Optional AI-only runner in the existing web process. Keeps its worker role
// separate from HTTP transactions and requires no Redis/SMTP consumer.
const agentStop = new AbortController();
let agentDb: ReturnType<typeof pool> | undefined;
let agentTask: Promise<void> | undefined;
if (process.env.RUN_DWR_AGENT === "true") {
  const url = process.env.WORKER_DATABASE_URL;
  if (!url) throw new Error("WORKER_DATABASE_URL required for RUN_DWR_AGENT");
  if (process.env.DEPLOYMENT_TARGET === "render-rds")
    cloudDatabase(url, "WORKER_DATABASE_URL", "hr_worker");
  agentDb = pool(
    process.env.DEPLOYMENT_TARGET === "render-rds"
      ? renderDatabaseUrl(url)
      : url,
    2,
  );
  await assertRuntimeRole(agentDb, "hr_worker");
  agentTask = runDwrAgent(agentDb, agentStop.signal);
}
const stop = async () => {
  agentStop.abort();
  await app.close();
  await agentTask;
  await agentDb?.end();
  await Promise.all([business.end(), auth.end()]);
};
process.once("SIGTERM", stop);
process.once("SIGINT", stop);
await app.listen({ port: cfg.PORT, host: "0.0.0.0" });
