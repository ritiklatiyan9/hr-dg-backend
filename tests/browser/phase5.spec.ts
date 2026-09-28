import { test, expect, type Page } from "./fixtures.js";
import sharp from "sharp";
import { mkdir } from "node:fs/promises";
import { pool } from "../../packages/db/src/index.js";
import { decrypt, totp } from "../../apps/api/src/security.js";
import { ids } from "../../packages/db/src/seed.js";
async function signIn(page: Page, email: string, userId: string) {
  await page.goto("/");
  await page.getByLabel("Email ID").fill(email);
  await page
    .getByLabel("Password", { exact: true })
    .fill(process.env.SEED_PASSWORD!);
  await page.getByRole("button", { name: "Sign in", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Two-step verification" }),
  ).toBeVisible();
  let secret: string;
  const setup = page.getByRole("button", { name: "Set up authenticator" });
  if (await setup.isVisible()) {
    await setup.click();
    secret = await page.locator(".secret").innerText();
  } else {
    const p = pool(process.env.MIGRATION_DATABASE_URL!, 1);
    try {
      const row = (
        await p.query("SELECT mfa_secret FROM auth.users WHERE id=$1", [userId])
      ).rows[0];
      secret = decrypt(row.mfa_secret, process.env.ENCRYPTION_KEY!);
      await p.query("UPDATE auth.users SET last_totp_step=-1 WHERE id=$1", [
        userId,
      ]);
    } finally {
      await p.end();
    }
  }
  await page.getByLabel("Six-digit code").fill(totp(secret).generate());
  await page.getByRole("button", { name: "Verify and continue" }).click();
  await page
    .getByRole("button", { name: /Defence Garden.*Open workspace/ })
    .click();
}

test("payroll preparation → independent review → publication → employee payslip and HR helpdesk", async ({
  page,
  browser,
}) => {
  test.setTimeout(180000);
  page.setDefaultTimeout(15000);
  if (new URL(process.env.MIGRATION_DATABASE_URL!).pathname != "/hr_local")
    throw Error("Synthetic localhost database required");
  const db = pool(process.env.MIGRATION_DATABASE_URL!, 1);
  let employment: string, start: string, finish: string;
  try {
    employment = (
      await db.query(
        "SELECT id FROM app.employment_records WHERE employee_id=$1",
        [ids.employeeProfile],
      )
    ).rows[0].id;
    const period = (
      await db.query(
        "SELECT d::date::text start,(d+interval '1 month'-interval '1 day')::date::text finish FROM (SELECT date_trunc('month',current_date)-i*interval '1 month' d FROM generate_series(0,18) i) dates WHERE NOT EXISTS(SELECT 1 FROM app.payroll_results WHERE employment_id=$1 AND period_start=d::date) ORDER BY d DESC LIMIT 1",
        [employment],
      )
    ).rows[0];
    start = period.start;
    finish = period.finish;
  } finally {
    await db.end();
  }
  await mkdir("docs/evidence/phase5", { recursive: true });
  await page.setViewportSize({ width: 1440, height: 1050 });
  await signIn(page, "superadmin@example.test", ids.superAdmin);
  await page.getByRole("link", { name: "Payroll", exact: true }).click();
  await page.getByRole("button", { name: "Prepare payroll" }).click();
  let dialog = page.getByRole("dialog");
  await dialog
    .getByLabel("Employment / legal employer")
    .selectOption(employment);
  await dialog.getByLabel("Start", { exact: true }).fill(start!);
  await dialog.getByLabel("End", { exact: true }).fill(finish!);
  for (const [label, value] of [
    ["Component code", "BASE"],
    ["Component name", "Base salary"],
    ["Base amount (₹)", "30000"],
  ])
    await dialog.getByLabel(label!, { exact: true }).fill(value!);
  await dialog
    .getByLabel("Accountant-approved policy version")
    .fill("SYNTHETIC-BROWSER-ONLY");
  await dialog
    .getByLabel("Rules, rounding assumptions and exclusions")
    .fill("Synthetic test inputs, no company or statutory deduction rules.");
  await dialog
    .getByLabel("Attendance inputs / gaps / approved overtime reference")
    .fill("Synthetic fully paid month; no GPS-derived deductions.");
  await dialog
    .getByLabel("Change reason")
    .fill("Synthetic browser payroll flow verification");
  await dialog.getByRole("checkbox").check();
  await expect(
    dialog.getByText("Net ₹30,000.00", { exact: false }),
  ).toBeVisible();
  await page.screenshot({
    path: "docs/evidence/phase5/web-payroll-editor.png",
    fullPage: true,
  });
  await dialog.getByRole("button", { name: "Save draft", exact: true }).click();
  await expect(dialog).toHaveCount(0);
  const openResult = async (p: Page) => {
    await p.getByRole("link", { name: "Payroll", exact: true }).click();
    await p.getByLabel("Pay month").fill(start!.slice(0, 7));
    await p
      .getByRole("row")
      .filter({ hasText: start! })
      .getByRole("button", { name: /^(Open|Open record)$/ })
      .click();
  };
  const labels: Record<string, string> = {
    validate: "Send for approval",
    review: "Mark reviewed",
    approve: "Approve",
    publish: "Publish payslip",
  };
  const stage = async (p: Page, op: string) => {
    await p
      .getByRole("dialog")
      .getByRole("button", { name: labels[op], exact: true })
      .click();
    const d = p.getByRole("dialog").last();
    await d
      .getByLabel("Reason", { exact: true })
      .fill(`Synthetic independent ${op} verified`);
    await d.getByRole("button", { name: labels[op], exact: true }).click();
    await expect(p.getByRole("dialog")).toHaveCount(0);
  };
  await openResult(page);
  await stage(page, "validate");
  const hrCtx = await browser.newContext({
      viewport: { width: 1440, height: 1050 },
    }),
    hr = await hrCtx.newPage();
  await signIn(hr, "hr@example.test", ids.admin);
  await openResult(hr);
  await stage(hr, "review");
  const adminCtx = await browser.newContext({
      viewport: { width: 1440, height: 1050 },
    }),
    admin = await adminCtx.newPage();
  await signIn(admin, "admin@example.test", ids.siteAdmin);
  await openResult(admin);
  await stage(admin, "approve");
  await openResult(admin);
  await stage(admin, "publish");
  await openResult(admin);
  await admin
    .getByRole("dialog")
    .getByRole("button", { name: "Record payment" })
    .click();
  const payment = admin.getByRole("dialog").last();
  await expect(payment.getByLabel(/^Amount/)).toHaveValue("30000.00");
  await payment
    .getByLabel("Reference (UTR, cheque or voucher number)")
    .fill(`UTR${Date.now()}`);
  await payment
    .getByLabel("Note", { exact: true })
    .fill("Synthetic salary transfer recorded after bank confirmation");
  await payment
    .getByRole("button", { name: "Record payment", exact: true })
    .click();
  await expect(admin.getByRole("dialog")).toHaveCount(0);
  await expect(
    admin
      .getByRole("row")
      .filter({ hasText: start! })
      .getByText("Paid", { exact: true }),
  ).toBeVisible();
  await admin.screenshot({
    path: "docs/evidence/phase5/web-payroll-list.png",
    fullPage: true,
  });
  await openResult(admin);
  await expect(
    admin.getByRole("dialog").getByText("Payment recorded · ₹30,000.00"),
  ).toBeVisible();
  await admin.screenshot({
    path: "docs/evidence/phase5/web-payroll-history.png",
    fullPage: true,
  });
  const subject = `Synthetic employee HR question ${Date.now()}`;
  const employeeCtx = await browser.newContext({
      viewport: { width: 1150, height: 1000 },
    }),
    employee = await employeeCtx.newPage();
  await employee.goto("/");
  await employee.getByLabel("Email ID").fill("employee@example.test");
  await employee
    .getByLabel("Password", { exact: true })
    .fill(process.env.SEED_PASSWORD!);
  await employee.getByRole("button", { name: "Sign in", exact: true }).click();
  await employee
    .getByRole("button", { name: /Defence Garden.*Open workspace/ })
    .click();
  await openResult(employee);
  await expect(
    employee.getByText("Net ₹30,000.00", { exact: true }),
  ).toBeVisible();
  const [print] = await Promise.all([
    employee.waitForEvent("popup"),
    employee.getByRole("link", { name: "Print / PDF" }).click(),
  ]);
  await print.waitForLoadState();
  await expect(
    print.getByRole("heading", { name: "Payslip", exact: true }),
  ).toBeVisible();
  await expect(print.getByText("Payments recorded")).toBeVisible();
  await print.screenshot({
    path: "docs/evidence/phase5/web-payslip.png",
    fullPage: true,
  });
  await print.close();
  await employee
    .getByRole("button", { name: "Close dialog", exact: true })
    .click();
  await employee.getByRole("link", { name: "Helpdesk", exact: true }).click();

  await employee.getByRole("button", { name: "New record" }).click();
  dialog = employee.getByRole("dialog");
  await dialog.getByLabel("Subject", { exact: true }).fill(subject);
  await dialog
    .getByLabel("Category", { exact: true })
    .fill("Policy clarification");
  await dialog
    .getByLabel("How can HR help?")
    .fill("Please clarify the synthetic workflow demonstration.");
  await dialog
    .getByLabel("Change reason")
    .fill("Synthetic browser employee request");
  await dialog.getByRole("button", { name: "Save server draft" }).click();
  await expect(dialog).toHaveCount(0);
  await employee
    .getByRole("row")
    .filter({ hasText: subject })
    .last()
    .getByRole("button", { name: /^(Open|Open record)$/ })
    .click();
  await employee.getByRole("button", { name: "submit", exact: true }).click();
  await employee
    .getByLabel("Reason / comment")
    .fill("Submit synthetic question for HR follow-up");
  await employee.getByRole("button", { name: "Confirm", exact: true }).click();
  await expect(
    employee
      .getByRole("dialog")
      .getByText(/^submitted$/i)
      .first(),
  ).toBeVisible();
  await employee.screenshot({
    path: "docs/evidence/phase5/web-helpdesk.png",
    fullPage: true,
  });
  await employee.setViewportSize({ width: 390, height: 844 });
  await employee.screenshot({
    path: "docs/evidence/phase5/web-narrow.png",
    fullPage: true,
  });
  await employeeCtx.close();
  await hrCtx.close();
  await adminCtx.close();
});
