import { randomBytes, randomUUID } from "node:crypto";
import { pool } from "../../packages/db/src/index.js";
import { migrate } from "../../packages/db/src/migrate.js";
import { seed, ids } from "../../packages/db/src/seed.js";
import { createApp } from "../../apps/api/src/app.js";
import { AuthService } from "../../apps/api/src/auth.js";
import { decrypt, totp } from "../../apps/api/src/security.js";
import assert from "node:assert/strict";
export async function fixture(prefix = "phase6") {
  const root = process.env.TEST_MIGRATION_DATABASE_URL!;
  if (
    !root ||
    new URL(root).pathname !== "/hr_test" ||
    !["localhost", "127.0.0.1"].includes(new URL(root).hostname)
  )
    throw Error("Disposable loopback PostGIS required");
  const control = pool(root, 1),
    dbName = `hr_test_${randomBytes(8).toString("hex")}`;
  await control.query(`CREATE DATABASE ${dbName}`);
  const url = (base: string) => {
    const u = new URL(base);
    u.pathname = `/${dbName}`;
    return u.toString();
  };
  const password = randomBytes(24).toString("hex"),
    key = randomBytes(32).toString("hex");
  await migrate(url(root));
  await seed(url(root), password);
  const owner = pool(url(root), 2),
    runtime = pool(url(process.env.TEST_DATABASE_URL!), 10),
    authPool = pool(url(process.env.TEST_AUTH_DATABASE_URL!), 5);
  const config = {
    NODE_ENV: "test" as const,
    PORT: 4000,
    DATABASE_URL: url(process.env.TEST_DATABASE_URL!),
    AUTH_DATABASE_URL: url(process.env.TEST_AUTH_DATABASE_URL!),
    LOGIN_ORGANIZATION_ID: ids.org,
    WEB_ORIGIN: "http://localhost:5180",
    COOKIE_SECURE: "true" as const,
    ENCRYPTION_KEY: key,
    REDIS_URL: "redis://localhost:56379",
  };
  const app = await createApp(config, runtime, authPool, false),
    auth = new AuthService(authPool, config);
  let sequence = 1;
  async function login(email: string) {
    const remoteAddress = `127.1.0.${sequence++}`;
    const r = await app.inject({
      remoteAddress,
      method: "POST",
      url: "/auth/login",
      payload: {
        email,
        password,
        kind: "mobile",
        deviceId: randomUUID(),
      },
    });
    assert.equal(r.statusCode, 200, r.body);
    const d = r.json();
    if (d.mfaRequired) {
      let secret: string;
      if (d.enrollmentRequired)
        secret = (
          await app.inject({
            remoteAddress,
            method: "POST",
            url: "/auth/mfa/setup",
            headers: { authorization: `Bearer ${d.accessToken}` },
            payload: {},
          })
        ).json().secret;
      else {
        secret = decrypt(
          (
            await owner.query(
              "SELECT mfa_secret FROM auth.users WHERE email=$1",
              [email],
            )
          ).rows[0].mfa_secret,
          key,
        );
        await owner.query(
          "UPDATE auth.users SET last_totp_step=-1 WHERE email=$1",
          [email],
        );
      }
      const m = await app.inject({
        remoteAddress,
        method: "POST",
        url: "/auth/mfa/verify",
        headers: { authorization: `Bearer ${d.accessToken}` },
        payload: { code: totp(secret).generate() },
      });
      assert.equal(m.statusCode, 200, m.body);
    }
    return {
      token: d.accessToken as string,
      actor: (await auth.lookup(d.accessToken))!,
    };
  }
  async function close() {
    await app.close();
    await Promise.all([owner.end(), runtime.end(), authPool.end()]);
    await control.query(`DROP DATABASE ${dbName}`);
    await control.end();
  }
  return {
    app,
    owner,
    runtime,
    authPool,
    auth,
    login,
    close,
    dbName,
    rootUrl: url(root),
    config,
  };
}
