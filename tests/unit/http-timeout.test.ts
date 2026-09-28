import { test } from "node:test";
import assert from "node:assert/strict";
import { randomBytes } from "node:crypto";
import type pg from "pg";
import { createApp } from "../../apps/api/src/app.js";

test(
  "a handler exceeding ten seconds returns a response without a socket reset",
  { timeout: 20_000 },
  async () => {
    const unusedPool = {
      query: () => {
        throw new Error("Unexpected database access");
      },
    } as unknown as pg.Pool;
    const app = await createApp(
      {
        NODE_ENV: "test",
        PORT: 4000,
        DATABASE_URL: "postgres://localhost/unused",
      AUTH_DATABASE_URL: "postgres://localhost/unused",
      LOGIN_ORGANIZATION_ID: "00000000-0000-0000-0000-000000000001",
        WEB_ORIGIN: "http://localhost:5173",
        COOKIE_SECURE: "true",
        ENCRYPTION_KEY: randomBytes(32).toString("hex"),
        REDIS_URL: "redis://localhost:56379",
      },
      unusedPool,
      unusedPool,
      false,
    );
    app.get("/__test/slow", async () => {
      await new Promise((resolve) => setTimeout(resolve, 10_200));
      return { ok: true };
    });
    try {
      const address = await app.listen({ port: 0, host: "127.0.0.1" });
      const response = await fetch(`${address}/__test/slow`, {
        signal: AbortSignal.timeout(15_000),
      });
      assert.equal(response.status, 200);
      assert.deepEqual(await response.json(), { ok: true });
    } finally {
      await app.close();
    }
  },
);
