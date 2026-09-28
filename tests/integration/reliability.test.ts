import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { Queue, Worker, QueueEvents } from "bullmq";
import { fixture } from "./fixture.js";
import { transaction } from "../../packages/db/src/index.js";
import { ids } from "../../packages/db/src/seed.js";
test("push leases skip missing devices and freshly reject revoked recipients without losing inbox", async () => {
  const f = await fixture("push");
  try {
    await f.owner.query(
      "INSERT INTO app.inbox_items(organization_id,site_id,user_id,module,entity_id,event_type,created_at) SELECT $1,$2,$3,'attendance',gen_random_uuid(),'synthetic',now()-interval '1 hour' FROM generate_series(1,12)",
      [ids.org, ids.dg, ids.admin],
    );
    const id = randomUUID();
    await f.owner.query(
      "INSERT INTO app.inbox_items(id,organization_id,site_id,user_id,module,entity_id,event_type) VALUES($1,$2,$3,$4,'attendance',$1,'synthetic')",
      [id, ids.org, ids.dg, ids.employee],
    );
    await f.owner.query(
      "INSERT INTO app.push_devices(organization_id,site_id,user_id,token_ciphertext,platform) VALUES($1,$2,$3,'SYNTHETIC_NOT_A_REAL_FCM_TOKEN','android')",
      [ids.org, ids.dg, ids.employee],
    );
    const query = (sql: string, params: unknown[] = []) =>
      transaction(f.owner, async (c) => {
        await c.query("SET LOCAL ROLE hr_worker");
        return c.query(sql, params);
      });
    assert.deepEqual(
      (await query("SELECT * FROM app.pending_operation_push()")).rows.map(
        (r) => r.inbox_id,
      ),
      [id],
    );
    assert.equal(
      (await query("SELECT * FROM app.pending_operation_push()")).rowCount,
      0,
    );
    assert.equal(
      (await query("SELECT * FROM app.authorized_operation_push($1)", [id]))
        .rowCount,
      1,
    );
    await f.owner.query(
      "UPDATE app.site_memberships SET active=false WHERE user_id=$1 AND site_id=$2",
      [ids.employee, ids.dg],
    );
    assert.equal(
      (await query("SELECT * FROM app.authorized_operation_push($1)", [id]))
        .rowCount,
      0,
    );
    assert.equal(
      (
        await f.owner.query(
          "SELECT push_status FROM app.inbox_items WHERE id=$1",
          [id],
        )
      ).rows[0].push_status,
      "unconfigured",
    );
    await assert.rejects(() =>
      f.runtime.query("SELECT * FROM app.authorized_operation_push($1)", [id]),
    );
  } finally {
    await f.close();
  }
});

test(
  "Redis outage rolls publication back; retry after queue commit deduplicates job ID",
  { timeout: 30000 },
  async () => {
    const f = await fixture("reliability");
    const name = `phase6-${randomUUID()}`,
      id = randomUUID();
    const connection = { host: "127.0.0.1", port: 56379 };
    const queue = new Queue(name, { connection });
    const events = new QueueEvents(name, { connection });
    let processed = 0;
    const worker = new Worker(
      name,
      async () => {
        processed++;
      },
      { connection, autorun: false },
    );
    const unavailable = new Queue(`offline-${name}`, {
      connection: {
        host: "127.0.0.1",
        port: 1,
        connectTimeout: 200,
        commandTimeout: 500,
        maxRetriesPerRequest: 1,
        enableOfflineQueue: false,
        retryStrategy: () => null,
      },
    });
    unavailable.on("error", () => {});
    try {
      await queue.waitUntilReady();
      await events.waitUntilReady();
      await f.owner.query(
        "INSERT INTO app.outbox(id,organization_id,site_id,event_type,payload) VALUES($1,$2,$3,'foundation.updated','{}')",
        [id, ids.org, ids.dg],
      );
      const publish = async (q: Queue, crash = false) =>
        transaction(f.owner, async (c) => {
          const row = (
            await c.query(
              "SELECT * FROM app.outbox WHERE id=$1 AND published_at IS NULL FOR UPDATE",
              [id],
            )
          ).rows[0];
          if (!row) return;
          await q.add(
            row.event_type,
            { eventId: id },
            { jobId: id, removeOnComplete: false },
          );
          if (crash) throw Error("Synthetic failure after Redis commit");
          await c.query(
            "UPDATE app.outbox SET published_at=now() WHERE id=$1",
            [id],
          );
        });
      await assert.rejects(() => publish(unavailable));
      assert.equal(
        (
          await f.owner.query(
            "SELECT published_at FROM app.outbox WHERE id=$1",
            [id],
          )
        ).rows[0].published_at,
        null,
      );
      await assert.rejects(() => publish(queue, true));
      await publish(queue);
      await publish(queue);
      const job = await queue.getJob(id);
      assert.ok(job);
      const running = worker.run();
      await job.waitUntilFinished(events, 5000);
      assert.equal(processed, 1);
      assert.equal(await queue.getCompletedCount(), 1);
      await worker.close();
      await running;
    } finally {
      await worker.close();
      await events.close();
      await unavailable.close();
      await queue.obliterate({ force: true });
      await queue.close();
      await f.close();
    }
  },
);
