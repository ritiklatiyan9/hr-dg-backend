import { randomUUID } from "node:crypto";
import { z } from "zod";
import { Payroll } from "./payroll.js";
import { fail, type Actor } from "../../../packages/authz/src/index.js";
import type { Tx } from "../../../packages/db/src/index.js";
import {
  hrKinds,
  hrModules,
  hrPayloads,
  type HrKind,
} from "../../../packages/contracts/hr.js";
const base = { clientId: z.uuid(), expectedVersion: z.number().int().min(0) };
const note = z.string().trim().min(8).max(2000);
const forms = {
  reminders: z
    .object({
      ...base,
      days: z.number().int().min(1).max(365).nullable(),
      note,
    })
    .strict(),
  save: z
    .object({
      ...base,
      id: z.uuid().optional(),
      kind: z.enum(hrKinds),
      employeeId: z.uuid().optional(),
      payload: z.unknown(),
      attachments: z.array(z.uuid()).max(10).default([]),
      audience: z.array(z.uuid()).max(100).default([]),
      note,
    })
    .strict(),
  action: z
    .object({
      ...base,
      id: z.uuid(),
      action: z.enum([
        "submit",
        "approve",
        "reject",
        "settle",
        "assign",
        "acknowledge",
        "return",
        "receive",
        "clear",
        "start",
        "resolve",
        "close",
        "publish",
        "comment",
      ]),
      employeeId: z.uuid().optional(),
      note,
    })
    .strict(),
  fileIntent: z
    .object({
      ...base,
      id: z.uuid(),
      type: z.enum(["image/jpeg", "image/png", "application/pdf"]),
      bytes: z
        .number()
        .int()
        .min(1)
        .max(8 * 1024 * 1024),
    })
    .strict(),
  handlers: z
    .object({ ...base, userIds: z.array(z.uuid()).max(10), note })
    .strict(),
};
export class Hr extends Payroll {
  async approvalQueue(actor: Actor, site: string) {
    return this.site(actor, site, async (c) => ({
      items: (await this.approvalRows(c)).slice(0, 100),
      limit: 100,
    }));
  }
  /** Pending decisions the actor may take, oldest first; each kind reads at most 100. */
  async approvalRows(c: Tx) {
    const hr = (
      await c.query(
        "SELECT id,kind,status,updated_at FROM app.hr_records WHERE status IN ('submitted','return_requested') AND user_id<>app.actor_id() AND created_by<>app.actor_id() AND (app.hr_visible(id,'approve') OR app.hr_visible(id,'review') OR app.hr_visible(id,'manage')) ORDER BY updated_at LIMIT 100",
      )
    ).rows;
    const payroll = (
      await c.query(
        "SELECT id,'payroll' kind,status,updated_at FROM app.payroll_results WHERE status IN ('validated','reviewed','approved') AND user_id<>app.actor_id() AND created_by<>app.actor_id() AND app.payroll_admin(CASE status WHEN 'validated' THEN 'payroll.review' WHEN 'reviewed' THEN 'payroll.approve' ELSE 'payroll.manage' END,employee_id) ORDER BY updated_at LIMIT 100",
      )
    ).rows;
    const leave = (
      await c.query(
        "SELECT id,'leave' kind,status,created_at updated_at FROM app.leave_requests WHERE status='pending' AND app.allowed('leave.approve',employee_id) LIMIT 100",
      )
    ).rows;
    const attendance = (
      await c.query(
        "SELECT id,'attendance' kind,status,created_at updated_at FROM app.attendance_adjustments WHERE status='pending' AND requester_id<>app.actor_id() AND app.allowed('attendance.approve',employee_id) LIMIT 100",
      )
    ).rows;
    const dwr = (
      await c.query(
        "SELECT id,'dwr' kind,status,updated_at FROM app.dwr_reports WHERE status='submitted' AND user_id<>app.actor_id() AND (app.allowed('dwr_review.review',employee_id) OR app.allowed('dwr_review.approve',employee_id)) LIMIT 100",
      )
    ).rows;
    return [...hr, ...payroll, ...leave, ...attendance, ...dwr].sort(
      (a, b) => Date.parse(a.updated_at) - Date.parse(b.updated_at),
    );
  }

