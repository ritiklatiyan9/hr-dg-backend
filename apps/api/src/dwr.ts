import { createHash, randomUUID } from "node:crypto";
import { z } from "zod";
import { DwrChat, isChatOperation } from "./dwr-chat.js";
import {
  fail,
  workDate,
  type Actor,
} from "../../../packages/authz/src/index.js";
import type { Tx } from "../../../packages/db/src/index.js";
import { dwrContent, dwrSettings } from "../../../packages/contracts/dwr.js";
const base = { clientId: z.uuid(), expectedVersion: z.number().int().min(0) };
const reason = z.string().trim().min(8).max(1000);
const schemas = {
  save: z
    .object({
      ...base,
      workDate: z.iso.date(),
      content: dwrContent,
      attachments: z.array(z.uuid()).max(10),
      // Accepted from older app builds and ignored: voice drafts were removed.
      voiceId: z.uuid().nullable().optional(),
    })
    .strict(),
  submit: z
    .object({ ...base, id: z.uuid(), confirmed: z.literal(true) })
    .strict(),
  amend: z.object({ ...base, id: z.uuid(), reason }).strict(),
  review: z
    .object({
      ...base,
      id: z.uuid(),
      decision: z.enum(["approve", "return", "comment"]),
      reason,
    })
    .strict(),
  settings: dwrSettings,
  fileIntent: z
    .object({
      clientId: z.uuid(),
      id: z.uuid(),
      type: z.enum(["image/jpeg", "image/png", "application/pdf"]),
      bytes: z
        .number()
        .int()
        .min(1)
        .max(8 * 1024 * 1024),
    })
    .strict(),
};
export class Dwr extends DwrChat {
  async printDwr(actor: Actor, site: string, id: string) {
    return this.site(actor, site, async (c) => {
      const r = (
        await c.query(
          "SELECT *,work_date::text AS date FROM app.dwr_reports WHERE id=$1",
          [id],
        )
      ).rows[0];
      if (!r) fail("NOT_FOUND", "Report unavailable", 404);
      if (r.user_id !== actor.id)
        await this.allowed(c, "dwr_review.export", r.employee_id);
      else await this.allowed(c, "my_dwr.view", r.employee_id);
      const escape = (v: unknown) =>
        String(v).replace(
          /[&<>"']/g,
          (ch) =>
            ({
              "&": "&amp;",
              "<": "&lt;",
              ">": "&gt;",
              '"': "&quot;",
              "'": "&#39;",
            })[ch]!,
        );
      const s = (
        await c.query("SELECT name FROM app.sites WHERE id=app.site_id()")
      ).rows[0];
      const e = (
        await c.query("SELECT display_name FROM app.employees WHERE id=$1", [
          r.employee_id,
        ])
      ).rows[0];
      const sections = [
        "completed",
        "pending",
        "blockers",
        "nextDayPlan",
        "uncertainties",
      ]
        .map(
          (key) =>
            "<section><h2>" +
            escape(
              {
                completed: "Completed work",
                pending: "Pending work / reasons",
                blockers: "Issues / blockers",
                nextDayPlan: "Next-day plan",
                uncertainties: "Clarification needed",
              }[key as "completed"],
            ) +
            "</h2>" +
            (r.content[key].length
              ? "<ul>" +
                r.content[key]
                  .map((v: string) => "<li>" + escape(v) + "</li>")
                  .join("") +
                "</ul>"
              : "<p>" +
                (r.content.stated?.[key] === "none"
                  ? "Explicitly reported none"
                  : "Not stated") +
                "</p>") +
            "</section>",
        )
        .join("");
      return (
        '<!doctype html><html lang="en"><meta charset="utf-8"><title>Daily work report</title><style>@page{size:A4;margin:16mm}body{font:12pt/1.5 system-ui;color:#24352f;max-width:180mm;margin:20px auto}h1{font-size:24pt}h2{font-size:13pt;break-after:avoid}section{border-top:1px solid #b7c9bf;margin-top:12px}li{overflow-wrap:anywhere}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:inherit}footer{font-size:10pt}small{display:block}@media print{.screen{display:none}li{break-inside:avoid}}</style><p class="screen">Print using your browser. Longer reports continue onto additional pages; nothing is hidden or shrunk to fit.</p><h1>Daily work report</h1><p>' +
        escape(e?.display_name ?? "Employee") +
        " · " +
        escape(s.name) +
        " · " +
        escape(r.date) +
        "</p><p>Status: " +
        escape(r.status) +
        " · Revision " +
        r.revision +
        "</p><small>Employee-reported claims; approval acknowledges review and does not verify achievements or authorize payroll.</small>" +
        sections +
        (r.origin === "chat" && r.content.sourceTranscript
          ? "<section><h2>Chat messages</h2><pre>" +
            escape(r.content.sourceTranscript) +
            "</pre></section>"
          : "") +
        "<footer><p>Attachments: " +
        r.attachments.length +
        " (available through authorized application access)</p><p>Report " +
        escape(r.id) +
        " · version " +
        r.version +
        "</p></footer></html>"
      );
    });
  }
  async dwrSnapshot(actor: Actor, siteId: string, date?: string) {
    if (date) z.iso.date().parse(date);
    return this.site(actor, siteId, async (c) => {
      if (
        !(
          await c.query(
            "SELECT app.allowed('my_dwr.view') OR app.allowed('dwr_review.view') OR app.allowed('site_settings.manage') ok",
          )
        ).rows[0].ok
      )
        fail("FORBIDDEN", "DWR access is restricted", 403);
      const reports = (
        await c.query(
          "SELECT r.*,r.work_date::text AS work_date FROM app.dwr_reports r WHERE ($1::date IS NULL OR r.work_date=$1) ORDER BY r.work_date DESC,r.updated_at DESC LIMIT 100",
          [date ?? null],
        )
      ).rows;
      for (const r of reports) {
        r.isSelf = r.user_id === actor.id;
        r.actions = (
          await c.query(
            "SELECT key FROM app.permission_catalogue WHERE module_id IN ('my_dwr','dwr_review') AND app.allowed(key,$1)",
            [r.employee_id],
          )
        ).rows.map((v) => v.key);
        r.history = (
          await c.query(
            "SELECT version,revision,event,reason,actor_id,content,attachments,created_at FROM app.dwr_history WHERE report_id=$1 ORDER BY version DESC LIMIT 100",
            [r.id],
          )
        ).rows;
        const provenance =
          r.isSelf ||
          (
            await c.query(
              "SELECT app.allowed('dwr_review.field.provenance',$1) ok",
              [r.employee_id],
            )
          ).rows[0].ok;
        // A chat report's transcript is the author's own messages, which a
        // reviewer may read anyway; voice transcripts stay a delegated field.
        const source = provenance || r.origin === "chat";
        if (!source) {
          r.content = { ...r.content, sourceTranscript: "" };
          r.history = r.history.map((h: any) => ({
            ...h,
            content: { ...h.content, sourceTranscript: "" },
          }));
          r.voice_id = null;
        }
        r.provenanceVisible = source;
        r.provenance = provenance
          ? (await c.query("SELECT app.dwr_provenance($1) data", [r.id]))
              .rows[0].data
          : null;
        r.employeeName =
          (
            await c.query(
              "SELECT display_name FROM app.employees WHERE id=$1",
              [r.employee_id],
            )
          ).rows[0]?.display_name ?? "Employee";
      }
      const settings =
        (await c.query("SELECT *,deadline::text FROM app.dwr_settings"))
          .rows[0] ?? null;
      const site = (
        await c.query(
          "SELECT name,timezone FROM app.sites WHERE id=app.site_id()",
        )
      ).rows[0];
      return {
        reports,
        settings,
        site,
        workDate: workDate(new Date(), site.timezone),
        serverTime: new Date().toISOString(),
        agent: await this.agentStatus(c),
        inbox: (
          await c.query(
            "SELECT id,entity_id,event_type,created_at,read_at FROM app.inbox_items WHERE module IN ('my_dwr','dwr_review') ORDER BY created_at DESC LIMIT 50",
          )
        ).rows,
      };
    });
  }
  async dwrCommand(
    actor: Actor,
    siteId: string,
    operation: string,
    raw: unknown,
  ) {
    if (
      operation === "fileIntent" &&
      process.env.FILE_STORAGE_DISABLED === "true"
    )
      fail("STORAGE_UNAVAILABLE", "Private storage is not configured", 503);
    if (isChatOperation(operation))
      return this.chatCommand(actor, siteId, operation, raw);
    const schema = schemas[operation as keyof typeof schemas];
    if (!schema) fail("BAD_INPUT", "Unknown DWR operation");
    const p: any = schema.parse(raw);
    return this.site(actor, siteId, async (c) => {
      if (operation === "settings") {
        await this.allowed(c, "site_settings.manage");
        await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
          `${actor.organizationId}:${siteId}:dwr-settings`,
        ]);
        const old = (await c.query("SELECT version FROM app.dwr_settings"))
          .rows[0];
        if ((old?.version ?? 0) !== p.expectedVersion)
          fail("CONFLICT", "Settings changed", 409);
        await c.query(
          `INSERT INTO app.dwr_settings(organization_id,site_id,version,deadline,deadline_day_offset,reminder_minutes,amendments,offline_drafts,reason) VALUES(app.org_id(),app.site_id(),$1,$2,$3,$4,$5,$6,$7) ON CONFLICT(organization_id,site_id) DO UPDATE SET version=excluded.version,deadline=excluded.deadline,deadline_day_offset=excluded.deadline_day_offset,reminder_minutes=excluded.reminder_minutes,amendments=excluded.amendments,offline_drafts=excluded.offline_drafts,reason=excluded.reason`,
          [
            p.expectedVersion + 1,
            p.deadline,
            p.deadlineDayOffset,
            p.reminderMinutes,
            p.amendments,
            p.offlineDrafts,
            p.reason,
          ],
        );
        await this.auditOperation(c, "dwr.settings", siteId, [
          "deadline",
          "reminders",
          "amendments",
          "offlineDrafts",
        ]);
        return { version: p.expectedVersion + 1 };
      }
      await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
        `${actor.organizationId}:${actor.id}:dwr`,
      ]);
      let report: any;
      if (operation === "save") {
        const me = await this.mine(c);
        await this.validateDate(c, me.id, p.workDate);
        report = (
          await c.query(
            "SELECT * FROM app.dwr_reports WHERE employee_id=$1 AND work_date=$2 FOR UPDATE",
            [me.id, p.workDate],
          )
        ).rows[0];
        await this.allowed(c, report ? "my_dwr.edit" : "my_dwr.create", me.id);
      } else {
        report = (
          await c.query(
            "SELECT * FROM app.dwr_reports WHERE id=$1 FOR UPDATE",
            [p.id],
          )
        ).rows[0];
        if (!report) fail("NOT_FOUND", "Report unavailable", 404);
        if (operation === "review") {
          if (report.user_id === actor.id)
            fail("FORBIDDEN", "You cannot review your own report", 403);
          await this.allowed(
            c,
            p.decision === "approve"
              ? "dwr_review.approve"
              : "dwr_review.review",
            report.employee_id,
          );
        } else {
          if (report.user_id !== actor.id)
            fail(
              "FORBIDDEN",
              "Only the employee can edit or submit this report",
              403,
            );
          await this.allowed(
            c,
            operation === "submit" ? "my_dwr.submit" : "my_dwr.edit",
            report.employee_id,
          );
        }
      }
      const digest = createHash("sha256")
        .update(JSON.stringify({ operation, p, siteId }))
        .digest("hex");
      const receipt = (
        await c.query(
          "SELECT digest,result FROM app.dwr_receipts WHERE client_id=$1",
          [p.clientId],
        )
      ).rows[0];
      if (receipt) {
        if (receipt.digest !== digest)
          fail("CONFLICT", "Request ID used with different content", 409);
        return receipt.result;
      }
      if (operation === "fileIntent") {
        if (!["draft", "returned"].includes(report.status))
          fail("CONFLICT", "Open a draft before attaching files", 409);
        const file = (
          await c.query(
            `INSERT INTO app.private_files(organization_id,site_id,employee_id,owner_id,client_id,purpose,parent_id,declared_type,byte_limit,object_key) VALUES(app.org_id(),app.site_id(),$1,app.actor_id(),$2,'dwr',$3,$4,$5,$6) RETURNING id,status`,
            [
              report.employee_id,
              p.clientId,
              report.id,
              p.type,
              p.bytes,
              `${actor.organizationId}/${siteId}/dwr/${randomUUID()}`,
            ],
          )
        ).rows[0];
        await this.receipt(c, p.clientId, digest, file);
        return file;
      }
      if ((report?.version ?? 0) !== p.expectedVersion)
        fail(
          "CONFLICT",
          "This DWR changed. Reload and reconcile your draft.",
          409,
        );
      if (operation === "save") {
        if (report && !["draft", "returned"].includes(report.status))
          fail(
            "CONFLICT",
            "Submitted reports require return or an explicit amendment",
            409,
          );
        if (p.attachments.length && !report)
          fail("BAD_INPUT", "Save a draft before adding attachments");
        for (const id of p.attachments) {
          if (
            !(
              await c.query(
                "SELECT 1 FROM app.private_files WHERE id=$1 AND purpose='dwr' AND parent_id=$2 AND owner_id=app.actor_id() AND status='ready'",
                [id, report.id],
              )
            ).rowCount
          )
            fail(
              "FILE_NOT_READY",
              "Attachment is unavailable or quarantined",
              409,
            );
        }
        if (!report) {
          const me = await this.mine(c);
          report = (
            await c.query(
              `INSERT INTO app.dwr_reports(organization_id,site_id,employee_id,user_id,work_date,content) VALUES(app.org_id(),app.site_id(),$1,app.actor_id(),$2,$3) RETURNING *`,
              [me.id, p.workDate, p.content],
            )
          ).rows[0];
        } else
          report = (
            await c.query(
              `UPDATE app.dwr_reports SET content=$2,attachments=$3,status='draft',version=version+1,revision=revision+1,updated_at=now() WHERE id=$1 RETURNING *`,
              [report.id, p.content, p.attachments],
            )
          ).rows[0];
      } else if (operation === "submit") {
        if (!["draft", "returned"].includes(report.status))
          fail("CONFLICT", "Report is already submitted", 409);
        const content = dwrContent.parse(report.content);
        if (
          !content.completed.length &&
          !content.pending.length &&
          !content.blockers.length &&
          !content.nextDayPlan.length &&
          // A chat report may be sent as the author's own messages alone.
          !(report.origin === "chat" && content.sourceTranscript.trim())
        )
          fail("BAD_INPUT", "Add work information before submitting");
        report = (
          await c.query(
            "UPDATE app.dwr_reports SET status='submitted',submitted_at=now(),version=version+1,updated_at=now() WHERE id=$1 RETURNING *",
            [report.id],
          )
        ).rows[0];
        await c.query("SELECT app.dwr_notify_reviewers($1)", [report.id]);
      } else if (operation === "amend") {
        if (
          report.status !== "approved" ||
          !(await c.query("SELECT amendments FROM app.dwr_settings")).rows[0]
            ?.amendments
        )
          fail(
            "FORBIDDEN",
            "Approved amendments are not enabled at this site",
            403,
          );
        report = (
          await c.query(
            "UPDATE app.dwr_reports SET status='draft',version=version+1,revision=revision+1,updated_at=now() WHERE id=$1 RETURNING *",
            [report.id],
          )
        ).rows[0];
      } else if (operation === "review") {
        if (report.status !== "submitted")
          fail("CONFLICT", "Only submitted reports can be reviewed", 409);
        report = (
          await c.query(
            "UPDATE app.dwr_reports SET status=$2,approved_revision=CASE WHEN $2='approved' THEN revision ELSE approved_revision END,version=version+1,updated_at=now() WHERE id=$1 RETURNING *",
            [
              report.id,
              p.decision === "approve"
                ? "approved"
                : p.decision === "return"
                  ? "returned"
                  : "submitted",
            ],
          )
        ).rows[0];
        await this.notify(
          c,
          report.user_id,
          "my_dwr",
          report.id,
          `dwr.${p.decision}.v${report.version}`,
        );
      }
      await c.query(
        `INSERT INTO app.dwr_history(organization_id,site_id,report_id,version,revision,actor_id,event,reason,content,attachments) VALUES(app.org_id(),app.site_id(),$1,$2,$3,app.actor_id(),$4,$5,$6,$7)`,
        [
          report.id,
          report.version,
          report.revision,
          operation === "review" ? p.decision : operation,
          p.reason ?? "",
          report.content,
          report.attachments,
        ],
      );
      await this.auditOperation(c, `dwr.${operation}`, report.id, [
        "version",
        "revision",
      ]);
      const result = {
        id: report.id,
        version: report.version,
        revision: report.revision,
        status: report.status,
      };
      await this.receipt(c, p.clientId, digest, result);
      return result;
    });
  }
  async receipt(c: Tx, id: string, digest: string, result: unknown) {
    await c.query(
      "INSERT INTO app.dwr_receipts(organization_id,site_id,actor_id,client_id,digest,result) VALUES(app.org_id(),app.site_id(),app.actor_id(),$1,$2,$3)",
      [id, digest, result],
    );
  }
}
