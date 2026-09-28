import { readJson } from "../../../packages/db/src/read-json.js";
import { randomUUID, createHash } from "node:crypto";
import { z } from "zod";
import { Foundation } from "./foundation.js";
import { fail, type Actor } from "../../../packages/authz/src/index.js";
import type { Tx } from "../../../packages/db/src/index.js";
import {
  projectDuty,
  stateAfter,
  type DutyEvent,
} from "../../../packages/attendance/src/engine.js";
import { onlineEvidenceTimely } from "../../../packages/attendance/src/online-evidence.js";
const epoch = (value: string | Date) => new Date(value).getTime();
const uuid = z.uuid(),
  instant = z.iso.datetime({ offset: true }),
  date = z.iso.date(),
  reason = z.string().trim().min(8).max(1000),
  text = z.string().trim().min(1).max(200),
  version = z.number().int().positive();
export const policySchema = z
  .object({
    allowOffline: z.boolean(),
    offlineMaxHours: z.number().int().min(0).max(168),
    maxAccuracyM: z.number().min(5).max(500),
    freshnessSeconds: z.number().int().min(5).max(300),
    clockSkewSeconds: z.number().int().min(5).max(300),
    gapSeconds: z.number().int().min(15).max(1800),
    maxSessionHours: z.number().int().min(1).max(36),
    lateGraceMinutes: z.number().int().min(0).max(120),
    earlyGraceMinutes: z.number().int().min(0).max(120),
    attendanceApproverId: uuid,
  })
  .strict();
const location = z
  .object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    accuracyM: z.number().min(0).max(100000),
    observedAt: instant,
    mocked: z.boolean().default(false),
  })
  .strict();
const eventSchema = z
  .object({
    clientEventId: uuid,
    dutyId: uuid,
    sequence: version,
    kind: z.enum([
      "IN",
      "OUT",
      "FIELD_START",
      "FIELD_END",
      "BREAK_START",
      "BREAK_END",
      "LOCATION",
      "VISIT_START",
      "VISIT_END",
    ]),
    capturedAt: instant,
    payloadVersion: z.literal(1),
    policyVersion: version,
    geofenceVersion: version,
    offsiteReason: reason.optional(),
    photoId: uuid.optional(),
    visitId: uuid.optional(),
    location: location.optional(),
  })
  .strict();
