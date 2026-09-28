import { Queue, Worker } from "bullmq";
import { validateCloudEnvironment } from "../../../packages/config/src/cloud.js";
import nodemailer from "nodemailer";
import {
  pool,
  transaction,
  assertRuntimeRole,
} from "../../../packages/db/src/index.js";
import { decrypt } from "../../api/src/security.js";
import { z } from "zod";
import { FcmAdapter, StaleToken, pushText } from "./fcm.js";
import { objectStorage } from "../../api/src/files.js";
import { DeleteObjectCommand } from "@aws-sdk/client-s3";
import {
  AgentError,
  HttpDwrAgent,
  agentSetup,
} from "../../api/src/dwr-provider.js";
validateCloudEnvironment(process.env, "worker");
if (process.env.NODE_ENV === "production" && process.env.MIGRATION_DATABASE_URL)
  throw new Error(
    "Migration credentials must not be present in the worker environment",
  );
const fcm = new FcmAdapter();
const url = process.env.WORKER_DATABASE_URL;
if (!url) throw new Error("WORKER_DATABASE_URL required");
const key = process.env.ENCRYPTION_KEY;
if (!key) throw new Error("ENCRYPTION_KEY required");
const db = pool(url, 2);
await assertRuntimeRole(db, "hr_worker");
const redis = new URL(process.env.REDIS_URL ?? "redis://localhost:56379");
const connection = {
  host: redis.hostname,
  port: Number(redis.port || 6379),
  ...(redis.password ? { password: decodeURIComponent(redis.password) } : {}),
  ...(redis.username ? { username: decodeURIComponent(redis.username) } : {}),
  ...(redis.protocol === "rediss:"
    ? { tls: { servername: redis.hostname } }
    : {}),
  connectTimeout: 5000,
  maxRetriesPerRequest: null,
};
// A publisher must fail promptly during a Redis outage so its DB transaction
// rolls back. A consuming worker may keep reconnecting independently.
const queue = new Queue("hr-events", {
  connection: {
    ...connection,
    maxRetriesPerRequest: 1,
    commandTimeout: 3000,
    enableOfflineQueue: false,
  },
});
queue.on("error", () => console.error("Queue publication unavailable"));
const smtp = nodemailer.createTransport({
  connectionTimeout: 5000,
  greetingTimeout: 5000,
  socketTimeout: 8000,
  host: process.env.SMTP_HOST ?? "localhost",
  port: Number(process.env.SMTP_PORT ?? 51025),
  secure: process.env.SMTP_SECURE === "true",
  requireTLS: process.env.NODE_ENV === "production",
  ...(process.env.SMTP_USER
    ? { auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASSWORD } }
    : {}),
  disableFileAccess: true,
  disableUrlAccess: true,
});
const worker = new Worker(
  "hr-events",
  async (job) => {
    if (job.name === "operations.changed") {
      z.object({
        module: z.enum([
          "attendance",
          "leave",
          "tasks",
          "field_duty",
          "my_dwr",
          "dwr_review",
          "my_payroll",
          "my_documents",
          "expenses",
          "assets",
          "helpdesk",
          "grievances",
          "employees",
          "announcements",
        ]),
        entityId: z.uuid(),
        recipientId: z.uuid(),
      }).parse(job.data.payload);
      return; // Durable inbox was committed before this notification event.
    }
    if (job.name === "access.updated") {
      z.object({ userId: z.uuid(), version: z.number().int() }).parse(
        job.data.payload,
      );
      return;
    }
    if (job.name === "foundation.updated") {
      z.object({ entityId: z.uuid(), operation: z.string() }).parse(
        job.data.payload,
      );
      return;
    }
    if (job.name !== "employee.profile_updated")
      throw new Error("Unrecognized event");
    // Phase 1 acknowledges a PII-free event; future consumers must be idempotent.
    z.object({ employeeId: z.uuid(), version: z.number().int() }).parse(
      job.data.payload,
    );
  },
  { connection, concurrency: 2 },
);
worker.on("error", () => console.error("Worker connection failure"));
let stopping = false;
async function poll() {
  while (!stopping) {
    try {
      await transaction(db, (c) =>
        c.query("SELECT app.dwr_tick(), app.hr_tick()"),
      );
      const expired = (await db.query("SELECT * FROM app.dwr_expired_audio()"))
        .rows;
      for (const row of expired) {
        await objectStorage().send(
          new DeleteObjectCommand({
            Bucket: process.env.S3_BUCKET ?? "hr-private",
            Key: row.object_key,
          }),
        );
        await db.query("SELECT app.dwr_audio_deleted($1)", [row.id]);
      }
      if (fcm.configured) {
        const candidates = (
          await transaction(db, (c) =>
            c.query("SELECT * FROM app.pending_operation_push()"),
          )
        ).rows;
        for (const id of new Set(candidates.map((r) => r.inbox_id))) {
          // Fresh authorization outside the claiming transaction.
          const devices = (
            await transaction(db, (c) =>
              c.query("SELECT * FROM app.authorized_operation_push($1)", [id]),
            )
          ).rows;
          if (!devices.length) continue;
          const { site, module, event_type, entity_id } = devices[0];
          const sent = new Set<string>();
          let delivered = false;
          for (const d of devices) {
            const token = decrypt(d.token_ciphertext, key!);
            if (sent.has(token)) continue;
            sent.add(token);
            try {
              await fcm.send(token, pushText(module, event_type), {
                inboxId: id,
                siteId: site,
                module,
                eventType: event_type,
                entityId: entity_id,
              });
              delivered = true;
            } catch (e) {
              if (e instanceof StaleToken)
                await db.query("SELECT app.retire_push_device($1)", [
                  d.device_id,
                ]);
            }
          }
          await db.query("SELECT app.mark_operation_push($1,$2)", [
            id,
            delivered,
          ]);
        }
      }
      await transaction(db, async (c) => {
        await c.query("SELECT app.prepare_exports()");
      });
      await transaction(db, async (c) => {
        const rows = (
          await c.query(
            "SELECT * FROM app.outbox WHERE published_at IS NULL ORDER BY created_at LIMIT 20 FOR UPDATE SKIP LOCKED",
          )
        ).rows;
        for (const r of rows) {
          await queue.add(
            r.event_type,
            {
              organizationId: r.organization_id,
              siteId: r.site_id,
              payload: r.payload,
            },
            {
              jobId: r.id,
              attempts: 5,
              backoff: { type: "exponential", delay: 1000 },
              removeOnComplete: { age: 86400 },
              removeOnFail: { age: 604800 },
            },
          );
          await c.query(
            "UPDATE app.outbox SET published_at=now() WHERE id=$1",
            [r.id],
          );
        }
      });
      await transaction(db, async (c) => {
        const rows = (
          await c.query(
            "SELECT * FROM auth.mail_outbox WHERE sent_at IS NULL AND attempts<5 ORDER BY created_at LIMIT 10 FOR UPDATE SKIP LOCKED",
          )
        ).rows;
        for (const r of rows) {
          try {
            const mail = z
              .object({
                to: z.email(),
                subject: z.string().max(200),
                text: z.string().max(4000),
              })
              .parse(JSON.parse(decrypt(r.encrypted_payload, key!)));
            await smtp.sendMail({
              ...mail,
              from: process.env.SMTP_FROM ?? "hr@example.test",
              messageId: `<${r.id}@hr.local>`,
            });
            await c.query(
              "UPDATE auth.mail_outbox SET sent_at=now(),encrypted_payload=$2 WHERE id=$1",
              [r.id, "[delivered]"],
            );
          } catch {
            await c.query(
              "UPDATE auth.mail_outbox SET attempts=attempts+1 WHERE id=$1",
              [r.id],
            );
            console.error("Mail delivery failed; bounded retry scheduled");
          }
        }
      });
    } catch {
      console.error("Outbox polling failed; retry scheduled");
    }
    if (!stopping) await new Promise((r) => setTimeout(r, 2000));
  }
}
// DWR agent: prepares each employee's own DWR from that day's chat messages.
// Runs beside the poll loop so provider latency never delays outbox or mail.
// Only codes are logged: never message text, names or provider responses.
const agent = new HttpDwrAgent();
let heartbeatAt = 0;
async function agentLoop() {
  while (!stopping) {
    const setup = agentSetup();
    try {
      if (Date.now() - heartbeatAt > 30_000) {
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
        for (const job of jobs) {
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
              AbortSignal.timeout(30_000),
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
            await db.query("SELECT app.dwr_agent_fail($1,$2,$3,$4,$5,$6,$7)", [
              ...key,
              job.lease,
              error.code,
              error.retryAfter,
            ]);
          }
        }
      }
    } catch {
      console.error("DWR agent polling failed; retry scheduled");
    }
    if (!stopping)
      await new Promise((r) => setTimeout(r, setup.configured ? 3000 : 15000));
  }
}
async function stop() {
  stopping = true;
  await worker.close();
  await queue.close();
}
process.once("SIGTERM", stop);
process.once("SIGINT", stop);
await Promise.all([poll(), agentLoop()]);
await db.end();
