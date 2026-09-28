import { readFile } from "node:fs/promises";
import { createSign } from "node:crypto";
import { z } from "zod";
/** Token rejected by FCM as unregistered/invalid; the device should retire. */
export class StaleToken extends Error {}
const HR: Record<string, string> = {
  expense: "Expense claim",
  asset: "Asset",
  helpdesk: "Helpdesk request",
  document: "Document",
  policy: "Policy",
  announcement: "Announcement",
  lifecycle: "Employment record",
};
/** Generic, content-free notification text. Lock screens are public: no
 * names, amounts, dates or record content — only what kind of thing changed.
 * The app re-authorizes and loads details after the user opens it. */
export function pushText(module: string, eventType: string) {
  const [a = "", b = "", c = ""] = eventType.split(".");
  const t = (title: string, body: string) => ({ title, body });
  if (a === "hr") {
    if (b === "document" && c === "expiry")
      return t("Document expiring", "One of your documents expires soon.");
    if (b === "grievance")
      return t("Confidential case update", "There is an update on a confidential case.");
    const kind = HR[b] ?? "HR record";
    if (c === "published" && (b === "announcement" || b === "policy"))
      return t(`New ${kind.toLowerCase()}`, `A new ${kind.toLowerCase()} was published.`);
    return t(`${kind} update`, `A ${kind.toLowerCase()} is now ${c.replace("_", " ") || "updated"}.`);
  }
  switch (`${a}.${b}`) {
    case "attendance.accepted":
      return t("Attendance recorded", "Your attendance was accepted.");
    case "attendance.review_required":
      return t("Attendance to review", "An attendance event is waiting for your review.");
    case "attendance.pending_verification":
    case "attendance.pending":
      return t("Attendance pending review", "Your attendance needs a review before it counts.");
    case "attendance.rejected":
      return t("Attendance not accepted", "Open attendance to see why.");
    case "event.reviewed":
      return t("Attendance reviewed", "A reviewer decided on your attendance.");
    case "adjustment.requested":
      return t("Correction to review", "An attendance correction is waiting for your review.");
    case "adjustment.reviewed":
      return t("Correction reviewed", "A decision was made on your attendance correction.");
    case "leave.requested":
      return t("Leave request", "A leave request is waiting for your decision.");
    case "leave.pending":
      return t("Leave request sent", "Your leave request is waiting for a decision.");
    case "leave.decided":
      return t("Leave decision", "A decision was made on your leave request.");
    case "task.assigned":
      return t("New task", "A new task was assigned to you.");
    case "task.updated":
      return t("Task updated", "A task you follow changed status.");
    case "task.comment":
      return t("New task comment", "Someone commented on a task.");
    case "visit.assigned":
      return t("Field visit scheduled", "A field visit was scheduled for you.");
    case "dwr.reminder":
      return t("Daily report reminder", "Submit today's daily work report.");
    case "dwr.prepared":
      return t("DWR draft ready", "Your daily report draft is ready to check and submit.");
    case "dwr.submitted":
      return module === "dwr_review"
        ? t("DWR to review", "A team member sent a daily report for review.")
        : t("DWR submitted", "Your daily report was submitted.");
    case "dwr.approve":
      return t("DWR approved", "Your daily report was approved.");
    case "dwr.return":
      return t("DWR returned", "Your daily report was returned for changes.");
    case "dwr.group":
      return t("Added to a DWR group", "Post your daily work in the group chat.");
    case "payroll.published":
      return t("Payslip published", "Your new payslip is available.");
    case "payroll.paid":
      return t("Salary payment recorded", "The payroll team recorded a salary payment.");
  }
  return t("Defence Garden HR", "You have a new update.");
}
/** Real FCM HTTP v1 adapter; absence of credentials is never simulated delivery. */
export class FcmAdapter {
  private access?: { token: string; until: number };
  get configured() {
    return Boolean(process.env.FCM_SERVICE_ACCOUNT_FILE);
  }
  async send(
    token: string,
    note: { title: string; body: string },
    data: Record<string, string>,
  ) {
    if (!this.configured) throw Error("FCM_UNCONFIGURED");
    const account = z
      .object({
        client_email: z.email(),
        private_key: z.string().min(100),
        project_id: z.string().regex(/^[a-z0-9-]+$/),
      })
      .parse(
        JSON.parse(
          await readFile(process.env.FCM_SERVICE_ACCOUNT_FILE!, "utf8"),
        ),
      );
    if (!this.access || this.access.until < Date.now()) {
      const now = Math.floor(Date.now() / 1000),
        encode = (v: unknown) =>
          Buffer.from(JSON.stringify(v)).toString("base64url");
      const unsigned = `${encode({ alg: "RS256", typ: "JWT" })}.${encode({ iss: account.client_email, scope: "https://www.googleapis.com/auth/firebase.messaging", aud: "https://oauth2.googleapis.com/token", iat: now, exp: now + 3600 })}`;
      const signature = createSign("RSA-SHA256")
        .update(unsigned)
        .sign(account.private_key, "base64url");
      const response = await fetch("https://oauth2.googleapis.com/token", {
        method: "POST",
        headers: { "content-type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
          assertion: `${unsigned}.${signature}`,
        }),
        signal: AbortSignal.timeout(10000),
      });
      if (!response.ok) throw Error("FCM_AUTH_FAILED");
      const body = z
        .object({ access_token: z.string(), expires_in: z.number() })
        .parse(await response.json());
      this.access = {
        token: body.access_token,
        until: Date.now() + Math.min(body.expires_in - 60, 3300) * 1000,
      };
    }
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: `Bearer ${this.access.token}`,
        },
        body: JSON.stringify({
          message: {
            token,
            notification: note,
            data,
            android: {
              priority: "high",
              notification: { tag: data.inboxId, sound: "default" },
            },
            apns: {
              headers: { "apns-push-type": "alert", "apns-priority": "10" },
              payload: { aps: { sound: "default" } },
            },
          },
        }),
        signal: AbortSignal.timeout(10000),
      },
    );
    if (response.ok) return;
    const detail = await response.text().catch(() => "");
    if (
      response.status === 404 ||
      /UNREGISTERED|registration-token-not-registered/.test(detail) ||
      (response.status === 400 && /INVALID_ARGUMENT/.test(detail) && /token/i.test(detail))
    )
      throw new StaleToken("FCM_STALE_TOKEN");
    throw Error("FCM_DELIVERY_FAILED");
  }
}
