import { writeFile, rm, mkdir } from "node:fs/promises";
import { execFileSync } from "node:child_process";
import assert from "node:assert/strict";
const docker = process.env.DOCKER_BIN ?? "docker";
if (
  new URL(process.env.DATABASE_URL).pathname != "/hr_local" ||
  !["localhost", "127.0.0.1"].includes(
    new URL(process.env.DATABASE_URL).hostname,
  )
)
  throw Error("Local synthetic DB only");
const url = (v) => {
  const u = new URL(v);
  u.hostname = "host.docker.internal";
  return u.toString();
};
const file = ".local/container-smoke.env",
  name = `hr-phase6-smoke-${process.pid}`;
await mkdir(".local", { recursive: true });
await writeFile(
  file,
  Object.entries({
    NODE_ENV: "production",
    SERVE_WEB: "true",
    WEB_ORIGIN: "https://localhost",
    COOKIE_SECURE: "true",
    ENCRYPTION_KEY: process.env.ENCRYPTION_KEY,
    DATABASE_URL: url(process.env.DATABASE_URL),
    AUTH_DATABASE_URL: url(process.env.AUTH_DATABASE_URL),
    LOGIN_ORGANIZATION_ID:
      process.env.LOGIN_ORGANIZATION_ID ??
      "10000000-0000-4000-8000-000000000001",
    REDIS_URL: url(process.env.REDIS_URL),
  })
    .map(([k, v]) => `${k}=${v}`)
    .join("\n"),
  { mode: 0o600 },
);
try {
  execFileSync(
    docker,
    [
      "run",
      "-d",
      "--name",
      name,
      "--env-file",
      file,
      "-p",
      "127.0.0.1:54000:4000",
      "defence-garden-hr:phase6-local",
    ],
    { stdio: "pipe" },
  );
  let ready = false;
  for (let i = 0; i < 30; i++) {
    try {
      if ((await fetch("http://127.0.0.1:54000/health/ready")).ok) {
        ready = true;
        break;
      }
    } catch {}
    await new Promise((r) => setTimeout(r, 500));
  }
  assert.ok(ready, "Container readiness");
  const r = await fetch("http://127.0.0.1:54000/");
  assert.equal(r.status, 200);
  assert.match(await r.text(), /<div id="root">/);
  assert.equal((await fetch("http://127.0.0.1:54000/.env")).status, 404);
  const who = execFileSync(docker, ["exec", name, "id", "-u"], {
    encoding: "utf8",
  }).trim();
  assert.notEqual(who, "0");
  console.log(
    "PASS: non-root production container, real DB/Redis readiness, bundled web page and private-file denial. No migration credentials injected.",
  );
} finally {
  try {
    execFileSync(docker, ["rm", "-f", name], { stdio: "pipe" });
  } finally {
    await rm(file, { force: true });
  }
}