  async hrAccess(c: Tx, r: any, action: string) {
    if (
      !(
        await c.query(
          "SELECT app.hr_row_access($1,$2,$3,$4,$5,$6,$7,$8,$9) ok",
          [
            r.kind,
            r.employee_id,
            r.user_id,
            r.created_by,
            r.status,
            r.handlers,
            r.audience,
            r.payload,
            action,
          ],
        )
      ).rows[0].ok
    )
      fail("FORBIDDEN", "This case action is not permitted", 403);
  }
  async hrSnapshot(actor: Actor, site: string, kind: HrKind) {
    z.enum(hrKinds).parse(kind);
    return this.site(actor, site, async (c) => {
      const mod = hrModules[kind];
      const cap =
        kind === "document" || kind === "policy"
          ? "my_documents.view"
          : kind === "lifecycle"
            ? "my_hr.view"
            : `${mod}.view`;
      if (
        !(
          await c.query("SELECT app.allowed($1) OR app.allowed($2) ok", [
            cap,
            `${mod}.view`,
          ])
        ).rows[0].ok
      )
        fail("FORBIDDEN", "Module unavailable", 403);
      const records = (
        await c.query(
          "SELECT * FROM app.hr_records WHERE kind=$1 ORDER BY updated_at DESC LIMIT 100",
          [kind],
        )
      ).rows;
      for (const r of records) {
        r.isSelf = r.user_id === actor.id;
        r.history = (
          await c.query(
            "SELECT version,event,note,actor_id,created_at FROM app.hr_history WHERE record_id=$1 ORDER BY version DESC LIMIT 100",
            [r.id],
          )
        ).rows;
        r.acknowledged = !!(
          await c.query(
            "SELECT 1 FROM app.hr_acknowledgments WHERE record_id=$1 AND user_id=app.actor_id()",
            [r.id],
          )
        ).rowCount;
        r.actions = [];
        for (const a of ["edit", "submit", "review", "approve", "manage"])
          if (
            (await c.query("SELECT app.hr_visible($1,$2) ok", [r.id, a]))
              .rows[0].ok
          )
            r.actions.push(a);
        r.files = (
          await c.query(
            "SELECT id,status,declared_type,scan_result FROM app.private_files WHERE parent_id=$1 AND purpose='hr' ORDER BY created_at",
            [r.id],
          )
        ).rows;
        delete r.handlers;
      }
      const own = (
        await c.query(
          "SELECT id,user_id,display_name FROM app.employees WHERE user_id=app.actor_id()",
        )
      ).rows[0];
      const employees = (
        await c.query(
          "SELECT id,user_id AS \"userId\",display_name AS name FROM app.employees WHERE app.allowed('employees.view',id) ORDER BY display_name LIMIT 100",
        )
      ).rows;
      return {
        records,
        employees,
        ownEmployeeId: own?.id,
        canCreate: (
          await c.query("SELECT app.allowed($1) OR app.allowed($2) ok", [
            `${mod}.create`,
            kind === "document" ? "my_documents.create" : `${mod}.create`,
          ])
        ).rows[0].ok,
        sites: (await c.query("SELECT id,name FROM app.sites ORDER BY name"))
          .rows,
        employments:
          kind === "lifecycle"
            ? (
                await c.query(
                  "SELECT er.id,er.employee_id,e.display_name AS name,l.name AS employer FROM app.employment_records er JOIN app.employees e ON e.id=er.employee_id JOIN app.legal_employers l ON l.id=er.legal_employer_id WHERE app.allowed('employees.field.employment',e.id) LIMIT 100",
                )
              ).rows
            : [],
        salaryStructures:
          kind === "lifecycle"
            ? (
                await c.query(
                  "SELECT id,employee_id,starts_on::text,ends_on::text FROM app.salary_structures LIMIT 100",
                )
              ).rows
            : [],
        handlerVersion:
          (await c.query("SELECT version FROM app.hr_handler_config")).rows[0]
            ?.version ?? 0,
        handlersConfigured: !!(
          await c.query("SELECT 1 FROM app.hr_case_handlers LIMIT 1")
        ).rowCount,
        settings: (
          await c.query("SELECT version,reminder_days FROM app.hr_settings")
        ).rows[0] ?? { version: 0, reminder_days: null },
        limit: 100,
      };
    });
  }
  async hrCommand(actor: Actor, site: string, op: string, raw: unknown) {
    if (op === "fileIntent" && process.env.FILE_STORAGE_DISABLED === "true")
      fail("STORAGE_UNAVAILABLE", "Private storage is not configured", 503);
    const schema = forms[op as keyof typeof forms];
    if (!schema) fail("BAD_INPUT", "Unknown HR operation");
    const p: any = schema.parse(raw);
    if (op === "save")
      p.payload = hrPayloads[p.kind as HrKind].parse(p.payload);
    return this.site(actor, site, async (c) => {
      let r: any;
      if (p.id) {
        r = (
          await c.query("SELECT * FROM app.hr_records WHERE id=$1 FOR UPDATE", [
            p.id,
          ])
        ).rows[0];
        if (!r) fail("NOT_FOUND", "Record unavailable", 404);
      }
      const permission =
        p.action === "comment" && r?.user_id !== actor.id
          ? "review"
          : op === "fileIntent"
            ? "edit"
            : op === "save"
              ? r
                ? "edit"
                : "create"
              : p.action === "approve" || p.action === "publish"
                ? "approve"
                : ["settle", "assign", "receive", "clear"].includes(p.action)
                  ? "manage"
                  : ["start", "resolve", "reject"].includes(p.action)
                    ? "review"
                    : "submit";
      if (op === "save" && !r) {
        const e = p.employeeId
          ? (
              await c.query(
                "SELECT id,user_id FROM app.employees WHERE id=$1",
                [p.employeeId],
              )
            ).rows[0]
          : await this.mine(c);
        if (!e?.user_id) fail("NOT_FOUND", "Employee unavailable");
        if (
          ["expense", "grievance", "helpdesk"].includes(p.kind) &&
          e.user_id !== actor.id
        )
          fail("FORBIDDEN", "Create your own request", 403);
        r = {
          id: randomUUID(),
          kind: p.kind,
          employee_id: e.id,
          user_id: e.user_id,
          created_by: actor.id,
          status: "draft",
          handlers: [],
          audience: p.audience,
          payload: p.payload,
          version: 0,
          attachments: [],
        };
      }
      return this.hrReceipt(
        c,
        actor,
        site,
        `hr.${op}`,
        p,
        async () => {
          if (op === "reminders") {
            await this.allowed(c, "documents.manage");
          } else if (op === "handlers") {
            await this.allowed(c, "grievances.manage");
            await this.allowed(c, "grievances.field.confidential");
          } else
            await this.hrAccess(
              c,
              r,
              permission === "manage" && r.kind === "expense"
                ? "approve"
                : permission,
            );
        },
        async () => {
          if (op === "reminders") {
            await c.query(
              "SELECT pg_advisory_xact_lock(hashtextextended($1,0))",
              [`${actor.organizationId}:${site}:hr-settings`],
            );
            const old = (await c.query("SELECT version FROM app.hr_settings"))
              .rows[0];
            if ((old?.version ?? 0) !== p.expectedVersion)
              fail("CONFLICT", "Settings changed", 409);
            await c.query(
              "INSERT INTO app.hr_settings VALUES(app.org_id(),app.site_id(),$1,$2,$3) ON CONFLICT(organization_id,site_id) DO UPDATE SET version=excluded.version,reminder_days=excluded.reminder_days,reason=excluded.reason",
              [p.expectedVersion + 1, p.days, p.note],
            );
            await this.auditOperation(c, "document.reminders", site, [
              "reminderDays",
            ]);
            return {
              id: site,
              version: p.expectedVersion + 1,
              status: "configured",
            };
          }
          if (op === "handlers") {
            await c.query(
              "SELECT pg_advisory_xact_lock(hashtextextended($1,0))",
              [`${actor.organizationId}:${site}:handlers`],
            );
            const old = (
              await c.query("SELECT version FROM app.hr_handler_config")
            ).rows[0];
            if ((old?.version ?? 0) !== p.expectedVersion)
              fail("CONFLICT", "Case handlers changed; reload", 409);
            for (const user of p.userIds)
              if (
                !(await c.query("SELECT app.hr_handler_allowed($1) ok", [user]))
                  .rows[0].ok
              )
                fail(
                  "BAD_INPUT",
                  "Handler requires site case-review and confidential-field permissions",
                );
            await c.query(
              "INSERT INTO app.hr_handler_config VALUES(app.org_id(),app.site_id(),$1) ON CONFLICT(organization_id,site_id) DO UPDATE SET version=excluded.version",
              [p.expectedVersion + 1],
            );
            await c.query("DELETE FROM app.hr_case_handlers");
            for (const user of p.userIds)
              await c.query(
                "INSERT INTO app.hr_case_handlers VALUES(app.org_id(),app.site_id(),$1)",
                [user],
              );
            await this.auditOperation(c, "grievance.handlers", site, [
              "handlers",
            ]);
            return {
              id: site,
              status: "configured",
              version: p.expectedVersion + 1,
            };
          }
          if (r.version !== p.expectedVersion)
            fail("CONFLICT", "Record changed. Reload before continuing", 409);
          if (op === "fileIntent") {
            if (!["draft"].includes(r.status))
              fail("CONFLICT", "Attachments require an editable draft");
            const f = (
              await c.query(
                "INSERT INTO app.private_files(organization_id,site_id,employee_id,owner_id,client_id,purpose,parent_id,declared_type,byte_limit,object_key) VALUES(app.org_id(),app.site_id(),$1,app.actor_id(),$2,'hr',$3,$4,$5,$6) RETURNING id,status",
                [
                  r.employee_id,
                  p.clientId,
                  r.id,
                  p.type,
                  p.bytes,
                  `${actor.organizationId}/${site}/hr/${randomUUID()}`,
                ],
              )
            ).rows[0];
            return f;
          }
          if (op === "save") {
            if (r.version && r.status !== "draft")
              fail("CONFLICT", "Accepted decisions cannot be edited");
            if (
              r.kind !== p.kind ||
              (p.employeeId && r.employee_id !== p.employeeId)
            )
              fail("CONFLICT", "Record identity is fixed");
            if (r.kind === "expense" && BigInt(p.payload.amountPaise) === 0n)
              fail("BAD_INPUT", "Expense must be positive");
            if (r.kind === "lifecycle") {
              const e = await this.payEmployment(c, p.payload.employmentId);
              if (e.employee_id !== r.employee_id)
                fail("BAD_INPUT", "Employment does not match employee");
              if (p.payload.event === "salary_revision") {
                await this.payrollAccess(c, "payroll.manage", e.employee_id);
                const st = (
                  await c.query(
                    "SELECT id FROM app.salary_structures WHERE id=$1 AND employment_id=$2 AND starts_on=$3",
                    [p.payload.salaryStructureId, e.id, p.payload.effectiveOn],
                  )
                ).rows[0];
                if (!st)
                  fail(
                    "BAD_INPUT",
                    "Salary revision needs a matching effective salary structure",
                  );
              }
            }
            if (["announcement", "policy"].includes(r.kind)) {
              if (!p.audience.length)
                fail("BAD_INPUT", "Choose an explicit audience");
              for (const u of p.audience)
                if (
                  !(
                    await c.query(
                      "SELECT 1 FROM app.employees WHERE user_id=$1",
                      [u],
                    )
                  ).rowCount
                )
                  fail("FORBIDDEN", "Audience member unavailable", 403);
            } else if (p.audience.length)
              fail("BAD_INPUT", "This record has no broadcast audience");
            for (const f of p.attachments) await this.hrAttachment(c, r.id, f);
            if (!r.version && r.kind === "grievance") {
              r.handlers = (
                await c.query(
                  "SELECT user_id FROM app.hr_case_handlers WHERE user_id<>app.actor_id()",
                )
              ).rows.map((x) => x.user_id);
              if (!r.handlers.length)
                fail(
                  "CONFIGURATION_REQUIRED",
                  "An authorized confidential case handler must be configured first",
                  409,
                );
            }
            if (!r.version)
              r = (
                await c.query(
                  "INSERT INTO app.hr_records(id,organization_id,site_id,kind,employee_id,user_id,created_by,payload,handlers,audience) VALUES($1,app.org_id(),app.site_id(),$2,$3,$4,app.actor_id(),$5,$6,$7) RETURNING *",
                  [
                    r.id,
                    r.kind,
                    r.employee_id,
                    r.user_id,
                    p.payload,
                    r.handlers,
                    p.audience,
                  ],
                )
              ).rows[0];
            else
              r = (
                await c.query(
                  "UPDATE app.hr_records SET payload=$2,attachments=$3,audience=$4,version=version+1,updated_at=now() WHERE id=$1 RETURNING *",
                  [r.id, p.payload, p.attachments, p.audience],
                )
              ).rows[0];
          } else {
            const own = r.user_id === actor.id,
              a = p.action;
            if (
              ["approve", "reject", "settle", "publish"].includes(a) &&
              (own || r.created_by === actor.id)
            )
              fail(
                "FORBIDDEN",
                "An independent reviewer must make this decision",
                403,
              );
            let next: string | undefined;
            const map: Record<string, Record<string, string>> = {
              expense: {
                "draft:submit": "submitted",
                "submitted:approve": "approved",
                "submitted:reject": "rejected",
                "approved:settle": "settled",
              },
              asset: {
                "draft:submit": "available",
                "available:assign": "assigned",
                "returned:assign": "assigned",
                "assigned:acknowledge": "acknowledged",
                "acknowledged:return": "return_requested",
                "assigned:return": "return_requested",
                "return_requested:receive": "returned",
                "returned:clear": "cleared",
              },
              helpdesk: {
                "draft:submit": "submitted",
                "submitted:start": "in_progress",
                "in_progress:resolve": "resolved",
                "submitted:resolve": "resolved",
                "resolved:close": "closed",
              },
              grievance: {
                "draft:submit": "submitted",
                "submitted:start": "in_progress",
                "in_progress:resolve": "resolved",
                "resolved:close": "closed",
              },
              document: {
                "draft:submit": "submitted",
                "submitted:approve": "approved",
                "submitted:reject": "rejected",
              },
              policy: {
                "draft:submit": "submitted",
                "submitted:publish": "published",
              },
              announcement: {
                "draft:submit": "submitted",
                "submitted:publish": "published",
              },
              lifecycle: {
                "draft:submit": "submitted",
                "submitted:approve": "approved",
                "submitted:reject": "rejected",
              },
            };
            if (
              a === "acknowledge" &&
              ["policy", "announcement"].includes(r.kind)
            ) {
              if (r.status !== "published" || !r.audience.includes(actor.id))
                fail("FORBIDDEN", "Not in this published audience", 403);
              await c.query(
                "INSERT INTO app.hr_acknowledgments VALUES(app.org_id(),app.site_id(),$1,app.actor_id(),now()) ON CONFLICT DO NOTHING",
                [r.id],
              );
              return { id: r.id, status: r.status, version: r.version };
            }
            if (a === "comment") {
              if (
                ["closed", "settled", "cleared", "rejected"].includes(r.status)
              )
                fail("CONFLICT", "Record is closed");
              next = r.status;
            } else next = map[r.kind]?.[`${r.status}:${a}`];
            if (!next) fail("CONFLICT", "This transition is unavailable", 409);
            if (["acknowledge", "return", "close"].includes(a) && !own)
              fail(
                "FORBIDDEN",
                "Only the employee can confirm this action",
                403,
              );
            if (a === "submit") {
              for (const f of r.attachments)
                await this.hrAttachment(c, r.id, f);
              if (
                ["expense", "document"].includes(r.kind) &&
                !r.attachments.length
              )
                fail(
                  "BAD_INPUT",
                  "Attach a ready receipt or document before submission",
                );
            }
            if (a === "assign") {
              if (!p.employeeId) fail("BAD_INPUT", "Choose the employee");
              const e = (
                await c.query(
                  "SELECT id,user_id FROM app.employees WHERE id=$1",
                  [p.employeeId],
                )
              ).rows[0];
              if (!e?.user_id) fail("NOT_FOUND", "Employee unavailable");
              await this.allowed(c, "assets.manage", e.id);
              r.employee_id = e.id;
              r.user_id = e.user_id;
            }
            if (r.kind === "lifecycle" && a === "approve")
              await c.query("SELECT app.apply_hr_lifecycle($1)", [r.id]);
            r = (
              await c.query(
                "UPDATE app.hr_records SET status=$2,employee_id=$3,user_id=$4,version=version+1,updated_at=now() WHERE id=$1 RETURNING *",
                [r.id, next, r.employee_id, r.user_id],
              )
            ).rows[0];
          }
          await c.query(
            "INSERT INTO app.hr_history(organization_id,site_id,record_id,version,actor_id,event,note,payload) VALUES(app.org_id(),app.site_id(),$1,$2,app.actor_id(),$3,$4,$5)",
            [
              r.id,
              r.version,
              op === "save" ? "save" : p.action,
              p.note,
              {
                content: r.payload,
                status: r.status,
                attachments: r.attachments,
                employeeId: r.employee_id,
              },
            ],
          );
          await this.auditOperation(
            c,
            `hr.${r.kind}.${op === "save" ? "save" : p.action}`,
            r.id,
            ["status", "version"],
          );
          await c.query("SELECT app.hr_notify($1)", [r.id]);
          return { id: r.id, status: r.status, version: r.version };
        },
      );
    });
  }
  async hrAttachment(c: Tx, parent: string, id: string) {
    if (
      !(
        await c.query(
          "SELECT 1 FROM app.private_files WHERE id=$1 AND parent_id=$2 AND purpose='hr' AND status='ready'",
          [id, parent],
        )
      ).rowCount
    )
      fail("BAD_INPUT", "Attachment is not ready or belongs to another record");
  }
}
