import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { fixture } from "./fixture.js";
import { ids } from "../../packages/db/src/seed.js";
let f: Awaited<ReturnType<typeof fixture>>;
let employee: string;
before(
  async () => {
    f = await fixture("push");
    employee = (await f.login("employee@example.test")).token;
  },
  { timeout: 90000 },
);
after(() => f?.close());
const register = (token: string, site = ids.dg) =>
  f.app.inject({
    method: "POST",
    url: "/notifications/register",
    headers: { authorization: `Bearer ${employee}` },
    payload: { siteId: site, token, platform: "android" },
  });
const item = (site: string, event: string, age = "0 minutes") =>
  f.owner
    .query(
      "INSERT INTO app.inbox_items(organization_id,site_id,user_id,module,entity_id,event_type,created_at) VALUES($1,$2,$3,'attendance',gen_random_uuid(),$4,now()-$5::interval) RETURNING id",
      [ids.org, site, ids.employee, event, age],
    )
    .then((r) => r.rows[0].id as string);
test("one device receives visible pushes from every site its user can open, never a replayed backlog", async () => {
  const old = await item(ids.dg, "attendance.accepted", "3 days");
  const token = "synthetic-push-token-".padEnd(40, "x");
  assert.equal((await register(token)).statusCode, 200);
  assert.equal((await register(token)).statusCode, 200);
  const active = await f.owner.query(
    "SELECT id FROM app.push_devices WHERE user_id=$1 AND active",
    [ids.employee],
  );
  assert.equal(active.rowCount, 1, "same token re-registers without a new row");
  // Registered at Defence Garden; an item raised at River Green still pushes.
  const river = await item(ids.rg, "attendance.review_required");
  const rows = (await f.owner.query("SELECT * FROM app.pending_operation_push()")).rows;
  assert.deepEqual(
    rows.map((r) => [r.inbox_id, r.event_type, r.device_id]),
    [[river, "attendance.review_required", active.rows[0].id]],
    "the 3-day-old item is not replayed",
  );
  assert.ok(!rows.some((r) => r.inbox_id === old));
  // Losing the site membership stops pushes for that site.
  await f.owner.query(
    "UPDATE app.site_memberships SET active=false WHERE user_id=$1 AND site_id=$2",
    [ids.employee, ids.rg],
  );
  assert.equal(
    (await f.owner.query("SELECT * FROM app.authorized_operation_push($1)", [river])).rowCount,
    0,
  );
  await f.owner.query("SELECT app.retire_push_device($1)", [active.rows[0].id]);
  await item(ids.dg, "attendance.accepted");
  assert.equal(
    (await f.owner.query("SELECT * FROM app.pending_operation_push()")).rowCount,
    0,
    "a retired device receives nothing",
  );
});
