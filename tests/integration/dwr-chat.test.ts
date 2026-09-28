import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import type pg from "pg";
import { fixture } from "./fixture.js";
import { ids } from "../../packages/db/src/seed.js";
import { scoped } from "../../packages/db/src/index.js";
import { workDate, type Actor } from "../../packages/authz/src/index.js";
import { emptyDwr } from "../../packages/contracts/dwr.js";
let f: Awaited<ReturnType<typeof fixture>>;
const kiranProfile = "40000000-0000-4000-8000-0000000000c1";
const today = () => workDate(new Date(), "Asia/Kolkata");
const who: Record<string, { token: string; actor: Actor }> = {};
async function signIn(name: string, email: string) {
  who[name] = await f.login(email);
}
const gql = async (name: string, query: string, variables: object) =>
  (
    await f.app.inject({
      method: "POST",
      url: "/graphql",
      headers: { authorization: `Bearer ${who[name]!.token}` },
      payload: { query, variables },
    })
  ).json();
const chat = (name: string, input: object, site = ids.dg) =>
  gql(name, "query($s:ID!,$i:JSON!){dwrChat(siteId:$s,input:$i)}", {
    s: site,
    i: input,
  });
const cmd = (name: string, operation: string, input: object, site = ids.dg) =>
  gql(
    name,
    "mutation($s:ID!,$o:String!,$i:JSON!){dwrCommand(siteId:$s,operation:$o,input:$i)}",
    { s: site, o: operation, i: input },
  );
const ok = (r: any) => {
  assert.ok(r.data, JSON.stringify(r.errors));
  return Object.values(r.data)[0] as any;
};
const code = (r: any) => r.errors?.[0]?.extensions?.code;
async function asWorker<T>(fn: (c: pg.PoolClient) => Promise<T>) {
  const c = await f.owner.connect();
  try {
    await c.query("BEGIN");
    await c.query("SET LOCAL ROLE hr_worker");
    const result = await fn(c);
    await c.query("COMMIT");
    return result;
  } catch (e) {
    await c.query("ROLLBACK");
    throw e;
  } finally {
    c.release();
  }
}
const job = async (employee: string) =>
  (
    await f.owner.query(
      "SELECT *,work_date::text AS day FROM app.dwr_agent_jobs WHERE employee_id=$1 AND work_date=$2",
      [employee, today()],
    )
  ).rows[0];
const send = async (
  name: string,
  body: string,
  groupId: string | null = null,
) =>
  ok(await cmd(name, "message", { clientId: randomUUID(), groupId, body }))
    .message;
