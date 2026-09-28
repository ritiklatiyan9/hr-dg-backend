import { z } from "zod";
import { Operations } from "./operations.js";
import {
  fail,
  workDate,
  type Actor,
} from "../../../packages/authz/src/index.js";
import type { Tx } from "../../../packages/db/src/index.js";
import {
  dwrContent,
  dwrGroupDescription,
  dwrGroupName,
  dwrMessageBody,
  emptyDwr,
} from "../../../packages/contracts/dwr.js";
import { chatTranscript } from "./dwr-provider.js";
const uuid = z.uuid();
const version = z.number().int().min(1);
const views = z.discriminatedUnion("view", [
  z.object({ view: z.literal("home") }).strict(),
  z
    .object({
      view: z.literal("thread"),
      groupId: uuid.nullable(),
      month: z
        .string()
        .regex(/^\d{4}-(0[1-9]|1[0-2])$/)
        .optional(),
      before: z
        .object({ at: z.iso.datetime({ offset: true }), id: uuid })
        .strict()
        .optional(),
      since: z.iso.datetime({ offset: true }).optional(),
    })
    .strict(),
  z.object({ view: z.literal("group"), groupId: uuid }).strict(),
  z
    .object({
      view: z.literal("candidates"),
      groupId: uuid.nullable(),
      search: z.string().max(60).default(""),
    })
    .strict(),
  z
    .object({
      view: z.literal("day"),
      employeeId: uuid.optional(),
      workDate: z.iso.date(),
    })
    .strict(),
  z
    .object({
      view: z.literal("daySummary"),
      groupId: uuid,
      workDate: z.iso.date(),
    })
    .strict(),
]);
export const chatSchemas = {
  message: z
    .object({ clientId: uuid, groupId: uuid.nullable(), body: dwrMessageBody })
    .strict(),
  editMessage: z
    .object({ id: uuid, expectedVersion: version, body: dwrMessageBody })
    .strict(),
  deleteMessage: z.object({ id: uuid, expectedVersion: version }).strict(),
  markRead: z.object({ groupId: uuid }).strict(),
  prepare: z
    .object({
      workDate: z.iso.date(),
      employeeId: uuid.optional(),
      mode: z.enum(["ai", "chat"]).default("ai"),
    })
    .strict(),
  prepareGroup: z.object({ groupId: uuid, workDate: z.iso.date() }).strict(),
  createGroup: z
    .object({
      clientId: uuid,
      name: dwrGroupName,
      description: dwrGroupDescription.default(""),
      members: z
        .array(z.object({ userId: uuid, admin: z.boolean() }).strict())
        .min(1)
        .max(256),
    })
    .strict(),
  updateGroup: z
    .object({
      id: uuid,
      expectedVersion: version,
      name: dwrGroupName,
      description: dwrGroupDescription,
    })
    .strict(),
  addMembers: z
    .object({ id: uuid, userIds: z.array(uuid).min(1).max(100) })
    .strict(),
  removeMember: z.object({ id: uuid, userId: uuid }).strict(),
  setMemberRole: z
    .object({ id: uuid, userId: uuid, role: z.enum(["admin", "member"]) })
    .strict(),
  leaveGroup: z.object({ id: uuid }).strict(),
  archiveGroup: z
    .object({
      id: uuid,
      expectedVersion: version,
      reason: z.string().trim().min(8).max(500),
    })
    .strict(),
};
export const isChatOperation = (op: string): op is keyof typeof chatSchemas =>
  Object.hasOwn(chatSchemas, op);
type Access = Record<
  | "view"
  | "create"
  | "edit"
  | "remove"
  | "oversee"
  | "createGroups"
  | "editGroups"
  | "moderate"
  | "review",
  boolean
>;
const MESSAGE =
  "id,group_id,user_id,employee_id,work_date::text AS work_date,body,version,created_at,updated_at,edited_at,deleted_at,deleted_by";
