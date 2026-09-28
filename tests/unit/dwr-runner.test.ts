import { test } from "node:test";
import assert from "node:assert/strict";
import type pg from "pg";
import { runDwrAgent } from "../../apps/api/src/dwr-agent-runner.js";
import { emptyDwr } from "../../packages/contracts/dwr.js";
test("all claimed DWR jobs start together instead of spending their leases waiting on another provider call", async () => {
  const stop = new AbortController();
  let started = 0,
    stored = 0,
    active = 0,
    peak = 0;
  let release!: () => void;
  const barrier = new Promise<void>((r) => (release = r));
  const jobs = [1, 2, 3].map((n) => ({
    organization_id: "org",
    site_id: "site",
    employee_id: `employee${n}`,
    work_date: "2026-09-29",
    lease: `lease${n}`,
    source_hash: "hash",
    messages: [],
    timezone: "Asia/Kolkata",
  }));
  const query = async (sql: string) => {
    if (sql.includes("dwr_agent_claim")) return { rows: jobs };
    if (sql.includes("dwr_agent_store")) {
      stored++;
      if (stored === 3) stop.abort();
    }
    return { rows: [] };
  };
  const db = {
    query,
    connect: async () => ({ query, release() {} }),
  } as unknown as pg.Pool;
  const timeout = setTimeout(() => {
    stop.abort();
    release();
  }, 1000);
  try {
    await runDwrAgent(
      db,
      stop.signal,
      {
        prepare: async () => {
          started++;
          active++;
          peak = Math.max(peak, active);
          if (started === 3) release();
          await barrier;
          active--;
          return { content: emptyDwr(), provenance: {} as any };
        },
      },
      () => ({
        service: "groq",
        configured: true,
        model: "synthetic",
        provider: null,
        userDaily: 24,
        orgDaily: 2000,
      }),
    );
    assert.equal(started, 3);
    assert.equal(peak, 3);
    assert.equal(stored, 3);
  } finally {
    clearTimeout(timeout);
  }
});