before(
  async () => {
    f = await fixture();
    // A third synthetic DWR participant: the seeded supervisor gets an employee profile.
    await f.owner.query(
      "INSERT INTO app.employees(id,organization_id,user_id,employee_code,display_name,work_email,job_title,department) VALUES($1,$2,$3,'DG-SUP','Kiran Rao','supervisor@example.test','Supervisor','Operations')",
      [kiranProfile, ids.org, ids.supervisor],
    );
    await f.owner.query(
      "INSERT INTO app.site_assignments(organization_id,site_id,employee_id,starts_on) VALUES($1,$2,$3,'2024-01-01')",
      [ids.org, ids.dg, kiranProfile],
    );
    await signIn("arjun", "employee@example.test");
    await signIn("kiran", "supervisor@example.test");
    await signIn("hr", "hr@example.test");
    await signIn("junior", "junior@example.test");
    await signIn("meera", "river@example.test");
  },
  { timeout: 90000 },
);
after(async () => {
  await f?.close();
});
test("catalogue: everyone deletes own DWR messages; DWR group oversight is site-only administration", async () => {
  const caps = async (name: string) =>
    ok(
      await gql(name, "query($s:ID!){scope(siteId:$s){capabilities}}", {
        s: ids.dg,
      }),
    ).capabilities as string[];
  const employee = await caps("arjun");
  assert.ok(employee.includes("my_dwr.delete"));
  assert.ok(!employee.some((c) => c.startsWith("dwr_groups.")));
  const hr = await caps("hr");
  for (const a of ["view", "create", "edit", "delete"])
    assert.ok(hr.includes(`dwr_groups.${a}`));
  const junior = await caps("junior");
  assert.ok(junior.includes("dwr_groups.edit"));
  assert.ok(!junior.includes("dwr_groups.delete"));
  const c = await f.owner.connect();
  try {
    await c.query("BEGIN");
    await c.query("SELECT set_config('app.organization_id',$1,true)", [
      ids.org,
    ]);
    const d = (
      await c.query(
        "SELECT app.policy_decision($1,$2,'dwr_groups.view',NULL,$3) d",
        [
          ids.manager,
          ids.dg,
          {
            role: "manager",
            active: true,
            rules: [{ key: "dwr_groups.view", effect: "allow", scope: "team" }],
          },
        ],
      )
    ).rows[0].d;
    assert.deepEqual([d.allowed, d.rule], [false, "invalid_module_scope"]);
    await c.query("ROLLBACK");
  } finally {
    c.release();
  }
});
test("personal DWR agent chat: idempotent send, month thread, edit/delete history and per-user denial", async () => {
  const clientId = randomUUID();
  const first = ok(
    await cmd("arjun", "message", {
      clientId,
      groupId: null,
      body: "  aaj site par pipes ki inspection ki  ",
    }),
  ).message;
  assert.equal(first.workDate, today());
  assert.equal(
    ok(
      await cmd("arjun", "message", {
        clientId,
        groupId: null,
        body: "aaj site par pipes ki inspection ki",
      }),
    ).message.id,
    first.id,
    "A retried send never duplicates the message",
  );
  assert.equal(
    code(
      await cmd("arjun", "message", {
        clientId,
        groupId: null,
        body: "different text",
      }),
    ),
    "CONFLICT",
  );
  const thread = ok(await chat("arjun", { view: "thread", groupId: null }));
  assert.equal(thread.month, today().slice(0, 7));
  assert.equal(thread.thread.canPost, true);
  const mine = thread.messages.find((m: any) => m.id === first.id);
  assert.equal(mine.body, "aaj site par pipes ki inspection ki");
  assert.ok(mine.mine && mine.canEdit && mine.canDelete);
  // Personal chats are private: other employees cannot open them.
  assert.equal(
    ok(await chat("kiran", { view: "thread", groupId: null })).messages.length,
    0,
  );
  assert.equal(
    code(
      await chat("kiran", {
        view: "day",
        employeeId: ids.employeeProfile,
        workDate: today(),
      }),
    ),
    "FORBIDDEN",
  );
  const edited = ok(
    await cmd("arjun", "editMessage", {
      id: first.id,
      expectedVersion: 1,
      body: "Site par pipes ki inspection ki, 2 leaks mile",
    }),
  );
  assert.equal(edited.version, 2);
  assert.equal(
    code(
      await cmd("arjun", "editMessage", {
        id: first.id,
        expectedVersion: 1,
        body: "stale edit",
      }),
    ),
    "CONFLICT",
  );
  const history = (
    await f.owner.query(
      "SELECT event,body,version FROM app.dwr_message_history WHERE message_id=$1 ORDER BY version",
      [first.id],
    )
  ).rows;
  assert.deepEqual(history, [
    { event: "edit", body: "aaj site par pipes ki inspection ki", version: 1 },
  ]);
  const spare = await send("arjun", "yeh message hata dena");
  // HR denies deleting for this one user; editing stays allowed.
  await f.owner.query(
    "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,'my_dwr.delete','deny','own')",
    [ids.org, ids.dg, ids.employee],
  );
  await signIn("arjun", "employee@example.test");
  assert.equal(
    code(
      await cmd("arjun", "deleteMessage", { id: spare.id, expectedVersion: 1 }),
    ),
    "FORBIDDEN",
  );
  assert.equal(
    ok(await chat("arjun", { view: "thread", groupId: null })).messages.find(
      (m: any) => m.id === spare.id,
    ).canDelete,
    false,
  );
  await f.owner.query(
    "DELETE FROM app.access_overrides WHERE user_id=$1 AND key='my_dwr.delete'",
    [ids.employee],
  );
  await signIn("arjun", "employee@example.test");
  ok(await cmd("arjun", "deleteMessage", { id: spare.id, expectedVersion: 1 }));
  const gone = ok(
    await chat("arjun", { view: "thread", groupId: null }),
  ).messages.find((m: any) => m.id === spare.id);
  assert.equal(gone.body, "");
  assert.ok(gone.deletedAt && !gone.canEdit && !gone.deletedByModerator);
  assert.equal(
    (
      await f.owner.query(
        "SELECT body FROM app.dwr_message_history WHERE message_id=$1 AND event='delete'",
        [spare.id],
      )
    ).rows[0].body,
    "yeh message hata dena",
    "Deleted claims stay auditable",
  );
});
let groupId: string;
test("groups: permissioned creation, WhatsApp-style admins, last-admin protection and leave hand-over", async () => {
  const input = {
    clientId: randomUUID(),
    name: "Site Ops",
    description: "Daily site updates",
    members: [
      { userId: ids.employee, admin: true },
      { userId: ids.supervisor, admin: false },
    ],
  };
  assert.equal(code(await cmd("arjun", "createGroup", input)), "FORBIDDEN");
  assert.equal(
    code(
      await cmd("hr", "createGroup", {
        ...input,
        clientId: randomUUID(),
        members: [{ userId: ids.employee, admin: false }],
      }),
    ),
    "BAD_INPUT",
    "A group needs an admin",
  );
  assert.equal(
    code(
      await cmd("hr", "createGroup", {
        ...input,
        clientId: randomUUID(),
        members: [{ userId: ids.river, admin: true }],
      }),
    ),
    "BAD_INPUT",
    "People from another site cannot join",
  );
  const created = ok(await cmd("hr", "createGroup", input));
  groupId = created.id;
  assert.equal(ok(await cmd("hr", "createGroup", input)).id, groupId);
  assert.equal(
    code(await cmd("hr", "createGroup", { ...input, name: "Changed" })),
    "CONFLICT",
  );
  assert.equal(
    code(
      await cmd("hr", "createGroup", {
        ...input,
        clientId: randomUUID(),
        name: " site ops ",
      }),
    ),
    "CONFLICT",
    "Active group names are unique per site",
  );
  // Plain members cannot administer the group.
  for (const [op, body] of [
    [
      "updateGroup",
      { id: groupId, expectedVersion: 1, name: "X Group", description: "" },
    ],
    ["setMemberRole", { id: groupId, userId: ids.employee, role: "member" }],
    ["addMembers", { id: groupId, userIds: [ids.admin] }],
  ] as const)
    assert.equal(code(await cmd("kiran", op, body)), "FORBIDDEN");
  // DB invariant: a member cannot promote themselves even with a direct update.
  await assert.rejects(
    scoped(f.runtime, who.kiran!.actor, ids.dg, (c) =>
      c.query(
        "UPDATE app.dwr_group_members SET role='admin' WHERE group_id=$1 AND user_id=app.actor_id()",
        [groupId],
      ),
    ),
  );
  ok(
    await cmd("arjun", "updateGroup", {
      id: groupId,
      expectedVersion: 1,
      name: "Site Ops",
      description: "Pipes, pumps and daily site work",
    }),
  );
  assert.equal(
    code(
      await cmd("arjun", "updateGroup", {
        id: groupId,
        expectedVersion: 1,
        name: "Site Ops",
        description: "stale",
      }),
    ),
    "CONFLICT",
  );
  ok(
    await cmd("arjun", "setMemberRole", {
      id: groupId,
      userId: ids.supervisor,
      role: "admin",
    }),
  );
  ok(
    await cmd("arjun", "setMemberRole", {
      id: groupId,
      userId: ids.employee,
      role: "member",
    }),
  );
  assert.equal(
    code(
      await cmd("kiran", "setMemberRole", {
        id: groupId,
        userId: ids.supervisor,
        role: "member",
      }),
    ),
    "LAST_GROUP_ADMIN",
  );
  ok(await cmd("kiran", "leaveGroup", { id: groupId }));
  const info = ok(await chat("arjun", { view: "group", groupId }));
  assert.deepEqual(
    info.members.map((m: any) => [m.name, m.role]),
    [["Arjun Mehta", "admin"]],
    "The longest-standing member takes over from the last admin",
  );
  assert.equal(
    code(await chat("kiran", { view: "thread", groupId })),
    "NOT_FOUND",
  );
  assert.equal(
    code(
      await cmd("kiran", "message", {
        clientId: randomUUID(),
        groupId,
        body: "still here?",
      }),
    ),
    "NOT_FOUND",
  );
  const candidates = ok(
    await chat("arjun", { view: "candidates", groupId, search: "kir" }),
  ).people;
  assert.deepEqual(
    candidates.map((p: any) => p.name),
    ["Kiran Rao"],
  );
  assert.deepEqual(Object.keys(candidates[0]).sort(), [
    "employeeId",
    "name",
    "userId",
  ]);
  ok(
    await cmd("arjun", "addMembers", {
      id: groupId,
      userIds: [ids.supervisor],
    }),
  );
  assert.equal(
    ok(await chat("kiran", { view: "group", groupId })).role,
    "member",
  );
  assert.equal(
    code(
      await cmd("junior", "archiveGroup", {
        id: groupId,
        expectedVersion: 2,
        reason: "Synthetic archive check",
      }),
    ),
    "FORBIDDEN",
    "Jr. HR cannot archive groups by default",
  );
});
test("group chat: members read each other with names, HR oversees read-only, moderation and unread counts", async () => {
  const note = await send("arjun", "Pump room ka valve replace kiya", groupId);
  const kiranView = ok(await chat("kiran", { view: "thread", groupId }));
  const seen = kiranView.messages.find((m: any) => m.id === note.id);
  assert.ok(seen && !seen.mine && !seen.canEdit && !seen.canDelete);
  assert.equal(kiranView.people[ids.employee], "Arjun Mehta");
  const home = ok(await chat("kiran", { view: "home" }));
  const listed = home.groups.find((g: any) => g.id === groupId);
  assert.equal(listed.unread, 1);
  assert.equal(listed.last.author, "Arjun Mehta");
  ok(await cmd("kiran", "markRead", { groupId }));
  assert.equal(
    ok(await chat("kiran", { view: "home" })).groups.find(
      (g: any) => g.id === groupId,
    ).unread,
    0,
  );
  const oversight = ok(await chat("hr", { view: "thread", groupId }));
  assert.equal(oversight.thread.canPost, false);
  assert.ok(oversight.messages.some((m: any) => m.id === note.id));
  assert.equal(
    code(
      await cmd("hr", "message", {
        clientId: randomUUID(),
        groupId,
        body: "hi",
      }),
    ),
    "FORBIDDEN",
    "Oversight does not make HR a member",
  );
  assert.equal(
    code(
      await cmd("kiran", "deleteMessage", { id: note.id, expectedVersion: 1 }),
    ),
    "NOT_FOUND",
    "Members cannot delete each other's messages",
  );
  const spam = await send("kiran", "unrelated forwarded message", groupId);
  ok(await cmd("hr", "deleteMessage", { id: spam.id, expectedVersion: 1 }));
  const moderated = ok(
    await chat("kiran", { view: "thread", groupId }),
  ).messages.find((m: any) => m.id === spam.id);
  assert.ok(moderated.deletedByModerator);
  // Another site never sees this group.
  assert.equal(
    ok(await chat("meera", { view: "home" }, ids.rg)).groups.length,
    0,
  );
  assert.equal(
    code(await chat("meera", { view: "thread", groupId }, ids.rg)),
    "NOT_FOUND",
  );
});
test("chat-only DWR: author's day becomes the report, reviewers read sources, submission locks the day", async () => {
  const draft = ok(
    await cmd("arjun", "prepare", { workDate: today(), mode: "chat" }),
  );
  assert.equal(draft.status, "draft");
  assert.equal(
    ok(await cmd("arjun", "prepare", { workDate: today(), mode: "chat" }))
      .version,
    draft.version,
    "Unchanged chat does not create another revision",
  );
  assert.equal(
    code(
      await cmd("kiran", "prepare", {
        workDate: today(),
        employeeId: ids.employeeProfile,
        mode: "chat",
      }),
    ),
    "FORBIDDEN",
  );
  const reviewer = ok(
    await gql("hr", "query($s:ID!){dwr(siteId:$s)}", { s: ids.dg }),
  ).reports.find((r: any) => r.id === draft.id);
  assert.equal(
    reviewer.status,
    "draft",
    "Chat drafts are visible to reviewers",
  );
  assert.equal(reviewer.origin, "chat");
  assert.match(reviewer.content.sourceTranscript, /2 leaks mile/);
  assert.match(reviewer.content.sourceTranscript, /Pump room ka valve/);
  const sources = ok(
    await chat("hr", {
      view: "day",
      employeeId: ids.employeeProfile,
      workDate: today(),
    }),
  ).messages;
  assert.ok(sources.some((m: any) => m.groupId === groupId));
  const submitted = ok(
    await cmd("arjun", "submit", {
      clientId: randomUUID(),
      id: draft.id,
      expectedVersion: draft.version,
      confirmed: true,
    }),
  );
  assert.equal(submitted.status, "submitted");
  const edit = ok(
    await chat("arjun", { view: "thread", groupId: null }),
  ).messages.find((m: any) => !m.deletedAt);
  assert.equal(edit.canEdit, false);
  assert.equal(
    code(
      await cmd("arjun", "editMessage", {
        id: edit.id,
        expectedVersion: edit.version,
        body: "rewriting a submitted claim",
      }),
    ),
    "REPORT_LOCKED",
  );
  const late = ok(
    await cmd("arjun", "message", {
      clientId: randomUUID(),
      groupId: null,
      body: "late note after submitting",
    }),
  );
  assert.equal(late.reportLocked, true);
});
test("agent jobs: quiet-period queue, explicit request, leases, stale sources, manual edits, budgets and revocation", async () => {
  await send("kiran", "Aaj 3 pumps ki servicing ki");
  const queued = await job(kiranProfile);
  assert.equal(queued.status, "queued");
  assert.equal(queued.explicit, false);
  assert.ok(Date.parse(queued.due_at) > Date.now() + 8 * 60_000);
  const claim = (budget = 24) =>
    asWorker(async (c) =>
      (
        await c.query("SELECT * FROM app.dwr_agent_claim(3,$1,2000)", [budget])
      ).rows.filter((r) => r.employee_id === kiranProfile),
    );
  assert.equal((await claim()).length, 0, "Not due until the author is quiet");
  assert.equal(
    ok(await cmd("kiran", "prepare", { workDate: today(), mode: "ai" }))
      .outcome,
    "QUEUED",
  );
  const [first] = await claim();
  assert.ok(first);
  assert.deepEqual(
    first.messages.map((m: any) => m.text),
    ["Aaj 3 pumps ki servicing ki"],
  );
  const content = {
    ...emptyDwr(),
    completed: ["Serviced 3 pumps"],
    sourceTranscript: "[10:00] Aaj 3 pumps ki servicing ki",
  };
  const store = (row: any, body = content) =>
    asWorker(
      async (c) =>
        (
          await c.query(
            "SELECT app.dwr_agent_store($1,$2,$3,$4::date,$5,$6,$7,$8) AS o",
            [
              row.organization_id,
              row.site_id,
              row.employee_id,
              today(),
              row.lease,
              row.source_hash,
              body,
              { model: "synthetic" },
            ],
          )
        ).rows[0].o,
    );
  await send("kiran", "Kal motor rewinding karni hai");
  assert.equal(
    await store(first),
    "STALE",
    "A newer message invalidates the lease",
  );
  const [second] = await claim();
  assert.equal(second.messages.length, 2);
  assert.equal(await store(second), "STORED");
  const report = (
    await f.owner.query(
      "SELECT r.*,(SELECT event FROM app.dwr_history h WHERE h.report_id=r.id ORDER BY version DESC LIMIT 1) AS last FROM app.dwr_reports r WHERE employee_id=$1 AND work_date=$2",
      [kiranProfile, today()],
    )
  ).rows[0];
  assert.deepEqual(
    [report.status, report.origin, report.last, report.content.completed],
    ["draft", "chat", "prepare", ["Serviced 3 pumps"]],
  );
  assert.equal(
    (
      await f.owner.query(
        "SELECT count(*)::int n FROM app.inbox_items WHERE user_id=$1 AND entity_id=$2 AND event_type='dwr.prepared'",
        [ids.supervisor, report.id],
      )
    ).rows[0].n,
    1,
  );
  // The author's manual edit is never overwritten by an automatic run.
  ok(
    await cmd("kiran", "save", {
      clientId: randomUUID(),
      expectedVersion: report.version,
      workDate: today(),
      content: {
        ...content,
        completed: ["Serviced 3 pumps", "Checked motor"],
      },
      attachments: [],
    }),
  );
  await send("kiran", "Motor check bhi kiya");
  await f.owner.query(
    "UPDATE app.dwr_agent_jobs SET due_at=now() WHERE employee_id=$1",
    [kiranProfile],
  );
  const [third] = await claim();
  assert.equal(await store(third), "MANUAL_EDITS");
  ok(await cmd("kiran", "prepare", { workDate: today(), mode: "ai" }));
  const [fourth] = await claim();
  assert.equal(
    await store(fourth),
    "STORED",
    "An explicit request re-prepares",
  );
  // Provider failure keeps a cooldown; budgets stop further calls.
  ok(await cmd("kiran", "prepare", { workDate: today(), mode: "ai" }));
  const [fifth] = await claim();
  await asWorker((c) =>
    c.query(
      "SELECT app.dwr_agent_fail($1,$2,$3,$4::date,$5,'PROVIDER_QUOTA',120)",
      [
        fifth.organization_id,
        fifth.site_id,
        fifth.employee_id,
        today(),
        fifth.lease,
      ],
    ),
  );
  assert.equal((await job(kiranProfile)).status, "failed");
  assert.equal((await claim()).length, 0, "Cooldown is respected");
  ok(await cmd("kiran", "prepare", { workDate: today(), mode: "ai" }));
  assert.equal((await claim(1)).length, 0);
  assert.equal((await job(kiranProfile)).error_code, "LIMIT_REACHED");
  // Revoked membership stops preparation without a provider call.
  ok(await cmd("kiran", "prepare", { workDate: today(), mode: "ai" }));
  await f.owner.query(
    "UPDATE app.site_memberships SET active=false WHERE organization_id=$1 AND site_id=$2 AND user_id=$3",
    [ids.org, ids.dg, ids.supervisor],
  );
  assert.equal((await claim()).length, 0);
  assert.equal((await job(kiranProfile)).error_code, "ACCESS_REVOKED");
  await f.owner.query(
    "UPDATE app.site_memberships SET active=true WHERE organization_id=$1 AND site_id=$2 AND user_id=$3",
    [ids.org, ids.dg, ids.supervisor],
  );
  // The runtime role can neither claim jobs nor store AI output.
  await assert.rejects(
    scoped(f.runtime, who.hr!.actor, ids.dg, (c) =>
      c.query("SELECT * FROM app.dwr_agent_claim(1,1,1)"),
    ),
    /permission denied/,
  );
});
test("agent heartbeat drives the honest online/offline status", async () => {
  await signIn("kiran", "supervisor@example.test");
  assert.deepEqual(ok(await chat("kiran", { view: "home" })).agent, {
    configured: false,
    online: false,
    model: null,
  });
  await asWorker((c) =>
    c.query("SELECT app.dwr_agent_heartbeat(true,'synthetic/model')"),
  );
  assert.deepEqual(ok(await chat("kiran", { view: "home" })).agent, {
    configured: true,
    online: true,
    model: "synthetic/model",
  });
  await f.owner.query(
    "UPDATE app.dwr_agent_state SET seen_at=now()-interval '5 minutes'",
  );
  assert.equal(ok(await chat("kiran", { view: "home" })).agent.online, false);
});
