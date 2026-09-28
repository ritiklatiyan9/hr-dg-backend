import { z } from "zod";
import { renderDatabaseUrl, validateCloudEnvironment } from "./cloud.js";
const schema = z.object({
  NODE_ENV: z
    .enum(["development", "test", "production"])
    .default("development"),
  PORT: z.coerce.number().default(4000),
  DATABASE_URL: z.string().min(1),
  AUTH_DATABASE_URL: z.string().min(1),
  LOGIN_ORGANIZATION_ID: z
    .uuid()
    .default("10000000-0000-4000-8000-000000000001"),
  WEB_ORIGIN: z.url().default("http://localhost:5180"),
  ENCRYPTION_KEY: z.string().regex(/^[0-9a-f]{64}$/),
  COOKIE_SECURE: z.enum(["true", "false"]).default("true"),
  REDIS_URL: z.url().default("redis://localhost:6379"),
});
export type Config = z.infer<typeof schema>;
export function config(env = process.env): Config {
  validateCloudEnvironment(env, "api");
  const c = schema.parse(env);
  if (env.DEPLOYMENT_TARGET === "render-rds") {
    c.DATABASE_URL = renderDatabaseUrl(c.DATABASE_URL);
    c.AUTH_DATABASE_URL = renderDatabaseUrl(c.AUTH_DATABASE_URL);
  }
  if (c.NODE_ENV === "production" && !env.LOGIN_ORGANIZATION_ID)
    throw new Error("Production requires LOGIN_ORGANIZATION_ID");
  if (c.NODE_ENV === "production" && env.MIGRATION_DATABASE_URL)
    throw new Error(
      "Migration credentials must not be present in the runtime environment",
    );
  if (
    c.NODE_ENV === "production" &&
    (!c.WEB_ORIGIN.startsWith("https:") || c.COOKIE_SECURE !== "true")
  )
    throw new Error("Production requires HTTPS and secure cookies");
  return c;
}
