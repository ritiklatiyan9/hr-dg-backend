import sharp from "sharp";
import { emptyDwr } from "../../packages/contracts/dwr.js";
import { DeleteObjectCommand } from "@aws-sdk/client-s3";
import { objectStorage } from "../../apps/api/src/files.js";
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { randomBytes, randomUUID } from "node:crypto";
import type pg from "pg";
import type { FastifyInstance } from "fastify";
import { pool, scoped } from "../../packages/db/src/index.js";
import { migrate } from "../../packages/db/src/migrate.js";
import { seed, ids } from "../../packages/db/src/seed.js";
import { createApp } from "../../apps/api/src/app.js";
import { AuthService } from "../../apps/api/src/auth.js";
import { totp, decrypt } from "../../apps/api/src/security.js";
import {
  catalogue,
  permissionKeys,
} from "../../packages/authz/src/catalogue.js";
let app: FastifyInstance,
  owner: pg.Pool,
  runtime: pg.Pool,
  authPool: pg.Pool,
  control: pg.Pool,
  auth: AuthService,
  dbName: string;
const password = randomBytes(24).toString("hex"),
  encryptionKey = randomBytes(32).toString("hex"),
  tokens: Record<string, string> = {};
let loginSequence = 1;
async function signIn(email: string) {
  const remoteAddress = `127.0.1.${loginSequence++}`;
  const response = await app.inject({
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
  assert.equal(response.statusCode, 200);
  const data = response.json();
  if (data.mfaRequired) {
    let secret: string;
    if (data.enrollmentRequired)
      secret = (
        await app.inject({
          remoteAddress,
          method: "POST",
          url: "/auth/mfa/setup",
          headers: { authorization: `Bearer ${data.accessToken}` },
          payload: {},
        })
      ).json().secret;
    else {
      const row = (
        await owner.query("SELECT mfa_secret FROM auth.users WHERE email=$1", [
          email,
        ])
      ).rows[0];
      secret = decrypt(row.mfa_secret, encryptionKey);
      await owner.query(
        "UPDATE auth.users SET last_totp_step=-1 WHERE email=$1",
        [email],
      );
    }
    const verified = await app.inject({
      remoteAddress,
      method: "POST",
      url: "/auth/mfa/verify",
      headers: { authorization: `Bearer ${data.accessToken}` },
      payload: { code: totp(secret).generate() },
    });
    assert.equal(verified.statusCode, 200);
  }
  return data.accessToken as string;
}
async function gql(
  token: string,
  query: string,
  variables: Record<string, unknown> = {},
  pv?: number,
) {
  return (
    await app.inject({
      method: "POST",
      url: "/graphql",
      headers: {
        authorization: `Bearer ${token}`,
        ...(pv ? { "x-permission-version": String(pv) } : {}),
      },
      payload: { query, variables },
    })
  ).json();
}
const accessQuery =
  "query($s:ID!,$u:ID!){userAccess(siteId:$s,userId:$u){id version role active protected rules{key effect scope} delegations{key scope} effective{key decision{allowed scope rule}} audit{id reason version}}}";
async function snapshot(
  userId: string,
  siteId = ids.dg,
  token = tokens.super_admin!,
) {
  const r = await gql(token, accessQuery, { s: siteId, u: userId });
  assert.ok(r.data?.userAccess, JSON.stringify(r.errors));
  return r.data.userAccess;
}
const accessMutation = (save = false) =>
  `mutation($s:ID!,$u:ID!,$i:AccessChangeInput!){${save ? "saveAccess" : "previewAccess"}(siteId:$s,userId:$u,input:$i){version changes{key before{allowed scope rule} after{allowed scope rule}}}}`;
const changeInput = (s: any, patch: any = {}) => ({
  expectedVersion: s.version,
  role: s.role,
  active: s.active,
  rules: s.rules,
  delegations: s.delegations,
  reason: "Reviewed synthetic test change",
  ...patch,
});
async function foundation(
  token: string,
  operation: string,
  input: Record<string, unknown>,
  siteId = ids.dg,
) {
  return gql(
    token,
    "mutation($s:ID!,$op:String!,$i:FoundationInput!){saveFoundation(siteId:$s,operation:$op,input:$i){id status version}}",
    { s: siteId, op: operation, i: input },
  );
}
before(
  async () => {
    const root = process.env.TEST_MIGRATION_DATABASE_URL!;
    if (!root || new URL(root).pathname != "/hr_test")
      throw Error("Isolated real PostgreSQL test configuration required");
    control = pool(root, 1);
    dbName = `hr_test_${randomBytes(8).toString("hex")}`;
    await control.query(`CREATE DATABASE ${dbName}`);
    const url = (base: string) => {
      const u = new URL(base);
      u.pathname = `/${dbName}`;
      return u.toString();
    };
    await migrate(url(root));
    await seed(url(root), password);
    owner = pool(url(root), 1);
    runtime = pool(url(process.env.TEST_DATABASE_URL!), 2);
    authPool = pool(url(process.env.TEST_AUTH_DATABASE_URL!), 2);
    const config = {
      NODE_ENV: "test" as const,
      PORT: 4000,
      DATABASE_URL: url(process.env.TEST_DATABASE_URL!),
      AUTH_DATABASE_URL: url(process.env.TEST_AUTH_DATABASE_URL!),
      LOGIN_ORGANIZATION_ID: ids.org,
      WEB_ORIGIN: "http://localhost:5173",
      COOKIE_SECURE: "true" as const,
      ENCRYPTION_KEY: encryptionKey,
      REDIS_URL: "redis://localhost:56379",
    };
    app = await createApp(config, runtime, authPool, false);
    auth = new AuthService(authPool, config);
    for (const [role, email] of [
      ["super_admin", "superadmin"],
      ["admin", "admin"],
      ["hr", "hr"],
      ["jr_hr", "junior"],
      ["employee", "employee"],
      ["manager", "manager"],
      ["supervisor", "supervisor"],
    ])
      tokens[role!] = await signIn(`${email}@example.test`);
  },
  { timeout: 60000 },
);
after(async () => {
  if (owner) {
    const keys = (await owner.query("SELECT object_key FROM app.dwr_voice"))
      .rows;
    for (const r of keys)
      await objectStorage().send(
        new DeleteObjectCommand({
          Bucket: process.env.S3_BUCKET ?? "hr-private",
          Key: r.object_key,
        }),
      );
  }
  await app?.close();
  await Promise.all([owner?.end(), runtime?.end(), authPool?.end()]);
  if (control && dbName) {
    await control.query(`DROP DATABASE IF EXISTS ${dbName}`);
    await control.end();
  }
});

const op = async (
  role: string,
  operation: string,
  input: any,
  site = ids.dg,
) => {
  const result = await gql(
    tokens[role]!,
    "mutation($s:ID!,$o:String!,$i:JSON!){dwrCommand(siteId:$s,operation:$o,input:$i)}",
    { s: site, o: operation, i: input },
  );
  return result;
};
const snap = (role: string, site = ids.dg) =>
  gql(tokens[role]!, "query($s:ID!){dwr(siteId:$s)}", { s: site });
const value = (r: any) => {
  assert.ok(r.data?.dwrCommand, JSON.stringify(r.errors));
  return r.data.dwrCommand;
};
const content = {
  ...emptyDwr(),
  completed: [
    "Checked records.",
    "Worked on registry-data optimization.",
    "Prepared payrolls.",
  ],
};
let report: any;
test("DWR site policy configured only by administrator with concurrency", async () => {
  const settings = {
    deadline: "18:00",
    deadlineDayOffset: 0,
    reminderMinutes: 30,
    amendments: true,
    offlineDrafts: true,
    expectedVersion: 0,
    reason: "Synthetic DWR acceptance configuration",
  };
  assert.equal(
    (await op("employee", "settings", settings)).errors[0].extensions.code,
    "FORBIDDEN",
  );
  value(await op("super_admin", "settings", settings));
  assert.equal(
    (await op("super_admin", "settings", settings)).errors[0].extensions.code,
    "CONFLICT",
  );
});
test("canonical draft retries, same-date duplicates, conflicting edits and site isolation", async () => {
  const input = {
    clientId: randomUUID(),
    expectedVersion: 0,
    workDate: "2026-09-20",
    content,
    attachments: [],
  };
  report = value(await op("employee", "save", input));
  assert.deepEqual(value(await op("employee", "save", input)), report);
  assert.equal(
    (await op("employee", "save", { ...input, clientId: randomUUID() }))
      .errors[0].extensions.code,
    "CONFLICT",
  );
  const edit = {
    ...input,
    clientId: randomUUID(),
    expectedVersion: report.version,
  };
  const edits = await Promise.all([
    op("employee", "save", edit),
    op("employee", "save", { ...edit, clientId: randomUUID() }),
  ]);
  assert.equal(edits.filter((r) => r.data?.dwrCommand).length, 1);
  report = value(edits.find((r) => r.data?.dwrCommand));
  assert.equal((await snap("employee", ids.rg)).data.dwr.reports.length, 0);
  assert.equal((await snap("supervisor")).data.dwr.reports.length, 0);
  assert.equal((await snap("hr")).data.dwr.reports.length, 0);
  assert.ok((await snap("employee", ids.otherSite)).errors);
});
test("explicit submission retry after commit, review authorization and history", async () => {
  const input = {
    id: report.id,
    clientId: randomUUID(),
    expectedVersion: report.version,
    confirmed: true,
  };
  report = value(await op("employee", "submit", input));
  assert.deepEqual(value(await op("employee", "submit", input)), report);
  assert.equal(
    (await op("employee", "submit", { ...input, clientId: randomUUID() }))
      .errors[0].extensions.code,
    "CONFLICT",
  );
  for (const role of ["employee", "manager", "supervisor", "jr_hr"]) {
    assert.ok(
      ["FORBIDDEN", "NOT_FOUND"].includes(
        (
          await op(role, "review", {
            id: report.id,
            clientId: randomUUID(),
            expectedVersion: report.version,
            decision: "approve",
            reason: "Synthetic independent review",
          })
        ).errors[0].extensions.code,
      ),
    );
  }
  const views = (await snap("hr")).data.dwr.reports;
  assert.equal(views.length, 1);
  assert.equal(views[0].content.sourceTranscript, "");
  await owner.query(
    "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) SELECT $1,$2,$3,k,'allow','team' FROM unnest(ARRAY['dwr_review.view','dwr_review.review']) k",
    [ids.org, ids.dg, ids.manager],
  );
  assert.equal((await snap("manager")).data.dwr.reports.length, 1);
  report = value(
    await op("manager", "review", {
      id: report.id,
      clientId: randomUUID(),
      expectedVersion: report.version,
      decision: "comment",
      reason: "Synthetic assigned-team review comment",
    }),
  );
  await owner.query(
    "UPDATE app.team_assignments SET ends_on=current_date-1 WHERE organization_id=$1 AND site_id=$2 AND manager_id=$3",
    [ids.org, ids.dg, ids.manager],
  );
  assert.equal(
    (await snap("manager")).data.dwr.reports.length,
    0,
    "Team grant cannot see an employee outside current assigned team",
  );
  assert.ok(
    (
      await op("manager", "review", {
        id: report.id,
        clientId: randomUUID(),
        expectedVersion: report.version,
        decision: "comment",
        reason: "Former team cannot review",
      })
    ).errors,
  );
  report = value(
    await op("hr", "review", {
      id: report.id,
      clientId: randomUUID(),
      expectedVersion: report.version,
      decision: "return",
      reason: "Please clarify pending work",
    }),
  );
  assert.equal(report.status, "returned");
  const history = (await snap("employee")).data.dwr.reports[0].history;
  assert.equal(history[0].event, "return");
});
test("returned revision, double approval and explicit approved amendment", async () => {
  report = value(
    await op("employee", "save", {
      clientId: randomUUID(),
      expectedVersion: report.version,
      workDate: "2026-09-20",
      content: {
        ...content,
        pending: ["Awaiting details"],
        stated: { ...content.stated, pending: "reported" },
      },
      attachments: [],
    }),
  );
  report = value(
    await op("employee", "submit", {
      id: report.id,
      clientId: randomUUID(),
      expectedVersion: report.version,
      confirmed: true,
    }),
  );
  const input = {
    id: report.id,
    expectedVersion: report.version,
    decision: "approve",
    reason: "Reviewed reported work details",
  };
  const results = await Promise.all([
    op("hr", "review", { ...input, clientId: randomUUID() }),
    op("hr", "review", { ...input, clientId: randomUUID() }),
  ]);
  assert.equal(results.filter((r) => r.data?.dwrCommand).length, 1);
  report = value(results.find((r) => r.data?.dwrCommand));
  assert.equal(
    (
      await op("employee", "save", {
        clientId: randomUUID(),
        expectedVersion: report.version,
        workDate: "2026-09-20",
        content,
        attachments: [],
      })
    ).errors[0].extensions.code,
    "CONFLICT",
  );
  report = value(
    await op("employee", "amend", {
      id: report.id,
      clientId: randomUUID(),
      expectedVersion: report.version,
      reason: "Add a missing reported detail",
    }),
  );
  assert.equal(report.status, "draft");
  assert.ok((await snap("employee")).data.dwr.reports[0].approved_revision);
});
test("protected print requires fresh access and never truncates overflow", async () => {
  const r = await app.inject({
    method: "GET",
    url: `/dwr/${report.id}/print?siteId=${ids.dg}`,
    headers: { authorization: `Bearer ${tokens.employee}` },
  });
  assert.equal(r.statusCode, 200);
  assert.match(r.body, /additional pages/);
  const forbidden = await app.inject({
    method: "GET",
    url: `/dwr/${report.id}/print?siteId=${ids.dg}`,
    headers: { authorization: `Bearer ${tokens.supervisor}` },
  });
  assert.equal(forbidden.statusCode, 404);
});
test("unconfigured DWR agent is reported honestly; arbitrary identity rejected; voice upload is gone", async () => {
  const agent = (await snap("employee")).data.dwr.agent;
  assert.equal(agent.configured, false);
  assert.equal(agent.online, false);
  const invalid = await op("employee", "save", {
    clientId: randomUUID(),
    expectedVersion: 0,
    workDate: "2026-09-20",
    content,
    attachments: [],
    userId: ids.admin,
  });
  assert.equal(invalid.errors[0].extensions.code, "BAD_INPUT");
  const voice = await app.inject({
    method: "POST",
    url: `/dwr/voice/${randomUUID()}/audio?siteId=${ids.dg}&workDate=2026-09-20`,
    headers: {
      authorization: `Bearer ${tokens.employee}`,
      "content-type": "application/octet-stream",
    },
    payload: Buffer.from("invalid"),
  });
  assert.equal(voice.statusCode, 404);
});

test("DWR attachments cannot cross reports, sites or employee/reviewer scope", async () => {
  const bytes = await sharp({
    create: { width: 3, height: 3, channels: 3, background: "#147852" },
  })
    .jpeg()
    .toBuffer();
  const intent = value(
    await op("employee", "fileIntent", {
      clientId: randomUUID(),
      id: report.id,
      type: "image/jpeg",
      bytes: bytes.length,
    }),
  );
  const url = `/files/intents/${intent.id}/content?siteId=${ids.dg}`;
  const uploaded = await app.inject({
    method: "POST",
    url,
    headers: {
      authorization: `Bearer ${tokens.employee}`,
      "content-type": "application/octet-stream",
    },
    payload: bytes,
  });
  assert.equal(uploaded.json().status, "ready");
  const forbidden = await app.inject({
    method: "GET",
    url: `/files/attachments/${intent.id}?siteId=${ids.dg}`,
    headers: { authorization: `Bearer ${tokens.supervisor}` },
  });
  assert.equal(forbidden.statusCode, 404);
  const wrong = await app.inject({
    method: "POST",
    url: `/files/intents/${intent.id}/content?siteId=${ids.rg}`,
    headers: {
      authorization: `Bearer ${tokens.employee}`,
      "content-type": "application/octet-stream",
    },
    payload: bytes,
  });
  assert.equal(wrong.statusCode, 404);
  const key = (
    await owner.query("SELECT object_key FROM app.private_files WHERE id=$1", [
      intent.id,
    ])
  ).rows[0].object_key;
  for (const suffix of ["/content", "/quarantine"])
    await objectStorage().send(
      new DeleteObjectCommand({
        Bucket: process.env.S3_BUCKET ?? "hr-private",
        Key: key + suffix,
      }),
    );
});

test("worker reminders are durable and idempotent; retained audio cleanup is bounded", async () => {
  await owner.query(
    "UPDATE app.dwr_settings SET deadline='00:00',deadline_day_offset=0,reminder_minutes=0 WHERE site_id=$1",
    [ids.dg],
  );
  const c = await owner.connect();
  try {
    await c.query("BEGIN");
    await c.query("SET LOCAL ROLE hr_worker");
    await c.query("SELECT app.dwr_tick()");
    await c.query("SELECT app.dwr_tick()");
    await c.query("COMMIT");
  } finally {
    c.release();
  }
  const count = (
    await owner.query(
      "SELECT count(*)::int n FROM app.inbox_items WHERE user_id=$1 AND event_type LIKE 'dwr.reminder.%'",
      [ids.employee],
    )
  ).rows[0].n;
  assert.equal(count, 1);
  // Voice capture was removed; audio retained from earlier releases is still deleted.
  await owner.query(
    "INSERT INTO app.dwr_voice(id,organization_id,site_id,employee_id,user_id,work_date,content_hash,object_key,seconds,status,expires_at) VALUES($1,$2,$3,$4,$5,'2026-09-20','synthetic',$6,1,'uploaded',now()-interval '1 minute')",
    [
      randomUUID(),
      ids.org,
      ids.dg,
      ids.employeeProfile,
      ids.employee,
      `${ids.org}/${ids.dg}/dwr-audio/synthetic-retained`,
    ],
  );
  const expired = (await owner.query("SELECT * FROM app.dwr_expired_audio()"))
    .rows;
  assert.ok(expired.length > 0);
  assert.ok(expired.length <= 20);
  for (const r of expired) {
    await objectStorage().send(
      new DeleteObjectCommand({
        Bucket: process.env.S3_BUCKET ?? "hr-private",
        Key: r.object_key,
      }),
    );
    await owner.query("SELECT app.dwr_audio_deleted($1)", [r.id]);
  }
  assert.equal(
    (await owner.query("SELECT * FROM app.dwr_expired_audio()")).rows.length,
    0,
  );
});

test("revoked membership rejects old draft submission and cached requests", async () => {
  await owner.query(
    "UPDATE app.site_memberships SET active=false WHERE organization_id=$1 AND site_id=$2 AND user_id=$3",
    [ids.org, ids.dg, ids.employee],
  );
  const r = await op("employee", "submit", {
    id: report.id,
    clientId: randomUUID(),
    expectedVersion: report.version,
    confirmed: true,
  });
  assert.ok(r.errors);
  const print = await app.inject({
    method: "GET",
    url: `/dwr/${report.id}/print?siteId=${ids.dg}`,
    headers: { authorization: `Bearer ${tokens.employee}` },
  });
  assert.ok(print.statusCode >= 400);
});