const like = (s: string) => s.replace(/[\\%_]/g, (ch) => "\\" + ch);
function monthRange(month: string, today: string) {
  const [y, m] = month.split("-").map(Number);
  const last = new Date(Date.UTC(y!, m!, 0)).getUTCDate();
  const end = `${month}-${String(last).padStart(2, "0")}`;
  return { from: `${month}-01`, to: end < today ? end : today };
}
export class DwrChat extends Operations {
  async agentStatus(c: Tx) {
    const s = (
      await c.query("SELECT configured,model,seen_at FROM app.dwr_agent_state")
    ).rows[0];
    return {
      configured: !!s?.configured,
      // The worker writes a heartbeat every 30 seconds while it runs.
      online: !!s?.configured && Date.now() - Date.parse(s.seen_at) < 90_000,
      model: s?.configured ? (s.model as string) : null,
    };
  }
  async siteToday(c: Tx) {
    const site = (
      await c.query(
        "SELECT name,timezone FROM app.sites WHERE id=app.site_id()",
      )
    ).rows[0];
    return { site, today: workDate(new Date(), site.timezone) };
  }
  async validateDate(c: Tx, employee: string, date: string) {
    z.iso.date().parse(date);
    const site = (
      await c.query("SELECT timezone FROM app.sites WHERE id=app.site_id()")
    ).rows[0];
    if (date > workDate(new Date(), site.timezone))
      fail("BAD_INPUT", "A report cannot use a future work date");
    if (
      !(
        await c.query(
          "SELECT 1 FROM app.site_assignments WHERE employee_id=$1 AND site_id=app.site_id() AND $2::date BETWEEN starts_on AND COALESCE(ends_on,'infinity'::date)",
          [employee, date],
        )
      ).rowCount
    )
      fail("FORBIDDEN", "No assignment at this site on the work date", 403);
  }
  async myEmployee(c: Tx) {
    return (
      (
        await c.query(
          "SELECT id,display_name FROM app.employees WHERE user_id=app.actor_id()",
        )
      ).rows[0] ?? null
    );
  }
  async chatAccess(c: Tx): Promise<Access> {
    return (
      await c.query(`SELECT app.allowed('my_dwr.view') AS view,app.allowed('my_dwr.create') AS create,
 app.allowed('my_dwr.edit') AS edit,app.allowed('my_dwr.delete') AS remove,app.allowed('dwr_groups.view') AS oversee,
 app.allowed('dwr_groups.create') AS "createGroups",app.allowed('dwr_groups.edit') AS "editGroups",
 app.allowed('dwr_groups.delete') AS moderate,app.allowed('dwr_review.view') AS review`)
    ).rows[0];
  }
  async people(c: Tx, users: Iterable<string | null>) {
    const ids = [...new Set([...users].filter(Boolean))];
    const names = new Map<string, string>();
    if (ids.length)
      for (const r of (
        await c.query("SELECT user_id,name FROM app.dwr_people($1::uuid[])", [
          ids,
        ])
      ).rows)
        names.set(r.user_id, r.name);
    return names;
  }
  async dayStatus(c: Tx, employeeId: string, date: string) {
    const report =
      (
        await c.query(
          "SELECT id,status,version,revision,origin,updated_at FROM app.dwr_reports WHERE employee_id=$1 AND work_date=$2",
          [employeeId, date],
        )
      ).rows[0] ?? null;
    const job =
      (
        await c.query(
          "SELECT status,due_at,error_code,prepared_at,explicit FROM app.dwr_agent_jobs WHERE employee_id=$1 AND work_date=$2",
          [employeeId, date],
        )
      ).rows[0] ?? null;
    const messages = (
      await c.query(
        "SELECT count(*)::int AS n FROM app.dwr_messages WHERE employee_id=$1 AND work_date=$2 AND deleted_at IS NULL",
        [employeeId, date],
      )
    ).rows[0].n;
    return {
      workDate: date,
      messages,
      report: report && {
        id: report.id,
        status: report.status,
        version: report.version,
        revision: report.revision,
        origin: report.origin,
        updatedAt: report.updated_at,
      },
      job: job && {
        status: job.status,
        dueAt: job.due_at,
        errorCode: job.error_code,
        preparedAt: job.prepared_at,
        explicit: job.explicit,
      },
    };
  }
  async group(c: Tx, id: string, lock = false) {
    const g = (
      await c.query(
        "SELECT id,name,description,version,created_by,created_at,archived_at FROM app.dwr_groups WHERE id=$1",
        [id],
      )
    ).rows[0];
    if (!g) fail("NOT_FOUND", "This group is unavailable", 404);
    // Serializes every membership change of one group (last-admin checks).
    if (lock)
      await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
        `dwr-group:${id}`,
      ]);
    const role = (await c.query("SELECT app.dwr_member_role($1) AS role", [id]))
      .rows[0].role as "admin" | "member" | null;
    return { ...g, role };
  }
  async manageable(c: Tx, id: string) {
    const g = await this.group(c, id, true);
    if (g.archived_at) fail("CONFLICT", "Archived groups are read-only", 409);
    if (g.role !== "admin" && !(await this.chatAccess(c)).editGroups)
      fail("FORBIDDEN", "Only group admins can change this group", 403);
    return g;
  }
  async dwrChat(actor: Actor, siteId: string, raw: unknown) {
    const input = views.parse(raw);
    return this.site(actor, siteId, async (c) => {
      const a = await this.chatAccess(c);
      if (!a.view && !a.oversee && !a.review)
        fail("FORBIDDEN", "DWR chat is restricted", 403);
      const { site, today } = await this.siteToday(c);
      const me = a.view ? await this.myEmployee(c) : null;
      const message = (m: any, locked: Set<string>, role: string | null) => {
        const mine = m.user_id === actor.id,
          open = !m.deleted_at && !(mine && locked.has(m.work_date));
        return {
          id: m.id,
          groupId: m.group_id,
          userId: m.user_id,
          workDate: m.work_date,
          body: m.deleted_at ? "" : m.body,
          version: m.version,
          createdAt: m.created_at,
          updatedAt: m.updated_at,
          editedAt: m.edited_at,
          deletedAt: m.deleted_at,
          deletedByModerator: !!m.deleted_at && m.deleted_by !== m.user_id,
          mine,
          canEdit:
            open && mine && a.edit && (m.group_id === null || role !== null),
          canDelete:
            open &&
            ((mine && a.remove && (m.group_id === null || role !== null)) ||
              (m.group_id !== null && a.moderate)),
        };
      };
      if (input.view === "home") {
        const groups = (
          await c.query(`SELECT g.id,g.name,g.description,g.version,g.created_at,g.archived_at,m.role,
 (SELECT count(*)::int FROM app.dwr_group_members x WHERE x.group_id=g.id AND x.active) AS member_count,
 l.body AS last_body,l.user_id AS last_user,l.created_at AS last_at,l.deleted_at AS last_deleted,
 CASE WHEN m.user_id IS NULL THEN 0 ELSE (SELECT count(*)::int FROM (SELECT 1 FROM app.dwr_messages u WHERE u.group_id=g.id
  AND u.created_at>m.last_read_at AND u.user_id<>app.actor_id() AND u.deleted_at IS NULL LIMIT 99) n) END AS unread
 FROM app.dwr_groups g
 LEFT JOIN app.dwr_group_members m ON m.group_id=g.id AND m.user_id=app.actor_id() AND m.active
 LEFT JOIN LATERAL (SELECT x.body,x.user_id,x.created_at,x.deleted_at FROM app.dwr_messages x WHERE x.group_id=g.id
  ORDER BY x.created_at DESC,x.id DESC LIMIT 1) l ON true
 ORDER BY (g.archived_at IS NULL) DESC,COALESCE(l.created_at,g.created_at) DESC LIMIT 200`)
        ).rows;
        const last = me
          ? ((
              await c.query(
                "SELECT body,created_at,deleted_at FROM app.dwr_messages WHERE group_id IS NULL AND user_id=app.actor_id() ORDER BY created_at DESC,id DESC LIMIT 1",
              )
            ).rows[0] ?? null)
          : null;
        const names = await this.people(
          c,
          groups.map((g) => g.last_user),
        );
        return {
          site,
          workDate: today,
          agent: await this.agentStatus(c),
          me: me
            ? { userId: actor.id, employeeId: me.id, name: me.display_name }
            : null,
          permissions: {
            post: a.create && !!me,
            edit: a.edit,
            delete: a.remove,
            createGroups: a.createGroups,
            editGroups: a.editGroups,
            moderate: a.moderate,
            oversee: a.oversee,
            review: a.review,
          },
          personal: me
            ? {
                last: last && {
                  body: last.deleted_at ? "" : last.body,
                  deleted: !!last.deleted_at,
                  at: last.created_at,
                },
                today: await this.dayStatus(c, me.id, today),
              }
            : null,
          groups: groups.map((g) => ({
            id: g.id,
            name: g.name,
            description: g.description,
            version: g.version,
            createdAt: g.created_at,
            archived: !!g.archived_at,
            role: g.role ?? null,
            memberCount: g.member_count,
            unread: g.unread,
            last: g.last_at && {
              body: g.last_deleted ? "" : g.last_body,
              deleted: !!g.last_deleted,
              at: g.last_at,
              userId: g.last_user,
              author: names.get(g.last_user) ?? null,
            },
          })),
        };
      }
      if (input.view === "thread") {
        const month = input.month ?? today.slice(0, 7);
        const { from, to } = monthRange(month, today);
        let group: any = null;
        if (input.groupId) group = await this.group(c, input.groupId);
        else if (!me)
          fail("NOT_FOUND", "No employee profile at this site", 404);
        const where = group
          ? "group_id=$1"
          : "group_id IS NULL AND user_id=app.actor_id() AND $1::uuid IS NULL";
        const rows = input.since
          ? (
              await c.query(
                `SELECT ${MESSAGE} FROM app.dwr_messages WHERE ${where} AND work_date BETWEEN $2 AND $3
 AND updated_at>$4::timestamptz-interval '10 seconds' ORDER BY updated_at,id LIMIT 300`,
                [group?.id ?? null, from, to, input.since],
              )
            ).rows
          : (
              await c.query(
                `SELECT ${MESSAGE} FROM app.dwr_messages WHERE ${where} AND work_date BETWEEN $2 AND $3
 AND ($4::timestamptz IS NULL OR (created_at,id)<($4::timestamptz,$5::uuid)) ORDER BY created_at DESC,id DESC LIMIT 151`,
                [
                  group?.id ?? null,
                  from,
                  to,
                  input.before?.at ?? null,
                  input.before?.id ?? null,
                ],
              )
            ).rows;
        const page = input.since ? rows : rows.slice(0, 150);
        const days = me
          ? (
              await c.query(
                `SELECT d::date::text AS work_date,r.id AS report_id,r.status,r.version,r.revision,r.origin,
 j.status AS job_status,j.due_at,j.error_code,j.prepared_at
 FROM generate_series($2::date,$3::date,interval '1 day') d
 LEFT JOIN app.dwr_reports r ON r.employee_id=$1 AND r.work_date=d::date
 LEFT JOIN app.dwr_agent_jobs j ON j.employee_id=$1 AND j.work_date=d::date
 WHERE r.id IS NOT NULL OR j.status IS NOT NULL`,
                [me.id, from, to],
              )
            ).rows
          : [];
        const locked = new Set(
          days
            .filter((d) => ["submitted", "approved"].includes(d.status))
            .map((d) => d.work_date as string),
        );
        const names = await this.people(c, [
          actor.id,
          ...page.map((m) => m.user_id),
        ]);
        return {
          site,
          workDate: today,
          month,
          serverTime: (await c.query("SELECT now() AS t")).rows[0].t,
          agent: await this.agentStatus(c),
          thread: group
            ? {
                groupId: group.id,
                name: group.name,
                description: group.description,
                version: group.version,
                archived: !!group.archived_at,
                role: group.role,
                memberCount: (
                  await c.query(
                    "SELECT count(*)::int AS n FROM app.dwr_group_members WHERE group_id=$1 AND active",
                    [group.id],
                  )
                ).rows[0].n,
                canPost:
                  !group.archived_at && group.role !== null && a.create && !!me,
                canManage:
                  !group.archived_at &&
                  (group.role === "admin" || a.editGroups),
              }
            : {
                groupId: null,
                name: "My DWR Agent",
                description: "",
                archived: false,
                role: null,
                memberCount: 1,
                canPost: a.create && !!me,
                canManage: false,
              },
          me: me ? { userId: actor.id, employeeId: me.id } : null,
          messages: page.map((m) =>
            message(m, locked, group ? group.role : null),
          ),
          hasMore: !input.since && rows.length > 150,
          before:
            !input.since && page.length
              ? { at: page.at(-1)!.created_at, id: page.at(-1)!.id }
              : null,
          people: Object.fromEntries(names),
          days: days.map((d) => ({
            workDate: d.work_date,
            report: d.report_id
              ? {
                  id: d.report_id,
                  status: d.status,
                  version: d.version,
                  revision: d.revision,
                  origin: d.origin,
                }
              : null,
            job: d.job_status
              ? {
                  status: d.job_status,
                  dueAt: d.due_at,
                  errorCode: d.error_code,
                  preparedAt: d.prepared_at,
                }
              : null,
          })),
        };
      }
      if (input.view === "group") {
        const g = await this.group(c, input.groupId);
        const members = (
          await c.query(
            "SELECT user_id,employee_id,role,added_at FROM app.dwr_group_members WHERE group_id=$1 AND active ORDER BY role,added_at,user_id",
            [g.id],
          )
        ).rows;
        const names = await this.people(c, [
          g.created_by,
          ...members.map((m) => m.user_id),
        ]);
        return {
          id: g.id,
          name: g.name,
          description: g.description,
          version: g.version,
          createdAt: g.created_at,
          createdBy: names.get(g.created_by) ?? null,
          archived: !!g.archived_at,
          role: g.role,
          canManage: !g.archived_at && (g.role === "admin" || a.editGroups),
          canArchive: !g.archived_at && a.moderate,
          canLeave: !g.archived_at && g.role !== null,
          members: members.map((m) => ({
            userId: m.user_id,
            employeeId: m.employee_id,
            name: names.get(m.user_id) ?? "Member",
            role: m.role,
            addedAt: m.added_at,
            me: m.user_id === actor.id,
          })),
        };
      }
      if (input.view === "candidates")
        return {
          people: (
            await c.query(
              "SELECT user_id,employee_id,name FROM app.dwr_candidates($1,$2)",
              [input.groupId, like(input.search.trim())],
            )
          ).rows.map((r) => ({
            userId: r.user_id,
            employeeId: r.employee_id,
            name: r.name,
          })),
        };
      if (input.view === "day") {
        const employee = input.employeeId ?? me?.id;
        if (!employee)
          fail("NOT_FOUND", "No employee profile at this site", 404);
        if (
          employee !== me?.id &&
          !(
            await c.query("SELECT app.allowed('dwr_review.view',$1) AS ok", [
              employee,
            ])
          ).rows[0].ok
        )
          fail("FORBIDDEN", "These messages are restricted", 403);
        const rows = (
          await c.query(
            `SELECT m.id,m.group_id,g.name AS group_name,m.body,m.created_at,m.edited_at,m.version FROM app.dwr_messages m
 LEFT JOIN app.dwr_groups g ON g.id=m.group_id WHERE m.employee_id=$1 AND m.work_date=$2 AND m.deleted_at IS NULL
 ORDER BY m.created_at,m.id LIMIT 200`,
            [employee, input.workDate],
          )
        ).rows;
        return {
          employeeId: employee,
          workDate: input.workDate,
          messages: rows.map((m) => ({
            id: m.id,
            groupId: m.group_id,
            groupName: m.group_id ? (m.group_name ?? "Group chat") : null,
            body: m.body,
            createdAt: m.created_at,
            editedAt: m.edited_at,
            version: m.version,
          })),
        };
      }
      const g = await this.group(c, input.groupId);
      if (g.role !== "admin" && !a.oversee)
        fail("FORBIDDEN", "Only group admins can see the day summary", 403);
      const rows = (
        await c.query(
          `SELECT m.user_id,m.employee_id,m.role,
 (SELECT count(*)::int FROM app.dwr_messages x WHERE x.group_id=m.group_id AND x.user_id=m.user_id AND x.work_date=$2 AND x.deleted_at IS NULL) AS messages,
 r.id AS report_id,r.status,r.version,j.status AS job_status,j.error_code,j.due_at
 FROM app.dwr_group_members m
 LEFT JOIN app.dwr_reports r ON r.employee_id=m.employee_id AND r.work_date=$2
 LEFT JOIN app.dwr_agent_jobs j ON j.employee_id=m.employee_id AND j.work_date=$2
 WHERE m.group_id=$1 AND m.active ORDER BY m.added_at,m.user_id`,
          [g.id, input.workDate],
        )
      ).rows;
      const names = await this.people(
        c,
        rows.map((r) => r.user_id),
      );
      return {
        groupId: g.id,
        workDate: input.workDate,
        agent: await this.agentStatus(c),
        canPrepare: !g.archived_at && (g.role === "admin" || a.editGroups),
        members: rows.map((r) => ({
          userId: r.user_id,
          employeeId: r.employee_id,
          name: names.get(r.user_id) ?? "Member",
          role: r.role,
          messages: r.messages,
          report: r.report_id
            ? { id: r.report_id, status: r.status, version: r.version }
            : null,
          job: r.job_status
            ? { status: r.job_status, errorCode: r.error_code, dueAt: r.due_at }
            : null,
        })),
      };
    });
  }
  async chatCommand(
    actor: Actor,
    siteId: string,
    operation: keyof typeof chatSchemas,
    raw: unknown,
  ) {
    const p: any = chatSchemas[operation].parse(raw);
    return this.site(actor, siteId, async (c) => {
      const { today, site } = await this.siteToday(c);
      if (operation === "message") {
        const me = await this.mine(c);
        // Current site assignment and own-record permission, like any DWR write.
        await this.allowed(c, "my_dwr.create", me.id);
        const body = p.body.replace(/\r\n?/g, "\n");
        const old = (
          await c.query(
            `SELECT ${MESSAGE} FROM app.dwr_messages WHERE user_id=app.actor_id() AND client_id=$1`,
            [p.clientId],
          )
        ).rows[0];
        if (old) {
          if (old.group_id !== p.groupId || old.body !== body)
            fail("CONFLICT", "Message ID reused with different content", 409);
          return { message: { id: old.id, version: old.version } };
        }
        if (p.groupId && (await this.group(c, p.groupId)).role === null)
          fail("FORBIDDEN", "You are not a member of this group", 403);
        const m = (
          await c.query(
            `INSERT INTO app.dwr_messages(organization_id,site_id,group_id,user_id,employee_id,work_date,client_id,body)
 VALUES(app.org_id(),app.site_id(),$1,app.actor_id(),$2,$3,$4,$5) RETURNING ${MESSAGE}`,
            [p.groupId, me.id, today, p.clientId, body],
          )
        ).rows[0];
        const status = (
          await c.query(
            "SELECT status FROM app.dwr_reports WHERE employee_id=$1 AND work_date=$2",
            [me.id, today],
          )
        ).rows[0]?.status;
        return {
          message: {
            id: m.id,
            version: m.version,
            workDate: m.work_date,
            createdAt: m.created_at,
          },
          // New messages never alter a DWR that was already sent.
          reportLocked: ["submitted", "approved"].includes(status),
        };
      }
      if (operation === "editMessage" || operation === "deleteMessage") {
        const m = (
          await c.query(
            `SELECT ${MESSAGE} FROM app.dwr_messages WHERE id=$1 FOR UPDATE`,
            [p.id],
          )
        ).rows[0];
        if (!m) fail("NOT_FOUND", "Message unavailable", 404);
        if (m.deleted_at)
          fail("CONFLICT", "This message was already deleted", 409);
        if (m.version !== p.expectedVersion)
          fail("CONFLICT", "This message changed. Reload the chat.", 409);
        const mine = m.user_id === actor.id;
        if (
          m.group_id &&
          mine &&
          (await this.group(c, m.group_id)).role === null
        )
          fail("FORBIDDEN", "You are no longer a member of this group", 403);
        if (operation === "editMessage") {
          if (!mine)
            fail("FORBIDDEN", "Only the author can edit a message", 403);
          await this.allowed(c, "my_dwr.edit", m.employee_id);
          const body = p.body.replace(/\r\n?/g, "\n");
          if (body === m.body) return { id: m.id, version: m.version };
          const r = (
            await c.query(
              "UPDATE app.dwr_messages SET body=$2 WHERE id=$1 RETURNING id,version",
              [m.id, body],
            )
          ).rows[0];
          return { id: r.id, version: r.version };
        }
        if (mine) await this.allowed(c, "my_dwr.delete", m.employee_id);
        else if (!m.group_id || !(await this.chatAccess(c)).moderate)
          fail("FORBIDDEN", "You cannot delete this message", 403);
        const r = (
          await c.query(
            "UPDATE app.dwr_messages SET deleted_at=now() WHERE id=$1 RETURNING id,version",
            [m.id],
          )
        ).rows[0];
        if (!mine)
          await this.auditOperation(c, "dwr.message.moderated", m.id, [
            "deleted",
          ]);
        return { id: r.id, version: r.version };
      }
      if (operation === "markRead") {
        await c.query(
          "UPDATE app.dwr_group_members SET last_read_at=now() WHERE group_id=$1 AND user_id=app.actor_id() AND active",
          [p.groupId],
        );
        return { ok: true };
      }
      if (operation === "prepare") {
        if (p.workDate > today)
          fail("BAD_INPUT", "A report cannot use a future work date");
        const me = await this.myEmployee(c);
        const employee = p.employeeId ?? me?.id;
        if (!employee)
          fail("NOT_FOUND", "No employee profile at this site", 404);
        if (p.mode === "ai")
          return {
            outcome: (
              await c.query("SELECT app.dwr_agent_request($1,$2) AS o", [
                employee,
                p.workDate,
              ])
            ).rows[0].o,
            agent: await this.agentStatus(c),
          };
        // Chat-only report: the author's own messages, no AI summary.
        if (employee !== me?.id)
          fail(
            "FORBIDDEN",
            "Only the author can use their chat as the report",
            403,
          );
        await this.validateDate(c, me.id, p.workDate);
        await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
          `${actor.organizationId}:${actor.id}:dwr`,
        ]);
        const lines = (
          await c.query(
            "SELECT created_at,body FROM app.dwr_messages WHERE employee_id=$1 AND work_date=$2 AND deleted_at IS NULL ORDER BY created_at,id LIMIT 200",
            [me.id, p.workDate],
          )
        ).rows;
        if (!lines.length)
          fail("BAD_INPUT", "Send at least one message for this day first");
        const transcript = chatTranscript(
          lines.map((l) => ({
            at: new Date(l.created_at).toISOString(),
            text: l.body,
          })),
          site.timezone,
        );
        let report = (
          await c.query(
            "SELECT * FROM app.dwr_reports WHERE employee_id=$1 AND work_date=$2 FOR UPDATE",
            [me.id, p.workDate],
          )
        ).rows[0];
        await this.allowed(c, report ? "my_dwr.edit" : "my_dwr.create", me.id);
        if (report && !["draft", "returned"].includes(report.status))
          fail("CONFLICT", "This day's DWR was already submitted", 409);
        if (report?.content.sourceTranscript === transcript)
          return {
            id: report.id,
            version: report.version,
            revision: report.revision,
            status: report.status,
          };
        const content = dwrContent.parse({
          ...(report?.content ?? emptyDwr()),
          sourceTranscript: transcript,
        });
        report = report
          ? (
              await c.query(
                "UPDATE app.dwr_reports SET content=$2,origin='chat',status='draft',version=version+1,revision=revision+1,updated_at=now() WHERE id=$1 RETURNING *",
                [report.id, content],
              )
            ).rows[0]
          : (
              await c.query(
                "INSERT INTO app.dwr_reports(organization_id,site_id,employee_id,user_id,work_date,content,origin) VALUES(app.org_id(),app.site_id(),$1,app.actor_id(),$2,$3,'chat') RETURNING *",
                [me.id, p.workDate, content],
              )
            ).rows[0];
        await c.query(
          `INSERT INTO app.dwr_history(organization_id,site_id,report_id,version,revision,actor_id,event,reason,content,attachments)
 VALUES(app.org_id(),app.site_id(),$1,$2,$3,app.actor_id(),'prepare','Chat messages without AI summary',$4,$5)`,
          [
            report.id,
            report.version,
            report.revision,
            report.content,
            report.attachments,
          ],
        );
        await this.auditOperation(c, "dwr.prepare", report.id, ["content"]);
        return {
          id: report.id,
          version: report.version,
          revision: report.revision,
          status: report.status,
        };
      }
      if (operation === "prepareGroup") {
        if (p.workDate > today)
          fail("BAD_INPUT", "A report cannot use a future work date");
        const g = await this.manageable(c, p.groupId);
        const outcomes: Record<string, number> = {};
        const requested = await c.query(
          "SELECT app.dwr_agent_request(employee_id,$2) AS outcome FROM app.dwr_group_members WHERE group_id=$1 AND active ORDER BY employee_id",
          [g.id, p.workDate],
        );
        for (const r of requested.rows)
          outcomes[r.outcome] = (outcomes[r.outcome] ?? 0) + 1;
        return { outcomes, agent: await this.agentStatus(c) };
      }
      if (operation === "createGroup") {
        await this.allowed(c, "dwr_groups.create");
        const old = (
          await c.query(
            "SELECT id,name,version FROM app.dwr_groups WHERE created_by=app.actor_id() AND client_id=$1",
            [p.clientId],
          )
        ).rows[0];
        if (old) {
          if (old.name !== p.name)
            fail("CONFLICT", "Request ID used with different content", 409);
          return { id: old.id, version: old.version };
        }
        const members = new Map<string, boolean>();
        for (const m of p.members)
          members.set(m.userId, (members.get(m.userId) ?? false) || m.admin);
        if (![...members.values()].some(Boolean))
          fail("BAD_INPUT", "Choose at least one group admin");
        const eligible = await this.eligible(c, null, [...members.keys()]);
        const g = (
          await c.query(
            "INSERT INTO app.dwr_groups(organization_id,site_id,name,description,created_by,client_id) VALUES(app.org_id(),app.site_id(),$1,$2,app.actor_id(),$3) RETURNING id,version",
            [p.name, p.description, p.clientId],
          )
        ).rows[0];
        await c.query(
          `INSERT INTO app.dwr_group_members(organization_id,site_id,group_id,user_id,employee_id,role,added_by)
 SELECT app.org_id(),app.site_id(),$1,u,e,CASE WHEN a THEN 'admin' ELSE 'member' END,app.actor_id()
 FROM unnest($2::uuid[],$3::uuid[],$4::boolean[]) AS x(u,e,a)`,
          [
            g.id,
            eligible.map((m) => m.user_id),
            eligible.map((m) => m.employee_id),
            eligible.map((m) => members.get(m.user_id)),
          ],
        );
        await this.notifyMany(
          c,
          eligible.filter((m) => m.user_id !== actor.id).map((m) => m.user_id),
          "my_dwr",
          g.id,
          "dwr.group.added",
        );
        await this.auditOperation(c, "dwr.group.create", g.id, [
          "name",
          "members",
        ]);
        return { id: g.id, version: g.version };
      }
      if (operation === "updateGroup") {
        const g = await this.manageable(c, p.id);
        if (g.version !== p.expectedVersion)
          fail("CONFLICT", "This group changed. Reload before saving.", 409);
        const r = (
          await c.query(
            "UPDATE app.dwr_groups SET name=$2,description=$3,version=version+1,updated_at=now() WHERE id=$1 RETURNING id,version",
            [g.id, p.name, p.description],
          )
        ).rows[0];
        await this.auditOperation(c, "dwr.group.update", g.id, [
          "name",
          "description",
        ]);
        return r;
      }
      if (operation === "addMembers") {
        const g = await this.manageable(c, p.id);
        const eligible = await this.eligible(c, g.id, [
          ...new Set<string>(p.userIds),
        ]);
        await c.query(
          `INSERT INTO app.dwr_group_members(organization_id,site_id,group_id,user_id,employee_id,role,added_by)
 SELECT app.org_id(),app.site_id(),$1,u,e,'member',app.actor_id() FROM unnest($2::uuid[],$3::uuid[]) AS x(u,e)
 ON CONFLICT(group_id,user_id) DO UPDATE SET active=true,role='member',added_by=app.actor_id(),added_at=now(),last_read_at=now()`,
          [
            g.id,
            eligible.map((m) => m.user_id),
            eligible.map((m) => m.employee_id),
          ],
        );
        await this.notifyMany(
          c,
          eligible.map((m) => m.user_id),
          "my_dwr",
          g.id,
          "dwr.group.added",
        );
        await this.auditOperation(c, "dwr.group.members", g.id, ["added"]);
        return { id: g.id, added: eligible.length };
      }
      if (operation === "removeMember" || operation === "setMemberRole") {
        const g = await this.manageable(c, p.id);
        const target = (
          await c.query(
            "SELECT role FROM app.dwr_group_members WHERE group_id=$1 AND user_id=$2 AND active",
            [g.id, p.userId],
          )
        ).rows[0];
        if (!target) fail("NOT_FOUND", "This person is not a member", 404);
        if (operation === "removeMember" && p.userId === actor.id)
          fail("BAD_INPUT", "Use Leave group to leave");
        const demoting =
          target.role === "admin" &&
          (operation === "removeMember" || p.role === "member");
        if (
          demoting &&
          (
            await c.query(
              "SELECT count(*)::int AS n FROM app.dwr_group_members WHERE group_id=$1 AND active AND role='admin'",
              [g.id],
            )
          ).rows[0].n <= 1
        )
          fail(
            "LAST_GROUP_ADMIN",
            "A group needs at least one admin. Make someone else admin first.",
            409,
          );
        if (operation === "removeMember")
          await c.query(
            "UPDATE app.dwr_group_members SET active=false WHERE group_id=$1 AND user_id=$2",
            [g.id, p.userId],
          );
        else if (target.role !== p.role)
          await c.query(
            "UPDATE app.dwr_group_members SET role=$3 WHERE group_id=$1 AND user_id=$2",
            [g.id, p.userId, p.role],
          );
        await this.auditOperation(c, `dwr.group.${operation}`, g.id, [
          operation === "removeMember" ? "removed" : "role",
        ]);
        return { id: g.id };
      }
      if (operation === "leaveGroup") {
        const g = await this.group(c, p.id, true);
        if (g.role === null)
          fail("NOT_FOUND", "You are not a member of this group", 404);
        // Like WhatsApp: the longest-standing member takes over from the last admin.
        if (
          g.role === "admin" &&
          !(
            await c.query(
              "SELECT 1 FROM app.dwr_group_members WHERE group_id=$1 AND active AND role='admin' AND user_id<>app.actor_id()",
              [g.id],
            )
          ).rowCount
        )
          await c.query(
            `UPDATE app.dwr_group_members SET role='admin' WHERE group_id=$1 AND user_id=(SELECT user_id FROM app.dwr_group_members
 WHERE group_id=$1 AND active AND user_id<>app.actor_id() ORDER BY added_at,user_id LIMIT 1)`,
            [g.id],
          );
        await c.query(
          "UPDATE app.dwr_group_members SET active=false WHERE group_id=$1 AND user_id=app.actor_id()",
          [g.id],
        );
        await this.auditOperation(c, "dwr.group.leave", g.id, ["left"]);
        return { id: g.id };
      }
      await this.allowed(c, "dwr_groups.delete");
      const g = await this.group(c, p.id, true);
      if (g.archived_at)
        fail("CONFLICT", "This group is already archived", 409);
      if (g.version !== p.expectedVersion)
        fail("CONFLICT", "This group changed. Reload before archiving.", 409);
      await c.query(
        "UPDATE app.dwr_groups SET archived_at=now(),version=version+1,updated_at=now() WHERE id=$1",
        [g.id],
      );
      await c.query(
        "INSERT INTO app.audit_records(organization_id,site_id,actor_id,action,entity_id,metadata) VALUES(app.org_id(),app.site_id(),app.actor_id(),'operations.dwr.group.archive',$1,$2)",
        [g.id, JSON.stringify({ reason: p.reason })],
      );
      return { id: g.id, archived: true };
    });
  }
  /** Each requested person must be able to use DWR at this site (and not already be a member). */
  async eligible(c: Tx, group: string | null, users: string[]) {
    const rows = (
      await c.query(
        "SELECT user_id,employee_id,name FROM app.dwr_candidates($1,'',$2::uuid[])",
        [group, users],
      )
    ).rows;
    if (rows.length !== users.length)
      fail(
        "BAD_INPUT",
        "Some people are already members or cannot use DWR at this site",
      );
    return rows as { user_id: string; employee_id: string; name: string }[];
  }
}