const schemas = {
  policy: z
    .object({
      rules: policySchema,
      expectedVersion: z.number().int().min(0),
      reason,
    })
    .strict(),
  geofence: z
    .object({
      label: text,
      coordinates: z
        .array(
          z.tuple([z.number().min(-180).max(180), z.number().min(-85).max(85)]),
        )
        .min(4)
        .max(100),
      expectedVersion: z.number().int().min(0),
      reason,
    })
    .strict(),
  event: eventSchema,
  roster: z
    .object({
      employeeId: uuid,
      shiftId: uuid,
      workDate: date,
      expectedVersion: z.number().int().min(0),
    })
    .strict(),
  // One duty time for many employees and days; replaces rosters on those dates.
  rosterRange: z
    .object({
      employeeIds: z
        .array(uuid)
        .min(1)
        .max(100)
        .refine((a) => new Set(a).size === a.length, "Duplicate employee"),
      shiftId: uuid,
      fromDate: date,
      toDate: date,
      weekdays: z.array(z.number().int().min(0).max(6)).min(1).max(7),
    })
    .strict()
    .refine(
      (p) =>
        p.toDate >= p.fromDate &&
        epoch(p.toDate) - epoch(p.fromDate) <= 62 * 86400000,
      "Choose a date range of at most 63 days",
    ),
  adjustment: z
    .object({
      dutyId: uuid,
      startsAt: instant,
      endsAt: instant,
      kind: z.enum([
        "office",
        "field",
        "break",
        "outside",
        "unknown",
        "overtime",
      ]),
      closeSession: z.boolean().default(false),
      reason,
    })
    .strict(),
  reviewAdjustment: z
    .object({
      id: uuid,
      expectedVersion: version,
      approve: z.boolean(),
      reason,
    })
    .strict(),
  verifyEvent: z
    .object({
      id: uuid,
      expectedStatus: z.literal("pending_verification"),
      approve: z.boolean(),
      effectiveAt: instant.optional(),
      reason,
    })
    .strict(),
  visit: z
    .object({
      employeeId: uuid,
      title: text,
      scheduledAt: instant,
      latitude: z.number().min(-90).max(90),
      longitude: z.number().min(-180).max(180),
      radiusM: z.number().int().min(10).max(5000),
      notes: z.string().max(1000).default(""),
    })
    .strict(),
  leaveType: z
    .object({
      code: z.string().regex(/^[A-Z0-9_]{2,16}$/),
      label: text,
      halfDays: z.boolean(),
      includeWeekends: z.boolean(),
      includeHolidays: z.boolean(),
      approverId: uuid,
    })
    .strict(),
  leaveCredit: z
    .object({
      employeeId: uuid,
      typeId: uuid,
      units: z.number().positive().max(365),
      effectiveOn: date,
      reason,
    })
    .strict(),
  leave: z
    .object({
      clientId: uuid,
      typeId: uuid,
      startsOn: date,
      endsOn: date,
      half: z.enum(["full", "am", "pm"]),
      reason,
    })
    .strict(),
  reviewLeave: z
    .object({
      id: uuid,
      expectedVersion: version,
      approve: z.boolean(),
      reason,
    })
    .strict(),
  task: z
    .object({
      clientId: uuid,
      employeeId: uuid,
      title: text,
      description: z.string().max(4000).default(""),
      deadline: instant,
      priority: z.enum(["low", "normal", "high", "urgent"]),
    })
    .strict(),
  taskStatus: z
    .object({
      id: uuid,
      expectedVersion: version,
      status: z.enum(["todo", "in_progress", "blocked", "done"]),
    })
    .strict(),
  comment: z
    .object({
      clientId: uuid,
      taskId: uuid,
      body: z.string().trim().min(1).max(4000),
      attachmentId: uuid.optional(),
    })
    .strict(),
  readInbox: z.object({ id: uuid }).strict(),
  fileIntent: z
    .object({
      clientId: uuid,
      purpose: z.enum(["attendance", "task", "visit"]),
      parentId: uuid.optional(),
      type: z.enum(["image/jpeg", "image/png", "application/pdf"]),
      bytes: z
        .number()
        .int()
        .min(1)
        .max(8 * 1024 * 1024),
    })
    .strict(),
};
export class Operations extends Foundation {
  async allowed(c: Tx, permission: string, employee?: string) {
    if (
      !(
        await c.query("SELECT app.allowed($1,$2) ok", [
          permission,
          employee ?? null,
        ])
      ).rows[0].ok
    )
      fail("FORBIDDEN", "This operation is not permitted", 403);
  }
  async mine(c: Tx) {
    const e = (
      await c.query(
        "SELECT id,user_id,display_name FROM app.employees WHERE user_id=app.actor_id()",
      )
    ).rows[0];
    if (!e) fail("NOT_FOUND", "No employee profile at this site", 404);
    return e;
  }
  async notify(
    c: Tx,
    recipient: string,
    module: string,
    entity: string,
    event: string,
  ) {
    await c.query("SELECT app.operation_notify($1,$2,$3,$4)", [
      recipient,
      module,
      entity,
      event,
    ]);
  }
  async notifyMany(
    c: Tx,
    recipients: string[],
    module: string,
    entity: string,
    event: string,
  ) {
    if (recipients.length)
      await c.query(
        "SELECT app.operation_notify(recipient,$2,$3,$4) FROM unnest($1::uuid[]) recipient",
        [recipients, module, entity, event],
      );
  }
  async policy(c: Tx) {
    const p = (
      await c.query(
        "SELECT version,rules,created_at FROM app.operation_policies ORDER BY version DESC LIMIT 1",
      )
    ).rows[0];
    if (!p)
      fail(
        "CONFIGURATION_REQUIRED",
        "An administrator must configure this site policy first",
        409,
      );
    return p;
  }
  async validateApprover(c: Tx, id: string, cap: string) {
    if (
      !(
        await c.query("SELECT app.operation_approver_allowed($1,$2) ok", [
          id,
          cap,
        ])
      ).rows[0]?.ok
    )
      fail("BAD_INPUT", "Approver lacks the required permission at this site");
  }
  async attendanceAdminOverride(c: Tx) {
    // A site role alone is insufficient: each decision still checks the target's
    // attendance.approve policy and prohibits self-approval.
    return !!(
      await c.query(
        `SELECT EXISTS(SELECT 1 FROM app.access_grants g
         WHERE g.organization_id=app.org_id() AND g.site_id=app.site_id()
          AND g.user_id=app.actor_id() AND g.role IN ('super_admin','admin')) AS allowed`,
      )
    ).rows[0]?.allowed;
  }
  async auditOperation(c: Tx, op: string, id: string, keys: string[]) {
    await c.query(
      "INSERT INTO app.audit_records(organization_id,site_id,actor_id,action,entity_id,metadata) VALUES(app.org_id(),app.site_id(),app.actor_id(),$1,$2,$3)",
      [`operations.${op}`, id, JSON.stringify({ fields: keys })],
    );
  }
  async attendanceReviewDay(actor: Actor, siteId: string, workDate: string) {
    const day = date.parse(workDate);
    return this.site(actor, siteId, async (c) => {
      const site = (
        await c.query("SELECT timezone FROM app.sites WHERE id=app.site_id()")
      ).rows[0];
      if (!site) fail("NOT_FOUND", "Site unavailable", 404);
      const policy = (
        await c.query(
          "SELECT rules FROM app.operation_policies ORDER BY version DESC LIMIT 1",
        )
      ).rows[0];
      const approverId = policy?.rules?.attendanceApproverId ?? null;
      // Mirrors the decision guard: the assigned approver, or a site
      // super_admin/admin even when approval is assigned to someone else.
      const authority =
        approverId === actor.id || (await this.attendanceAdminOverride(c));
      const eventRows = (
        await c.query(
          `SELECT e.id,e.duty_id,e.employee_id,e.user_id,e.kind,e.sequence,
            e.captured_at,e.received_at,e.payload->>'photoId' AS photo_id,
            e.payload->>'offsiteReason' AS offsite_reason,
            v.status,v.reason,v.effective_at,v.reviewer_id,v.reviewed_at,
            o.classification,o.accuracy_m,o.observed_at,o.reason AS location_reason,
            COALESCE(emp.display_name,'Employee') AS employee_name,
            app.allowed('attendance.approve',e.employee_id)
              AND (e.kind NOT IN ('FIELD_START','FIELD_END','VISIT_START','VISIT_END')
                OR app.allowed('field_duty.approve',e.employee_id)) AS may_approve
           FROM app.duty_events e
           JOIN app.event_verifications v ON v.event_id=e.id
           LEFT JOIN app.geofence_observations o ON o.event_id=e.id
           LEFT JOIN app.employees emp ON emp.id=e.employee_id
           WHERE (e.captured_at AT TIME ZONE $2)::date=$1::date
            AND e.kind IN ('IN','OUT','BREAK_START','BREAK_END',
              'FIELD_START','FIELD_END','VISIT_START','VISIT_END')
           ORDER BY e.captured_at,e.id LIMIT 1001`,
          [day, site.timezone],
        )
      ).rows;
      const adjustmentRows = (
        await c.query(
          `SELECT a.id,a.duty_id,a.employee_id,a.requester_id,a.starts_at,a.ends_at,
            a.kind,a.reason,a.decision_note,a.status,a.version,a.reviewer_id,
            a.reviewed_at,COALESCE(emp.display_name,'Employee') AS employee_name,
            app.allowed('attendance.approve',a.employee_id) AS may_approve
           FROM app.attendance_adjustments a
           LEFT JOIN app.employees emp ON emp.id=a.employee_id
           WHERE (a.starts_at AT TIME ZONE $2)::date=$1::date
           ORDER BY a.starts_at,a.id LIMIT 1001`,
          [day, site.timezone],
        )
      ).rows;
      const earlierPending = (
        await c.query(
          `SELECT count(*)::int count,
            to_char(min(e.captured_at AT TIME ZONE $2),'YYYY-MM-DD') first_day
           FROM app.duty_events e JOIN app.event_verifications v ON v.event_id=e.id
           WHERE v.status='pending_verification'
             AND v.organization_id=app.org_id() AND v.site_id=app.site_id()
             AND (e.captured_at AT TIME ZONE $2)::date<$1::date
             AND e.kind IN ('IN','OUT','BREAK_START','BREAK_END',
               'FIELD_START','FIELD_END','VISIT_START','VISIT_END')`,
          [day, site.timezone],
        )
      ).rows[0];
      const events = eventRows.slice(0, 1000).map((e) => ({
        ...e,
        can_decide:
          authority &&
          e.may_approve &&
          e.user_id !== actor.id &&
          e.status === "pending_verification",
      }));
      const adjustments = adjustmentRows.slice(0, 1000).map((a) => ({
        ...a,
        can_decide:
          authority &&
          a.may_approve &&
          a.requester_id !== actor.id &&
          a.status === "pending",
      }));
      const ids = [
        approverId,
        ...events.map((e) => e.reviewer_id),
        ...adjustments.map((a) => a.reviewer_id),
      ].filter(Boolean);
      const names = ids.length
        ? (
            await c.query(
              "SELECT user_id,name FROM app.attendance_actor_names($1::uuid[])",
              [[...new Set(ids)]],
            )
          ).rows
        : [];
      return {
        workDate: day,
        timezone: site.timezone,
        approverId,
        canDecide: authority,
        reviewers: Object.fromEntries(names.map((r) => [r.user_id, r.name])),
        events,
        adjustments,
        earlierPendingCount: earlierPending.count,
        oldestPendingDate: earlierPending.first_day,
        truncated: eventRows.length > 1000 || adjustmentRows.length > 1000,
      };
    });
  }
  async snapshot(
    actor: Actor,
    siteId: string,
    filter?: { workDate: string; employeeId?: string | null; offset?: number },
  ) {
    if (filter) {
      date.parse(filter.workDate);
      if (filter.employeeId) uuid.parse(filter.employeeId);
      z.number()
        .int()
        .min(0)
        .max(100000)
        .parse(filter.offset ?? 0);
    }
    return this.site(actor, siteId, async (c) => {
      const setup = await readJson(c, {
        site: [
          "SELECT name,timezone,to_char(now() AT TIME ZONE timezone,'YYYY-MM-DD') work_date FROM app.sites WHERE id=app.site_id()",
        ],
        people: filter
          ? [
              "SELECT id,display_name AS name FROM app.employees e WHERE (app.allowed('attendance.view',e.id) OR app.allowed('my_attendance.view',e.id)) AND EXISTS(SELECT 1 FROM app.site_assignments a WHERE a.employee_id=e.id AND a.site_id=app.site_id() AND $1::date BETWEEN a.starts_on AND COALESCE(a.ends_on,'infinity'::date)) ORDER BY display_name,id LIMIT 1001",
              [filter.workDate],
            ]
          : ["SELECT id,display_name AS name FROM app.employees WHERE false"],
        policy: [
          "SELECT version,rules,reason FROM app.operation_policies ORDER BY version DESC LIMIT 1",
        ],
        fence: [
          "SELECT version,label,ST_AsGeoJSON(boundary::geometry)::json AS geojson FROM app.geofence_versions ORDER BY version DESC LIMIT 1",
        ],
        me: ["SELECT id FROM app.employees WHERE user_id=app.actor_id()"],
        policies: ["SELECT version,rules FROM app.operation_policies"],
      });
      const policy = setup.policy[0] ?? null,
        fence = setup.fence[0] ?? null,
        me = setup.me[0]?.id ?? null,
        policies = setup.policies;
      const sessions = (
        await c.query(
          // max_sequence counts pending events too: clients number after it.
          `SELECT s.*,e.display_name,(SELECT max(d.sequence) FROM app.duty_events d WHERE d.duty_id=s.id) max_sequence,
            s.opened_at + (COALESCE((sp.rules->>'maxSessionHours')::int,24) * interval '1 hour') expires_at,
            to_char(s.opened_at AT TIME ZONE session_site.timezone,'YYYY-MM-DD') work_date
          FROM app.duty_sessions s LEFT JOIN app.employees e ON e.id=s.employee_id
          LEFT JOIN app.operation_policies sp ON sp.organization_id=s.organization_id AND sp.site_id=s.site_id AND sp.version=s.policy_version
          JOIN app.sites session_site ON session_site.id=s.site_id
          ${
            filter
              ? `WHERE ($2::uuid IS NULL OR s.employee_id=$2)
            AND s.opened_at < (($1::date+1)::timestamp AT TIME ZONE $3)
            AND (COALESCE(s.closed_at,s.opened_at+($4::int * interval '1 hour')) >= ($1::date::timestamp AT TIME ZONE $3)
              OR EXISTS(SELECT 1 FROM app.duty_events de WHERE de.duty_id=s.id
                AND de.captured_at >= ($1::date::timestamp AT TIME ZONE $3)
                AND de.captured_at < (($1::date+1)::timestamp AT TIME ZONE $3)))`
              : ""
          }
          ORDER BY ${filter ? "" : "(s.user_id=app.actor_id()) DESC,"}s.opened_at DESC,s.id DESC LIMIT ${filter ? "101 OFFSET $5" : "100"}`,
          filter
            ? [
                filter.workDate,
                filter.employeeId ?? null,
                setup.site[0].timezone,
                policy?.rules?.maxSessionHours ?? 24,
                filter.offset ?? 0,
              ]
            : [],
        )
      ).rows;
      const hasMore = !!filter && sessions.length > 100;
      if (hasMore) sessions.pop();
      const events = (
        await c.query(
          "SELECT e.id,e.duty_id,e.kind,e.sequence,e.captured_at,e.received_at,e.payload->>'photoId' photo_id,e.payload->>'offsiteReason' offsite_reason,e.payload->>'visitId' visit_id,v.status,v.reason,v.effective_at,o.classification,o.accuracy_m,o.observed_at,o.reason location_reason,CASE WHEN e.kind IN ('IN','OUT') OR app.allowed('field_duty.view',e.employee_id) THEN ST_Y(o.point::geometry) END latitude,CASE WHEN e.kind IN ('IN','OUT') OR app.allowed('field_duty.view',e.employee_id) THEN ST_X(o.point::geometry) END longitude FROM app.duty_events e JOIN app.event_verifications v ON v.event_id=e.id LEFT JOIN app.geofence_observations o ON o.event_id=e.id WHERE e.duty_id=ANY($1::uuid[]) ORDER BY e.received_at",
          [sessions.map((s) => s.id)],
        )
      ).rows;
      const adjustments = (
        await c.query(
          "SELECT * FROM app.attendance_adjustments WHERE duty_id=ANY($1::uuid[]) ORDER BY created_at DESC",
          [sessions.map((s) => s.id)],
        )
      ).rows;
      // Rosters for the listed sessions (late/early) plus the coming week, soonest
      // first. Newest-first would show far-future bulk schedules and hide today.
      const rosters = (
        await c.query(
          `SELECT r.* FROM app.shift_rosters r WHERE ${filter ? `(($5::uuid IS NULL OR r.employee_id=$5) AND r.starts_at < (($3::date+1)::timestamp AT TIME ZONE $4) AND r.ends_at > ($3::date::timestamp AT TIME ZONE $4))` : "(r.starts_at<now()+interval '7 days' AND r.ends_at>now()-interval '1 day')"}
          OR EXISTS(SELECT 1 FROM unnest($1::uuid[],$2::timestamptz[]) s(employee_id,opened_at) WHERE s.employee_id=r.employee_id
            AND r.starts_at BETWEEN s.opened_at-interval '18 hours' AND s.opened_at+interval '18 hours')
          ORDER BY r.starts_at LIMIT 500`,
          [
            sessions.map((s) => s.employee_id),
            sessions.map((s) => s.opened_at),
            ...(filter
              ? [
                  filter.workDate,
                  setup.site[0].timezone,
                  filter.employeeId ?? null,
                ]
              : []),
          ],
        )
      ).rows;
      for (const s of sessions) {
        const rules = policies.find(
          (p) => p.version === s.policy_version,
        )?.rules;
        if (!rules) continue;
        const scopedEvents = events
          .filter((e) => e.duty_id === s.id)
          .map((e) => this.engineEvent(e));
        if (
          s.closed_at &&
          !scopedEvents.some((e) => e.kind === "OUT" && e.status === "accepted")
        )
          scopedEvents.push({
            id: s.id,
            kind: "OUT",
            effectiveAt: s.closed_at.toISOString(),
            status: "accepted",
          });
        const project = projectDuty(
          scopedEvents,
          new Date().toISOString(),
          rules,
          adjustments
            .filter(
              (a) =>
                a.duty_id === s.id &&
                a.status === "approved" &&
                a.kind !== "overtime",
            )
            .map((a) => ({
              id: a.id,
              startsAt: a.starts_at.toISOString(),
              endsAt: a.ends_at.toISOString(),
              kind: a.kind,
            })),
        );
        Object.assign(s, project);
        s.timeAtLocation = Object.values(
          project.segments.reduce((totals: Record<string, any>, segment) => {
            const key = `${segment.visitId ?? "duty"}:${segment.kind}`;
            const row = (totals[key] ??= {
              visitId: segment.visitId,
              kind: segment.kind,
              minutes: 0,
            });
            row.minutes +=
              (epoch(segment.endsAt) - epoch(segment.startsAt)) / 60000;
            return totals;
          }, {}),
        );
        const roster = rosters.find(
          (r) =>
            r.employee_id === s.employee_id &&
            Math.abs(epoch(s.opened_at) - epoch(r.starts_at)) < 18 * 3600000,
        );
        s.late = roster
          ? epoch(s.opened_at) >
            epoch(roster.starts_at) + rules.lateGraceMinutes * 60000
          : null;
        s.early =
          roster && s.closed_at
            ? epoch(s.closed_at) <
              epoch(roster.ends_at) - rules.earlyGraceMinutes * 60000
            : null;
        s.roster = roster ?? null;
        s.overtimeMinutes = adjustments
          .filter(
            (a) =>
              a.duty_id === s.id &&
              a.status === "approved" &&
              a.kind === "overtime",
          )
          .reduce(
            (n, a) => n + (epoch(a.ends_at) - epoch(a.starts_at)) / 60000,
            0,
          );
      }
      if (filter)
        return {
          me,
          siteName: setup.site[0].name,
          timezone: setup.site[0].timezone,
          workDate: filter.workDate,
          hasMore,
          offset: filter.offset ?? 0,
          people: (setup.people ?? []).slice(0, 1000),
          peopleTruncated: (setup.people?.length ?? 0) > 1000,
          serverTime: new Date().toISOString(),
          policy,
          geofence: fence,
          sessions,
          events,
          adjustments,
          rosters,
          visits: [],
          approvers: [],
          leaveTypes: [],
          leaveRequests: [],
          balances: [],
          ledger: [],
          tasks: [],
          comments: [],
          inbox: [],
          files: [],
        };
      const data = await readJson(c, {
        site: ["SELECT name,timezone FROM app.sites WHERE id=app.site_id()"],
        approvers: ["SELECT * FROM app.operation_approvers()"],
        visits: [
          "SELECT * FROM app.field_visits ORDER BY scheduled_at DESC LIMIT 100",
        ],
        leaveTypes: ["SELECT * FROM app.leave_types ORDER BY code"],
        leaveRequests: [
          "SELECT * FROM app.leave_requests ORDER BY created_at DESC LIMIT 100",
        ],
        balances: [
          "SELECT employee_id,type_id,sum(units)::text balance FROM app.leave_ledger WHERE effective_on<=CURRENT_DATE GROUP BY employee_id,type_id",
        ],
        ledger: [
          "SELECT * FROM app.leave_ledger ORDER BY created_at DESC LIMIT 100",
        ],
        tasks: ["SELECT * FROM app.work_tasks ORDER BY deadline LIMIT 100"],
        comments: [
          "SELECT * FROM app.task_comments ORDER BY created_at DESC LIMIT 200",
        ],
        inbox: [
          "SELECT id,module,entity_id,event_type,created_at,read_at,push_status FROM app.inbox_items ORDER BY created_at DESC LIMIT 100",
        ],
        files: [
          "SELECT id,purpose,parent_id,declared_type,status,scan_result FROM app.private_files WHERE owner_id=app.actor_id() ORDER BY created_at DESC LIMIT 100",
        ],
      });
      const { site, ...lists } = data;
      return {
        ...lists,
        me,
        siteName: site[0].name,
        timezone: site[0].timezone,
        workDate: setup.site[0].work_date,
        serverTime: new Date().toISOString(),
        policy,
        geofence: fence,
        sessions,
        events,
        adjustments,
        rosters,
      };
    });
  }
  engineEvent(e: any): DutyEvent {
    return {
      id: e.id,
      kind: e.kind,
      effectiveAt: e.effective_at
        ? new Date(e.effective_at).toISOString()
        : null,
      status: e.status,
      observation: e.classification,
      visitId: e.visit_id,
    };
  }
  async command(actor: Actor, siteId: string, operation: string, raw: unknown) {
    if (
      operation === "fileIntent" &&
      process.env.FILE_STORAGE_DISABLED === "true"
    )
      fail("STORAGE_UNAVAILABLE", "Private storage is not configured", 503);
    const schema = schemas[operation as keyof typeof schemas];
    if (!schema) fail("BAD_INPUT", "Unknown operation");
    const p: any = schema.parse(raw);
    return this.site(actor, siteId, async (c) => {
      await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
        `${actor.organizationId}:operations:${actor.id}`,
      ]);
      let result: any;
      if (operation === "event") return this.event(c, actor, p);
      if (operation === "policy" || operation === "geofence") {
        await this.allowed(c, "site_settings.manage");
        await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
          `${actor.organizationId}:policy:${siteId}`,
        ]);
        const table =
          operation === "policy" ? "operation_policies" : "geofence_versions";
        const v = (
          await c.query(
            `SELECT COALESCE(max(version),0)::int v FROM app.${table}`,
          )
        ).rows[0].v;
        if (v !== p.expectedVersion)
          fail("CONFLICT", "Configuration changed; reload");
        if (operation === "policy") {
          await this.validateApprover(
            c,
            p.rules.attendanceApproverId,
            "attendance.approve",
          );
          result = (
            await c.query(
              "INSERT INTO app.operation_policies(organization_id,site_id,version,rules,reason) VALUES(app.org_id(),app.site_id(),$1,$2,$3) RETURNING id,version",
              [v + 1, p.rules, p.reason],
            )
          ).rows[0];
        } else {
          const coords = p.coordinates;
          if (JSON.stringify(coords[0]) !== JSON.stringify(coords.at(-1)))
            fail("BAD_INPUT", "Polygon must be closed");
          const geo = JSON.stringify({
            type: "Polygon",
            coordinates: [coords],
          });
          const ok = (
            await c.query(
              "SELECT ST_IsValid(g) AND ST_Area(g::geography) BETWEEN 10 AND 100000000 valid FROM (SELECT ST_SetSRID(ST_GeomFromGeoJSON($1),4326) g) x",
              [geo],
            )
          ).rows[0].valid;
          if (!ok)
            fail("BAD_INPUT", "Geofence must be a valid 10 m²–100 km² polygon");
          result = (
            await c.query(
              "INSERT INTO app.geofence_versions(organization_id,site_id,version,boundary,label,reason) VALUES(app.org_id(),app.site_id(),$1,ST_SetSRID(ST_GeomFromGeoJSON($2),4326)::geography,$3,$4) RETURNING id,version",
              [v + 1, geo, p.label, p.reason],
            )
          ).rows[0];
        }
      } else if (operation === "roster") {
        await this.allowed(c, "attendance.edit", p.employeeId);
        await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
          `${actor.organizationId}:roster:${p.employeeId}`,
        ]);
        const shift = await this.activeShift(c, p.shiftId);
        result = await this.assignRoster(
          c,
          p.employeeId,
          shift,
          p.workDate,
          p.expectedVersion,
        );
        if (!result) fail("CONFLICT", "Roster overlaps another shift");
      } else if (operation === "rosterRange") {
        const shift = await this.activeShift(c, p.shiftId);
        // Sorted lock order keeps concurrent bulk schedules deadlock-free.
        const ids = [...p.employeeIds].sort();
        if (
          !(
            await c.query(
              "SELECT NOT EXISTS(SELECT 1 FROM unnest($1::uuid[]) employee WHERE app.allowed('attendance.edit',employee) IS NOT TRUE) ok",
              [ids],
            )
          ).rows[0].ok
        )
          fail("FORBIDDEN", "This operation is not permitted", 403);
        await c.query(
          "SELECT pg_advisory_xact_lock(hashtextextended($2||':roster:'||employee,0)) FROM (SELECT unnest($1::uuid[]) employee ORDER BY 1) ordered",
          [ids, actor.organizationId],
        );
        // Active site holidays are not duty days; they are reported, not assigned.
        const days = (
          await c.query(
            `SELECT to_char(d,'YYYY-MM-DD') d,EXISTS(SELECT 1 FROM app.site_reference_items h WHERE h.kind='holiday' AND h.active AND h.details->>'date'=to_char(d,'YYYY-MM-DD')) holiday
            FROM app.sites s, generate_series($1::date,$2::date,interval '1 day') d
            WHERE s.id=app.site_id() AND extract(dow FROM d)::int=ANY($3::int[]) AND d::date>=(now() AT TIME ZONE s.timezone)::date`,
            [p.fromDate, p.toDate, p.weekdays],
          )
        ).rows;
        const holidays = days
          .filter((r) => r.holiday)
          .map((r) => r.d as string);
        const dates = days.filter((r) => !r.holiday).map((r) => r.d as string);
        if (!dates.length)
          fail(
            "BAD_INPUT",
            holidays.length
              ? "Every chosen day is a site holiday"
              : "No working days from today in the chosen range",
          );
        const batch = await this.assignRosterBatch(c, ids, shift, dates);
        result = { id: shift.id, ...batch, holidays };
      } else if (
        operation === "adjustment" ||
        operation === "reviewAdjustment" ||
        operation === "verifyEvent"
      ) {
        result = await this.adjust(c, actor, operation, p);
      } else if (operation === "visit") {
        await this.allowed(c, "field_duty.create", p.employeeId);
        const e = (
          await c.query("SELECT user_id FROM app.employees WHERE id=$1", [
            p.employeeId,
          ])
        ).rows[0];
        if (!e?.user_id) fail("NOT_FOUND", "Employee missing");
        result = (
          await c.query(
            "INSERT INTO app.field_visits(organization_id,site_id,employee_id,assignee_id,title,scheduled_at,latitude,longitude,radius_m,notes) VALUES(app.org_id(),app.site_id(),$1,$2,$3,$4,$5,$6,$7,$8) RETURNING id",
            [
              p.employeeId,
              e.user_id,
              p.title,
              p.scheduledAt,
              p.latitude,
              p.longitude,
              p.radiusM,
              p.notes,
            ],
          )
        ).rows[0];
        await this.notify(
          c,
          e.user_id,
          "field_duty",
          result.id,
          "visit.assigned",
        );
      } else if (operation.startsWith("leave") || operation === "reviewLeave") {
        result = await this.leave(c, actor, operation, p);
      } else if (["task", "taskStatus", "comment"].includes(operation)) {
        result = await this.task(c, actor, operation, p);
      } else if (operation === "readInbox") {
        result = (
          await c.query(
            "UPDATE app.inbox_items SET read_at=now() WHERE id=$1 AND user_id=app.actor_id() RETURNING id",
            [p.id],
          )
        ).rows[0];
        if (!result) fail("NOT_FOUND", "Inbox item unavailable");
      } else if (operation === "fileIntent") {
        let employeeId: string;
        if (p.purpose !== "task" && p.type === "application/pdf")
          fail("BAD_INPUT", "Photo evidence must be JPEG or PNG");
        if (p.purpose === "task") {
          if (!p.parentId) fail("BAD_INPUT", "Task required");
          const task = (
            await c.query(
              "SELECT employee_id,assignee_id FROM app.work_tasks WHERE id=$1",
              [p.parentId],
            )
          ).rows[0];
          if (!task) fail("NOT_FOUND", "Task unavailable");
          employeeId = task.employee_id;
          await this.allowed(
            c,
            task.assignee_id === actor.id ? "tasks.submit" : "tasks.edit",
            employeeId,
          );
        } else {
          employeeId = (await this.mine(c)).id;
          await this.allowed(
            c,
            p.purpose === "visit"
              ? "field_duty.submit"
              : "my_attendance.create",
            employeeId,
          );
        }
        const existing = (
          await c.query(
            "SELECT id,status,declared_type,byte_limit,purpose,parent_id FROM app.private_files WHERE owner_id=app.actor_id() AND client_id=$1",
            [p.clientId],
          )
        ).rows[0];
        if (existing) {
          if (
            existing.declared_type !== p.type ||
            existing.byte_limit !== p.bytes ||
            existing.purpose !== p.purpose ||
            existing.parent_id !== (p.parentId ?? null)
          )
            fail("CONFLICT", "Upload ID reused with different data");
          return existing;
        }
        const id = randomUUID();
        result = (
          await c.query(
            "INSERT INTO app.private_files(id,organization_id,site_id,employee_id,owner_id,client_id,purpose,parent_id,declared_type,byte_limit,object_key) VALUES($1,app.org_id(),app.site_id(),$2,app.actor_id(),$3,$4,$5,$6,$7,$8) RETURNING id,status",
            [
              id,
              employeeId,
              p.clientId,
              p.purpose,
              p.parentId ?? null,
              p.type,
              p.bytes,
              `${actor.organizationId}/${siteId}/${actor.id}/${id}`,
            ],
          )
        ).rows[0];
      }
      if (!result) fail("BAD_INPUT", "Operation produced no result");
      await this.auditOperation(
        c,
        operation,
        result.id ?? randomUUID(),
        Object.keys(p),
      );
      return result;
    });
  }
  async activeShift(c: Tx, shiftId: string) {
    const shift = (
      await c.query(
        "SELECT * FROM app.site_reference_items WHERE id=$1 AND kind='shift' AND active",
        [shiftId],
      )
    ).rows[0];
    if (!shift) fail("BAD_INPUT", "Choose an active shift");
    return shift;
  }
  /** Caller holds the sorted per-employee advisory locks. Simulate the same
   * chronological overlap decisions as single assignment, then persist once. */
  async assignRosterBatch(
    c: Tx,
    employees: string[],
    shift: any,
    dates: string[],
  ) {
    const windows = (
      await c.query(
        `SELECT d::text AS day,(d+(($2::jsonb)->>'startTime')::time) AT TIME ZONE timezone start,
        (d+(($2::jsonb)->>'endTime')::time+CASE WHEN (($2::jsonb)->>'endTime')::time<=(($2::jsonb)->>'startTime')::time THEN interval '1 day' ELSE interval '0 day' END) AT TIME ZONE timezone finish
        FROM app.sites,unnest($1::date[]) d WHERE id=app.site_id() ORDER BY d`,
        [dates, shift.details],
      )
    ).rows;
    const existing = (
      await c.query(
        `SELECT id,employee_id,work_date::text AS day,starts_at,ends_at FROM app.shift_rosters
        WHERE employee_id=ANY($1::uuid[]) AND (work_date=ANY($2::date[]) OR (starts_at<$4 AND ends_at>$3))
        ORDER BY employee_id,work_date FOR UPDATE`,
        [employees, dates, windows[0].start, windows.at(-1).finish],
      )
    ).rows;
    const accepted: {
      employee: string;
      day: string;
      start: Date;
      finish: Date;
    }[] = [];
    const skipped: { employeeId: string; workDate: string }[] = [];
    for (const employee of employees) {
      const current = new Map(
        existing
          .filter((r) => r.employee_id === employee)
          .map((r) => [r.day, r]),
      );
      for (const w of windows) {
        if (
          [...current.values()].some(
            (r) =>
              r.day !== w.day &&
              +r.starts_at < +w.finish &&
              +r.ends_at > +w.start,
          )
        ) {
          skipped.push({ employeeId: employee, workDate: w.day });
          continue;
        }
        accepted.push({
          employee,
          day: w.day,
          start: w.start,
          finish: w.finish,
        });
        current.set(w.day, {
          day: w.day,
          starts_at: w.start,
          ends_at: w.finish,
        });
      }
    }
    if (accepted.length)
      await c.query(
        `INSERT INTO app.shift_rosters(organization_id,site_id,employee_id,shift_id,work_date,starts_at,ends_at)
        SELECT app.org_id(),app.site_id(),r.employee,$1,r.day,r.start,r.finish
        FROM json_to_recordset($2::json) AS r(employee uuid,day date,start timestamptz,finish timestamptz)
        ORDER BY r.employee,r.day
        ON CONFLICT(organization_id,employee_id,work_date) DO UPDATE SET shift_id=excluded.shift_id,starts_at=excluded.starts_at,ends_at=excluded.ends_at,version=app.shift_rosters.version+1
        WHERE (app.shift_rosters.shift_id,app.shift_rosters.starts_at,app.shift_rosters.ends_at) IS DISTINCT FROM (excluded.shift_id,excluded.starts_at,excluded.ends_at)`,
        [shift.id, JSON.stringify(accepted)],
      );
    return { assigned: accepted.length, skipped };
  }
  /** Upserts one site-local dated roster. Null when it overlaps another shift.
   *  Without expectedVersion an existing roster for that date is replaced. */
  async assignRoster(
    c: Tx,
    employeeId: string,
    shift: any,
    workDate: string,
    expectedVersion?: number,
  ) {
    const row = (
      await c.query(
        "SELECT ($1::date+(($2::jsonb)->>'startTime')::time) AT TIME ZONE timezone start, ($1::date+(($2::jsonb)->>'endTime')::time+CASE WHEN (($2::jsonb)->>'endTime')::time<= (($2::jsonb)->>'startTime')::time THEN interval '1 day' ELSE interval '0 day' END) AT TIME ZONE timezone finish FROM app.sites WHERE id=app.site_id()",
        [workDate, shift.details],
      )
    ).rows[0];
    const old = (
      await c.query(
        "SELECT * FROM app.shift_rosters WHERE employee_id=$1 AND work_date=$2 FOR UPDATE",
        [employeeId, workDate],
      )
    ).rows[0];
    if (
      expectedVersion !== undefined &&
      (old?.version ?? 0) !== expectedVersion
    )
      fail("CONFLICT", "Roster changed");
    const overlap = (
      await c.query(
        "SELECT id FROM app.shift_rosters WHERE employee_id=$1 AND id<>$2 AND tstzrange(starts_at,ends_at) && tstzrange($3,$4)",
        [employeeId, old?.id ?? randomUUID(), row.start, row.finish],
      )
    ).rowCount;
    if (overlap) return null;
    // A bulk re-apply keeps identical rosters' versions so live tracking is
    // not interrupted; an explicit single edit always bumps the version.
    return (
      (
        await c.query(
          `INSERT INTO app.shift_rosters(organization_id,site_id,employee_id,shift_id,work_date,starts_at,ends_at) VALUES(app.org_id(),app.site_id(),$1,$2,$3,$4,$5) ON CONFLICT(organization_id,employee_id,work_date) DO UPDATE SET shift_id=excluded.shift_id,starts_at=excluded.starts_at,ends_at=excluded.ends_at,version=app.shift_rosters.version+1
          WHERE $6 OR (app.shift_rosters.shift_id,app.shift_rosters.starts_at,app.shift_rosters.ends_at) IS DISTINCT FROM (excluded.shift_id,excluded.starts_at,excluded.ends_at) RETURNING id,version`,
          [
            employeeId,
            shift.id,
            workDate,
            row.start,
            row.finish,
            expectedVersion !== undefined,
          ],
        )
      ).rows[0] ?? { id: old.id, version: old.version }
    );
  }
  async event(c: Tx, actor: Actor, p: z.infer<typeof eventSchema>) {
    const me = await this.mine(c);
    await this.allowed(c, "my_attendance.create", me.id);
    const hash = createHash("sha256").update(JSON.stringify(p)).digest("hex");
    const duplicate = (
      await c.query(
        "SELECT e.id,e.payload_hash,v.status,v.reason FROM app.duty_events e JOIN app.event_verifications v ON v.event_id=e.id WHERE e.client_event_id=$1 AND e.user_id=app.actor_id()",
        [p.clientEventId],
      )
    ).rows[0];
    if (duplicate) {
      if (duplicate.payload_hash !== hash)
        fail("CONFLICT", "Event ID already exists with another payload");
      return duplicate;
    }
    const current = await this.policy(c),
      rulesRow = (
        await c.query(
          "SELECT rules FROM app.operation_policies WHERE version=$1",
          [p.policyVersion],
        )
      ).rows[0];
    if (!rulesRow) fail("BAD_INPUT", "Unknown policy version");
    const rules = policySchema.parse(rulesRow.rules);
    const fence = (
      await c.query(
        "SELECT id,created_at,(SELECT max(version) FROM app.geofence_versions) current_version FROM app.geofence_versions WHERE version=$1",
        [p.geofenceVersion],
      )
    ).rows[0];
    if (!fence)
      fail("CONFIGURATION_REQUIRED", "A valid versioned geofence is required");
    const capture = epoch(p.capturedAt),
      received = Date.now();
    const assigned = (
      await c.query(
        "SELECT 1 FROM app.site_assignments a JOIN app.sites s ON s.id=a.site_id WHERE a.employee_id=$1 AND a.site_id=app.site_id() AND a.starts_on<=($2::timestamptz AT TIME ZONE s.timezone)::date AND (a.ends_on IS NULL OR a.ends_on>=($2::timestamptz AT TIME ZONE s.timezone)::date)",
        [me.id, p.capturedAt],
      )
    ).rowCount;
    if (!assigned)
      fail("FORBIDDEN", "No effective assignment at capture time", 403);
    const device = (
      await c.query("SELECT app.operation_device($1) id", [actor.sessionId])
    ).rows[0]?.id;
    if (!device) fail("UNAUTHENTICATED", "Device session expired");
    let session = (
      await c.query("SELECT * FROM app.duty_sessions WHERE id=$1 FOR UPDATE", [
        p.dutyId,
      ])
    ).rows[0];
    if (!session) {
      if (p.kind !== "IN")
        fail("CONFLICT", "Entry must synchronize before subsequent events");
      if (p.sequence !== 1)
        fail("BAD_INPUT", "A new session begins at event 1");
      // The old day remains in review with its real evidence and no invented
      // OUT. This releases the single-open-duty constraint for a new IN.
      await c.query(
        `UPDATE app.duty_sessions s SET status='needs_review',version=s.version+1
         FROM app.operation_policies old
         WHERE s.organization_id=app.org_id() AND s.site_id=app.site_id()
           AND s.employee_id=$1 AND s.status='open'
           AND old.organization_id=s.organization_id AND old.site_id=s.site_id
           AND old.version=s.policy_version
           AND s.opened_at+(old.rules->>'maxSessionHours')::int*interval '1 hour'<=$2::timestamptz
           AND s.opened_at+(old.rules->>'maxSessionHours')::int*interval '1 hour'<=now()`,
        [me.id, p.capturedAt],
      );
      session = (
        await c.query(
          "INSERT INTO app.duty_sessions(id,organization_id,site_id,employee_id,user_id,device_id,policy_version,geofence_version,opened_at) VALUES($1,app.org_id(),app.site_id(),$2,app.actor_id(),$3,$4,$5,$6) ON CONFLICT (organization_id,employee_id) WHERE status='open' DO NOTHING RETURNING *",
          [
            p.dutyId,
            me.id,
            device,
            p.policyVersion,
            p.geofenceVersion,
            p.capturedAt,
          ],
        )
      ).rows[0];
      if (!session)
        fail(
          "CONFLICT",
          "An open duty exists at the original site or device; close or correct it before transferring",
        );
    } else if (session.user_id !== actor.id || session.device_id !== device)
      fail(
        "CONFLICT",
        "This duty belongs to its original device. Request a correction or finish it there",
      );
    if (
      session.policy_version !== p.policyVersion ||
      session.geofence_version !== p.geofenceVersion
    )
      fail(
        "CONFLICT",
        "Event policy and geofence must match the original duty",
      );
    if (
      ["FIELD_START", "FIELD_END", "VISIT_START", "VISIT_END"].includes(p.kind)
    )
      await this.allowed(c, "field_duty.submit", me.id);
    if (
      p.kind === "LOCATION" &&
      (session.status !== "open" ||
        capture > epoch(session.opened_at) + rules.maxSessionHours * 3600000)
    )
      fail("FORBIDDEN", "Tracking is permitted only during active duty");
    if (p.kind === "LOCATION") {
      if (
        (await c.query("SELECT 1 FROM app.tracking_policies LIMIT 1")).rowCount
      )
        fail("FORBIDDEN", "Use HR-scheduled duty location sharing");
      const entered = (
        await c.query(
          "SELECT 1 FROM app.duty_events e JOIN app.event_verifications v ON v.event_id=e.id WHERE e.duty_id=$1 AND e.kind='IN' AND v.status='accepted' AND v.effective_at<=$2",
          [session.id, p.capturedAt],
        )
      ).rowCount;
      if (!entered)
        fail(
          "FORBIDDEN",
          "A verified entry is required before legacy location capture",
        );
    }
    let photoCreatedAt: number | null = null;
    if (["IN", "OUT", "VISIT_START", "VISIT_END"].includes(p.kind)) {
      if (!p.photoId)
        fail(
          "PHOTO_REQUIRED",
          "Complete photo upload before submitting the event",
        );
      const photo = (
        await c.query(
          "SELECT id,created_at FROM app.private_files WHERE id=$1 AND owner_id=app.actor_id() AND status='ready' AND purpose IN ('attendance','visit')",
          [p.photoId],
        )
      ).rows[0];
      if (!photo)
        fail(
          "PHOTO_NOT_READY",
          "Photo is missing, quarantined or not yet uploaded",
        );
      photoCreatedAt = epoch(photo.created_at);
    }
    let visit: any;
    if (p.visitId) {
      visit = (
        await c.query(
          "SELECT * FROM app.field_visits WHERE id=$1 AND assignee_id=app.actor_id() FOR UPDATE",
          [p.visitId],
        )
      ).rows[0];
      if (!visit) fail("FORBIDDEN", "Visit is not assigned to you");
    }
    if (p.kind.startsWith("VISIT_") && !p.visitId)
      fail("BAD_INPUT", "Visit required");
    let observation: "inside" | "outside" | "unknown" = "unknown",
      observationReason = "No location observation";
    if (p.location) {
      const l = p.location;
      if (l.mocked) observationReason = "Device reports mock location";
      else if (l.accuracyM > rules.maxAccuracyM)
        observationReason = "Accuracy exceeds policy limit";
      else if (
        Math.abs(capture - epoch(l.observedAt)) >
        rules.freshnessSeconds * 1000
      )
        observationReason = "Observation is stale relative to capture";
      else {
        const row = (
          await c.query(
            "SELECT ST_Covers(boundary::geometry,point::geometry) inside, ST_Distance(ST_Boundary(boundary::geometry)::geography,point) edge FROM app.geofence_versions CROSS JOIN (SELECT ST_SetSRID(ST_MakePoint($1,$2),4326)::geography point) p WHERE version=$3",
            [l.longitude, l.latitude, p.geofenceVersion],
          )
        ).rows[0];
        observation =
          row.edge <= l.accuracyM
            ? "unknown"
            : row.inside
              ? "inside"
              : "outside";
        observationReason =
          observation === "unknown"
            ? "Accuracy circle crosses geofence boundary"
            : "Geodesic distance in meters against versioned boundary";
      }
    }
    if (p.kind === "OUT" && observation !== "inside" && !p.offsiteReason)
      fail(
        "OFFSITE_REASON_REQUIRED",
        "Explain why you are marking OUT outside the site or without a verified location. It will count only after approval.",
      );
    // Rejected evidence must not permanently block the next valid submission.
    // Missing sequences and earlier pending evidence still need resolution.
    const skipped = (
      await c.query(
        "SELECT count(*)::int n FROM app.duty_events e JOIN app.event_verifications v ON v.event_id=e.id WHERE e.duty_id=$1 AND e.sequence>$2 AND e.sequence<$3 AND v.status='rejected'",
        [session.id, session.last_sequence, p.sequence],
      )
    ).rows[0].n;
    const previous = (
      await c.query(
        "SELECT e.kind,e.sequence,e.payload->>'visitId' visit_id,v.effective_at FROM app.duty_events e JOIN app.event_verifications v ON v.event_id=e.id WHERE e.duty_id=$1 AND v.status='accepted' ORDER BY e.sequence",
        [session.id],
      )
    ).rows;
    let status = "accepted",
      why =
        "Evidence accepted under versioned policy; device time within server window";
    const reject = (message: string) => {
      status = "pending_verification";
      why = message;
    };
    if (session.status !== "open")
      reject(
        "Duty closed or awaiting missed-exit review; inspect delayed evidence",
      );
    else if (p.sequence !== session.last_sequence + skipped + 1)
      reject("Out-of-order sequence; raw evidence preserved");
    else if (previous.length && capture < epoch(previous.at(-1)!.effective_at))
      reject("Device clock moved backward");
    else if (!stateAfter([...previous.map((e) => e.kind), p.kind]))
      reject("Invalid event order or duplicate tap");
    else if (capture > received + rules.clockSkewSeconds * 1000)
      reject("Device capture clock is ahead of server");
    else if (
      !onlineEvidenceTimely(
        capture,
        received,
        photoCreatedAt,
        rules.freshnessSeconds,
      )
    )
      reject(
        !rules.allowOffline
          ? "Offline capture is not enabled"
          : received - capture > rules.offlineMaxHours * 3600000
            ? "Upload exceeds configured offline window"
            : "Delayed upload requires independent verification",
      );
    else if (p.kind === "IN" && fence.current_version !== p.geofenceVersion)
      reject("Geofence changed since capture; review original evidence");
    else if (capture < epoch(fence.created_at) - rules.clockSkewSeconds * 1000)
      reject("Capture predates the declared geofence version");
    else if (current.version !== p.policyVersion)
      reject("Policy changed since capture");
    else if (["IN", "OUT"].includes(p.kind) && observation !== "inside")
      reject(
        "Entry/exit location is outside or unverified; no absence inferred",
      );
    else if (
      capture - epoch(session.opened_at) >
      rules.maxSessionHours * 3600000
    )
      reject("Maximum duty duration exceeded; missed-exit review required");
    if (p.kind.startsWith("VISIT_")) {
      const activeVisit = [...previous]
        .reverse()
        .find((e) => e.kind.startsWith("VISIT_"));
      if (p.kind === "VISIT_END" && activeVisit?.visit_id !== p.visitId)
        reject("Departure must match the active assigned visit");
      if (p.kind === "VISIT_START" && visit.status !== "assigned")
        reject("Visit already started or completed");
      if (!p.location || observation === "unknown")
        reject("Visit location is unverified");
      else {
        const distance = (
          await c.query(
            "SELECT ST_Distance(ST_SetSRID(ST_MakePoint($1,$2),4326)::geography,ST_SetSRID(ST_MakePoint($3,$4),4326)::geography) meters",
            [
              p.location.longitude,
              p.location.latitude,
              visit.longitude,
              visit.latitude,
            ],
          )
        ).rows[0].meters;
        if (distance + p.location.accuracyM > visit.radius_m)
          reject("Visit accuracy circle is not inside the assigned location");
      }
    }
    const id = randomUUID();
    await c.query(
      "INSERT INTO app.duty_events(id,organization_id,site_id,employee_id,user_id,duty_id,client_event_id,device_id,sequence,kind,captured_at,payload_version,payload_hash,payload) VALUES($1,app.org_id(),app.site_id(),$2,app.actor_id(),$3,$4,$5,$6,$7,$8,$9,$10,$11)",
      [
        id,
        me.id,
        session.id,
        p.clientEventId,
        device,
        p.sequence,
        p.kind,
        p.capturedAt,
        p.payloadVersion,
        hash,
        p,
      ],
    );
    await c.query(
      "INSERT INTO app.event_verifications(organization_id,site_id,employee_id,event_id,status,reason,effective_at) VALUES(app.org_id(),app.site_id(),$1,$2,$3,$4,$5)",
      [me.id, id, status, why, status === "accepted" ? p.capturedAt : null],
    );
    const l = p.location;
    await c.query(
      "INSERT INTO app.geofence_observations(organization_id,site_id,employee_id,event_id,geofence_version,point,accuracy_m,observed_at,classification,reason) VALUES(app.org_id(),app.site_id(),$1,$2,$3,CASE WHEN $4::double precision IS NULL THEN NULL ELSE ST_SetSRID(ST_MakePoint($4,$5),4326)::geography END,$6,$7,$8,$9)",
      [
        me.id,
        id,
        p.geofenceVersion,
        l?.longitude ?? null,
        l?.latitude ?? null,
        l?.accuracyM ?? null,
        l?.observedAt ?? null,
        observation,
        observationReason,
      ],
    );
    if (status === "accepted") {
      await c.query(
        "UPDATE app.duty_sessions SET last_sequence=$2,status=CASE WHEN $3='OUT' THEN 'closed' ELSE status END,closed_at=CASE WHEN $3='OUT' THEN $4::timestamptz ELSE closed_at END,version=version+1 WHERE id=$1",
        [session.id, p.sequence, p.kind, p.capturedAt],
      );
      await this.updateVisit(c, p.kind, p.visitId);
      await this.project(c, session.id);
    }
    if (p.kind !== "LOCATION")
      await this.notify(c, actor.id, "attendance", id, `attendance.${status}`);
    if (status !== "accepted")
      await this.notify(
        c,
        rules.attendanceApproverId,
        "attendance",
        id,
        "attendance.review_required",
      );
    await this.auditOperation(c, "event", id, [
      "kind",
      "evidence",
      "policyVersion",
    ]);
    return {
      id,
      status,
      reason: why,
      dutyId: session.id,
      sequence: p.sequence,
    };
  }
  async updateVisit(c: Tx, kind: string, visitId?: string) {
    if (visitId && ["VISIT_START", "VISIT_END"].includes(kind))
      await c.query(
        "UPDATE app.field_visits SET status=$2,version=version+1 WHERE id=$1",
        [visitId, kind === "VISIT_START" ? "in_progress" : "completed"],
      );
  }
  async project(c: Tx, dutyId: string) {
    const session = (
      await c.query("SELECT * FROM app.duty_sessions WHERE id=$1", [dutyId])
    ).rows[0];
    const events = (
      await c.query(
        "SELECT e.id,e.kind,e.payload->>'visitId' visit_id,v.effective_at,v.status,o.classification FROM app.duty_events e JOIN app.event_verifications v ON v.event_id=e.id LEFT JOIN app.geofence_observations o ON o.event_id=e.id WHERE e.duty_id=$1",
        [dutyId],
      )
    ).rows;
    const adj = (
      await c.query(
        "SELECT * FROM app.attendance_adjustments WHERE duty_id=$1 AND status='approved' AND kind<>'overtime'",
        [dutyId],
      )
    ).rows;
    const rules = (
      await c.query(
        "SELECT rules FROM app.operation_policies WHERE version=$1",
        [session.policy_version],
      )
    ).rows[0].rules;
    const projectedEvents = events.map((e) => this.engineEvent(e));
    if (
      session.closed_at &&
      !projectedEvents.some((e) => e.kind === "OUT" && e.status === "accepted")
    )
      projectedEvents.push({
        id: session.id,
        kind: "OUT",
        effectiveAt: session.closed_at.toISOString(),
        status: "accepted",
      });
    const projection = projectDuty(
      projectedEvents,
      new Date().toISOString(),
      rules,
      adj.map((a) => ({
        id: a.id,
        startsAt: a.starts_at.toISOString(),
        endsAt: a.ends_at.toISOString(),
        kind: a.kind,
      })),
    );
    if (projection.segments.length)
      await c.query(
        `INSERT INTO app.duty_segments(organization_id,site_id,employee_id,duty_id,revision,engine_version,starts_at,ends_at,kind,source_ids,assumption,visit_id)
        SELECT app.org_id(),app.site_id(),$1,$2,$3,$4,s."startsAt",s."endsAt",s.kind,s."sourceIds",s.assumption,s."visitId"
        FROM json_to_recordset($5::json) AS s("startsAt" timestamptz,"endsAt" timestamptz,kind text,"sourceIds" jsonb,assumption text,"visitId" uuid)`,
        [
          session.employee_id,
          dutyId,
          session.version,
          projection.version,
          JSON.stringify(projection.segments),
        ],
      );
    return projection;
  }
  async withinArchivedDuty(c: Tx, duty: any, at: string | Date) {
    const policy = (
      await c.query(
        "SELECT rules FROM app.operation_policies WHERE version=$1",
        [duty.policy_version],
      )
    ).rows[0];
    if (!policy)
      fail("CONFIGURATION_REQUIRED", "Original duty policy is unavailable");
    const start = epoch(duty.opened_at),
      end = start + policySchema.parse(policy.rules).maxSessionHours * 3600000,
      time = epoch(at);
    return time >= start && time <= end;
  }
  async adjust(c: Tx, actor: Actor, operation: string, p: any) {
    if (operation === "adjustment") {
      const me = await this.mine(c);
      await this.allowed(c, "my_attendance.submit", me.id);
      const d = (
        await c.query(
          "SELECT * FROM app.duty_sessions WHERE id=$1 AND user_id=app.actor_id()",
          [p.dutyId],
        )
      ).rows[0];
      if (!d) fail("NOT_FOUND", "Duty unavailable");
      if (p.closeSession && !["open", "needs_review"].includes(d.status))
        fail(
          "CONFLICT",
          "Only an unresolved missed-exit session can be closed",
        );
      if (
        p.closeSession &&
        d.status === "needs_review" &&
        !(await this.withinArchivedDuty(c, d, p.endsAt))
      )
        fail("BAD_INPUT", "Missed-exit time exceeds the original duty window");
      if (
        epoch(p.endsAt) <= epoch(p.startsAt) ||
        epoch(p.startsAt) < epoch(d.opened_at) ||
        epoch(p.endsAt) > Date.now() ||
        (d.closed_at && epoch(p.endsAt) > epoch(d.closed_at))
      )
        fail(
          "BAD_INPUT",
          "Adjustment interval must be within captured duty and past time",
        );
      const result = (
        await c.query(
          "INSERT INTO app.attendance_adjustments(organization_id,site_id,employee_id,duty_id,requester_id,starts_at,ends_at,kind,reason,close_session) VALUES(app.org_id(),app.site_id(),$1,$2,app.actor_id(),$3,$4,$5,$6,$7) RETURNING id,status",
          [me.id, d.id, p.startsAt, p.endsAt, p.kind, p.reason, p.closeSession],
        )
      ).rows[0];
      await this.notify(
        c,
        (await this.policy(c)).rules.attendanceApproverId,
        "attendance",
        result.id,
        "adjustment.requested",
      );
      return result;
    }
    const policy = await this.policy(c);
    if (
      policy.rules.attendanceApproverId !== actor.id &&
      !(await this.attendanceAdminOverride(c))
    )
      fail(
        "FORBIDDEN",
        "Only the configured attendance approver or an authorized admin can decide",
      );
    if (operation === "verifyEvent") {
      const e = (
        await c.query(
          "SELECT e.*,v.status FROM app.duty_events e JOIN app.event_verifications v ON v.event_id=e.id WHERE e.id=$1 FOR UPDATE OF v",
          [p.id],
        )
      ).rows[0];
      if (!e) fail("NOT_FOUND", "Event unavailable");
      await this.allowed(c, "attendance.approve", e.employee_id);
      if (e.kind.startsWith("VISIT_") || e.kind.startsWith("FIELD_"))
        await this.allowed(c, "field_duty.approve", e.employee_id);
      if (e.user_id === actor.id)
        fail("FORBIDDEN", "Self approval is prohibited");
      if (e.status !== p.expectedStatus)
        fail("CONFLICT", "Event already reviewed");
      const d = (
        await c.query(
          "SELECT * FROM app.duty_sessions WHERE id=$1 FOR UPDATE",
          [e.duty_id],
        )
      ).rows[0];
      if (p.approve) {
        if (!p.effectiveAt || epoch(p.effectiveAt) > Date.now())
          fail("BAD_INPUT", "Confirm a past effective time");
        if (
          d.status === "needs_review" &&
          !(await this.withinArchivedDuty(c, d, p.effectiveAt))
        )
          fail("BAD_INPUT", "Confirmed time exceeds the original duty window");
        const prior = (
          await c.query(
            "SELECT e.kind,v.effective_at FROM app.duty_events e JOIN app.event_verifications v ON v.event_id=e.id WHERE e.duty_id=$1 AND v.status='accepted' ORDER BY e.sequence",
            [d.id],
          )
        ).rows;
        // New offsite OUT captures require the employee reason at ingestion.
        // Older immutable evidence remains reviewable with the approver's note.
        const skipped = (
          await c.query(
            "SELECT count(*)::int n FROM app.duty_events e JOIN app.event_verifications v ON v.event_id=e.id WHERE e.duty_id=$1 AND e.sequence>$2 AND e.sequence<$3 AND v.status='rejected'",
            [d.id, d.last_sequence, e.sequence],
          )
        ).rows[0].n;
        if (
          d.status === "closed" ||
          e.sequence !== d.last_sequence + skipped + 1 ||
          !stateAfter([...prior.map((x) => x.kind), e.kind]) ||
          (prior.length &&
            epoch(p.effectiveAt) < epoch(prior.at(-1)!.effective_at))
        )
          fail("CONFLICT", "Resolve event order before acceptance");
        await c.query(
          "UPDATE app.duty_sessions SET last_sequence=$2,version=version+1,opened_at=CASE WHEN $3='IN' THEN $4::timestamptz ELSE opened_at END,status=CASE WHEN $3='OUT' THEN 'closed' ELSE status END,closed_at=CASE WHEN $3='OUT' THEN $4::timestamptz ELSE closed_at END WHERE id=$1",
          [d.id, e.sequence, e.kind, p.effectiveAt],
        );
      }
      const result = (
        await c.query(
          "UPDATE app.event_verifications SET status=$2,reason=$3,effective_at=$4,reviewer_id=app.actor_id(),reviewed_at=now() WHERE event_id=$1 RETURNING event_id id,status",
          [
            e.id,
            p.approve ? "accepted" : "rejected",
            p.reason,
            p.approve ? p.effectiveAt : null,
          ],
        )
      ).rows[0];
      if (p.approve) await this.updateVisit(c, e.kind, e.payload.visitId);
      await this.project(c, d.id);
      await this.notify(c, e.user_id, "attendance", e.id, "event.reviewed");
      return result;
    }
    const a = (
      await c.query(
        "SELECT * FROM app.attendance_adjustments WHERE id=$1 FOR UPDATE",
        [p.id],
      )
    ).rows[0];
    if (!a) fail("NOT_FOUND", "Request unavailable");
    await this.allowed(c, "attendance.approve", a.employee_id);
    if (a.requester_id === actor.id)
      fail("FORBIDDEN", "Self approval is prohibited");
    if (a.version !== p.expectedVersion || a.status !== "pending")
      fail("CONFLICT", "Request already reviewed");
    const adjustedDuty = (
      await c.query(
        "SELECT status FROM app.duty_sessions WHERE id=$1 FOR UPDATE",
        [a.duty_id],
      )
    ).rows[0];
    if (
      p.approve &&
      a.close_session &&
      !["open", "needs_review"].includes(adjustedDuty.status)
    )
      fail("CONFLICT", "Duty was already closed");
    if (
      p.approve &&
      a.close_session &&
      adjustedDuty.status === "needs_review"
    ) {
      const duty = (
        await c.query("SELECT * FROM app.duty_sessions WHERE id=$1", [
          a.duty_id,
        ])
      ).rows[0];
      if (!(await this.withinArchivedDuty(c, duty, a.ends_at)))
        fail("BAD_INPUT", "Missed-exit time exceeds the original duty window");
    }
    if (
      p.approve &&
      (
        await c.query(
          "SELECT id FROM app.attendance_adjustments WHERE duty_id=$1 AND ((kind='overtime')=($2='overtime')) AND status='approved' AND tstzrange(starts_at,ends_at)&&tstzrange($3,$4)",
          [
            a.duty_id,
            a.kind === "overtime" ? "overtime" : a.kind,
            a.starts_at,
            a.ends_at,
          ],
        )
      ).rowCount
    )
      fail("CONFLICT", "Approved adjustment intervals overlap");
    const r = (
      await c.query(
        "UPDATE app.attendance_adjustments SET status=$2,decision_note=$3,reviewer_id=app.actor_id(),reviewed_at=now(),version=version+1 WHERE id=$1 RETURNING id,status",
        [a.id, p.approve ? "approved" : "rejected", p.reason],
      )
    ).rows[0];
    await c.query(
      "UPDATE app.duty_sessions SET version=version+1,status=CASE WHEN $2 AND $3 THEN 'closed' ELSE status END,closed_at=CASE WHEN $2 AND $3 THEN $4 ELSE closed_at END WHERE id=$1",
      [a.duty_id, p.approve, a.close_session, a.ends_at],
    );
    await this.project(c, a.duty_id);
    await this.notify(
      c,
      a.requester_id,
      "attendance",
      a.id,
      "adjustment.reviewed",
    );
    return r;
  }
  async leave(c: Tx, actor: Actor, operation: string, p: any) {
    if (operation === "leaveType") {
      await this.allowed(c, "site_settings.manage");
      await this.validateApprover(c, p.approverId, "leave.approve");
      return (
        await c.query(
          "INSERT INTO app.leave_types(organization_id,site_id,code,label,half_days,include_weekends,include_holidays,approver_id) VALUES(app.org_id(),app.site_id(),$1,$2,$3,$4,$5,$6) RETURNING id",
          [
            p.code,
            p.label,
            p.halfDays,
            p.includeWeekends,
            p.includeHolidays,
            p.approverId,
          ],
        )
      ).rows[0];
    }
    if (operation === "leaveCredit") {
      await this.allowed(c, "leave.approve", p.employeeId);
      await this.allowed(c, "site_settings.manage");
      return (
        await c.query(
          "INSERT INTO app.leave_ledger(organization_id,site_id,employee_id,type_id,units,reason,author_id,effective_on) VALUES(app.org_id(),app.site_id(),$1,$2,$3,$4,app.actor_id(),$5) RETURNING id",
          [p.employeeId, p.typeId, p.units, p.reason, p.effectiveOn],
        )
      ).rows[0];
    }
    if (operation === "leave") {
      const me = await this.mine(c);
      await this.allowed(c, "my_leave.submit", me.id);
      await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
        `${actor.organizationId}:leave:${me.id}`,
      ]);
      const old = (
        await c.query(
          "SELECT *,starts_on::text start_date,ends_on::text end_date FROM app.leave_requests WHERE user_id=app.actor_id() AND client_id=$1",
          [p.clientId],
        )
      ).rows[0];
      if (old) {
        if (
          old.type_id !== p.typeId ||
          old.start_date !== p.startsOn ||
          old.end_date !== p.endsOn ||
          old.half !== p.half ||
          old.reason !== p.reason
        )
          fail("CONFLICT", "Request ID payload changed");
        return { id: old.id, status: old.status };
      }
      const type = (
        await c.query("SELECT * FROM app.leave_types WHERE id=$1 AND active", [
          p.typeId,
        ])
      ).rows[0];
      if (!type)
        fail("CONFIGURATION_REQUIRED", "Choose a configured active leave type");
      if (
        p.endsOn < p.startsOn ||
        epoch(p.endsOn) - epoch(p.startsOn) > 366 * 86400000
      )
        fail("BAD_INPUT", "Invalid leave interval");
      if (p.half !== "full" && (!type.half_days || p.startsOn !== p.endsOn))
        fail("BAD_INPUT", "Half-day leave is not configured for this range");
      const conflict = (
        await c.query(
          "SELECT id FROM app.leave_requests WHERE employee_id=$1 AND status<>'rejected' AND daterange(starts_on,ends_on,'[]')&&daterange($2,$3,'[]') AND (half='full' OR $4='full' OR half=$4)",
          [me.id, p.startsOn, p.endsOn, p.half],
        )
      ).rowCount;
      if (conflict)
        fail("CONFLICT", "Leave dates overlap a pending or approved request");
      const units =
        Number(
          (
            await c.query(
              "SELECT count(*)::int n FROM generate_series($1::date,$2::date,interval '1 day') d WHERE ($3 OR extract(isodow FROM d)<6) AND ($4 OR NOT EXISTS(SELECT 1 FROM app.site_reference_items WHERE kind='holiday' AND active AND details->>'date'=to_char(d,'YYYY-MM-DD')))",
              [
                p.startsOn,
                p.endsOn,
                type.include_weekends,
                type.include_holidays,
              ],
            )
          ).rows[0].n,
        ) * (p.half === "full" ? 1 : 0.5);
      if (!units)
        fail("BAD_INPUT", "The configured calendar gives zero leave days");
      const balance = Number(
        (
          await c.query(
            "SELECT COALESCE(sum(units),0)::text balance FROM app.leave_ledger WHERE employee_id=$1 AND type_id=$2 AND effective_on<=$3",
            [me.id, type.id, p.startsOn],
          )
        ).rows[0].balance,
      );
      if (balance < units)
        fail(
          "INSUFFICIENT_BALANCE",
          "Configured leave balance is insufficient",
        );
      const r = (
        await c.query(
          "INSERT INTO app.leave_requests(organization_id,site_id,employee_id,user_id,client_id,type_id,starts_on,ends_on,half,units,reason,approver_id) VALUES(app.org_id(),app.site_id(),$1,app.actor_id(),$2,$3,$4,$5,$6,$7,$8,$9) RETURNING id,status",
          [
            me.id,
            p.clientId,
            p.typeId,
            p.startsOn,
            p.endsOn,
            p.half,
            units,
            p.reason,
            type.approver_id,
          ],
        )
      ).rows[0];
      await this.notify(c, type.approver_id, "leave", r.id, "leave.requested");
      await this.notify(c, actor.id, "leave", r.id, "leave.pending");
      return r;
    }
    const request = (
      await c.query("SELECT * FROM app.leave_requests WHERE id=$1 FOR UPDATE", [
        p.id,
      ])
    ).rows[0];
    if (!request) fail("NOT_FOUND", "Leave request unavailable");
    await this.allowed(c, "leave.approve", request.employee_id);
    if (request.user_id === actor.id || request.approver_id !== actor.id)
      fail("FORBIDDEN", "Independent configured approver required");
    if (request.status !== "pending" || request.version !== p.expectedVersion)
      fail("CONFLICT", "Request already decided");
    await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
      `${actor.organizationId}:leave:${request.employee_id}`,
    ]);
    if (p.approve) {
      const balance = Number(
        (
          await c.query(
            "SELECT COALESCE(sum(units),0)::text balance FROM app.leave_ledger WHERE employee_id=$1 AND type_id=$2 AND effective_on<=$3",
            [request.employee_id, request.type_id, request.starts_on],
          )
        ).rows[0].balance,
      );
      if (balance < Number(request.units))
        fail("INSUFFICIENT_BALANCE", "Balance changed before approval");
      await c.query(
        "INSERT INTO app.leave_ledger(organization_id,site_id,employee_id,type_id,request_id,units,reason,author_id,effective_on) VALUES(app.org_id(),app.site_id(),$1,$2,$3,$4,$5,app.actor_id(),$6)",
        [
          request.employee_id,
          request.type_id,
          request.id,
          -Number(request.units),
          p.reason,
          request.starts_on,
        ],
      );
    }
    const r = (
      await c.query(
        "UPDATE app.leave_requests SET status=$2,decision_note=$3,reviewer_id=app.actor_id(),version=version+1 WHERE id=$1 RETURNING id,status",
        [request.id, p.approve ? "approved" : "rejected", p.reason],
      )
    ).rows[0];
    await this.notify(c, request.user_id, "leave", r.id, "leave.decided");
    return r;
  }
  async task(c: Tx, actor: Actor, operation: string, p: any) {
    if (operation === "task") {
      await this.allowed(c, "tasks.create", p.employeeId);
      const e = (
        await c.query("SELECT user_id FROM app.employees WHERE id=$1", [
          p.employeeId,
        ])
      ).rows[0];
      if (!e?.user_id) fail("NOT_FOUND", "Assignee unavailable");
      const old = (
        await c.query(
          "SELECT * FROM app.work_tasks WHERE author_id=app.actor_id() AND client_id=$1",
          [p.clientId],
        )
      ).rows[0];
      if (old) {
        if (
          old.title !== p.title ||
          old.employee_id !== p.employeeId ||
          old.description !== p.description ||
          old.priority !== p.priority ||
          epoch(old.deadline) !== epoch(p.deadline)
        )
          fail("CONFLICT", "Task ID payload changed");
        return { id: old.id };
      }
      const r = (
        await c.query(
          "INSERT INTO app.work_tasks(organization_id,site_id,employee_id,assignee_id,author_id,client_id,title,description,deadline,priority) VALUES(app.org_id(),app.site_id(),$1,$2,app.actor_id(),$3,$4,$5,$6,$7) RETURNING id,status",
          [
            p.employeeId,
            e.user_id,
            p.clientId,
            p.title,
            p.description,
            p.deadline,
            p.priority,
          ],
        )
      ).rows[0];
      await this.notify(c, e.user_id, "tasks", r.id, "task.assigned");
      return r;
    }
    const task = (
      await c.query("SELECT * FROM app.work_tasks WHERE id=$1 FOR UPDATE", [
        p.taskId ?? p.id,
      ])
    ).rows[0];
    if (!task) fail("NOT_FOUND", "Task unavailable");
    await this.allowed(c, "tasks.view", task.employee_id);
    if (operation === "taskStatus") {
      await this.allowed(
        c,
        task.assignee_id === actor.id ? "tasks.submit" : "tasks.edit",
        task.employee_id,
      );
      if (task.version !== p.expectedVersion)
        fail("CONFLICT", "Task changed; reload");
      const r = (
        await c.query(
          "UPDATE app.work_tasks SET status=$2,version=version+1 WHERE id=$1 RETURNING id,status,version",
          [task.id, p.status],
        )
      ).rows[0];
      await this.notify(
        c,
        task.author_id,
        "tasks",
        task.id,
        `task.updated.${p.status}`,
      );
      return r;
    }
    await this.allowed(
      c,
      task.assignee_id === actor.id ? "tasks.submit" : "tasks.edit",
      task.employee_id,
    );
    if (
      p.attachmentId &&
      !(
        await c.query(
          "SELECT id FROM app.private_files WHERE id=$1 AND parent_id=$2 AND owner_id=app.actor_id() AND status='ready'",
          [p.attachmentId, task.id],
        )
      ).rowCount
    )
      fail(
        "FILE_NOT_READY",
        "Attachment is not ready or belongs to another task",
      );
    const old = (
      await c.query(
        "SELECT id,body,attachment_id FROM app.task_comments WHERE author_id=app.actor_id() AND client_id=$1",
        [p.clientId],
      )
    ).rows[0];
    if (old) {
      if (old.body !== p.body || old.attachment_id !== (p.attachmentId ?? null))
        fail("CONFLICT", "Comment ID payload changed");
      return old;
    }
    const r = (
      await c.query(
        "INSERT INTO app.task_comments(organization_id,site_id,employee_id,task_id,author_id,client_id,body,attachment_id) VALUES(app.org_id(),app.site_id(),$1,$2,app.actor_id(),$3,$4,$5) RETURNING id",
        [task.employee_id, task.id, p.clientId, p.body, p.attachmentId ?? null],
      )
    ).rows[0];
    await this.notify(
      c,
      task.assignee_id === actor.id ? task.author_id : task.assignee_id,
      "tasks",
      task.id,
      `task.comment.${r.id}`,
    );
    return r;
  }
}
