import { config } from "../../../packages/config/src/index.js";
import { pool, assertRuntimeRole } from "../../../packages/db/src/index.js";
import { createApp } from "./app.js";
const cfg = config(),
  business = pool(cfg.DATABASE_URL),
  auth = pool(cfg.AUTH_DATABASE_URL, 5);
await assertRuntimeRole(business, "hr_runtime");
await assertRuntimeRole(auth, "hr_auth");
const app = await createApp(cfg, business, auth);
const stop = async () => {
  await app.close();
  await Promise.all([business.end(), auth.end()]);
};
process.once("SIGTERM", stop);
process.once("SIGINT", stop);
await app.listen({ port: cfg.PORT, host: "0.0.0.0" });
