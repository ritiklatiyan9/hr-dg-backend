import { test, expect, type Page } from "./fixtures.js";
import { mkdir } from "node:fs/promises";
import { pool } from "../../packages/db/src/index.js";
import { decrypt, totp } from "../../apps/api/src/security.js";
import { ids } from "../../packages/db/src/seed.js";
// Synthetic databases only: the shared local database or a disposable test database.
const database = process.env.MIGRATION_DATABASE_URL!;
function synthetic() {
  if (!/^\/hr_(local|test_[a-z0-9]+)$/.test(new URL(database).pathname))
    throw Error("Synthetic local browser database required");
}
async function signIn(page: Page, email: string, userId: string, mfa = true) {
  await page.goto("/");
  await page.getByLabel("Email ID").fill(email);
  await page
    .getByLabel("Password", { exact: true })
    .fill(process.env.SEED_PASSWORD!);
  await page.getByRole("button", { name: "Sign in", exact: true }).click();
  if (mfa) {
    await expect(
      page.getByRole("heading", { name: "Two-step verification" }),
    ).toBeVisible();
    let secret: string;
    const setup = page.getByRole("button", { name: "Set up authenticator" });
    if (await setup.isVisible()) {
      await setup.click();
      secret = await page.locator(".secret").innerText();
    } else {
      const p = pool(database, 1);
      try {
        const row = (
          await p.query("SELECT mfa_secret FROM auth.users WHERE id=$1", [
            userId,
          ])
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
  }
  await page
    .getByRole("button", { name: /Defence Garden.*Open workspace/ })
    .click();
}

test("DWR chat → employee submits the day from chat → independent review, printable sources and scoped navigation", async ({
  page,
  browser,
}) => {
  test.setTimeout(150000);
  synthetic();
  // Today's synthetic day must be open: a previous run may have submitted it.
  const db = pool(database, 1);
  try {
    await db.query(
      `WITH day AS (SELECT id FROM app.dwr_reports WHERE employee_id=$1 AND site_id=$2 AND work_date=(now() AT TIME ZONE 'Asia/Kolkata')::date)
       DELETE FROM app.dwr_history WHERE report_id IN (SELECT id FROM day)`,
      [ids.employeeProfile, ids.dg],
    );
    await db.query(
      "DELETE FROM app.dwr_reports WHERE employee_id=$1 AND site_id=$2 AND work_date=(now() AT TIME ZONE 'Asia/Kolkata')::date",
      [ids.employeeProfile, ids.dg],
    );
  } finally {
    await db.end();
  }
  await mkdir("docs/evidence/dwr-chat", { recursive: true });
  await page.setViewportSize({ width: 1440, height: 1000 });
  await signIn(page, "superadmin@example.test", ids.superAdmin);
  await page
    .getByRole("link", { name: "Daily work reports", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "Daily work reports" }),
  ).toBeVisible();
  await page.getByRole("tab", { name: "Settings" }).click();
  await page.getByLabel("Deadline (site time)").fill("18:00");
  await page.getByLabel("Allow reasoned amendments after approval").check();
  await page
    .getByLabel("Reason for change")
    .fill("Synthetic DWR chat browser verification policy");
  await page.getByRole("button", { name: "Save settings" }).click();
  await expect(page.getByText("Settings saved")).toBeVisible();
  // WhatsApp-style group: the first person added becomes its admin.
  // Unique per run: synthetic databases keep earlier runs' chats.
  const run = Date.now().toString(36);
  const groupName = `E2E site team ${run}`;
  await page.getByRole("button", { name: "New group" }).first().click();
  const create = page.getByRole("dialog", { name: "New DWR group" });
  await create.getByLabel("Group name").fill(groupName);
  await create.getByPlaceholder("Search people at this site").fill("Arj");
  await create.getByRole("option", { name: /Arjun Mehta/ }).click();
  await create.getByPlaceholder("Search people at this site").fill("Adi");
  await create.getByRole("option", { name: /Aditi Sharma/ }).click();
  await create.getByRole("button", { name: "Create group" }).click();
  await expect(page.getByRole("heading", { name: "Group info" })).toBeVisible();
  await expect(page.getByText("Group admin", { exact: true })).toHaveCount(1);
  await page.keyboard.press("Escape");

  const employeeContext = await browser.newContext({
    viewport: { width: 1280, height: 900 },
  });
  const employee = await employeeContext.newPage();
  await signIn(employee, "employee@example.test", ids.employee, false);
  await employee.goto("/#/dwr");
  await expect(
    employee.getByRole("heading", { name: "My DWR Agent" }),
  ).toBeVisible();
  const composer = employee.getByLabel("Message", { exact: true });
  for (const body of [
    `Aaj pump house ka inspection kiya ${run}`,
    `Vendor se bearings ka quotation liya ${run}`,
  ]) {
    await composer.fill(body);
    await composer.press("Enter");
    await expect(employee.getByText(body)).toBeVisible();
  }
  // Actions appear only once the server confirms the message.
  const bubble = employee.locator("div.group", {
    hasText: `Vendor se bearings ka quotation liya ${run}`,
  });
  await bubble.hover();
  await bubble.getByRole("button", { name: "Message actions" }).click();
  await employee.getByRole("menuitem", { name: "Edit" }).click();
  await employee
    .getByLabel("Edit message")
    .fill(`Vendor se 2 bearings ka quotation liya ${run}`);
  await employee.getByRole("button", { name: "Save", exact: true }).click();
  await expect(
    employee.getByText(`Vendor se 2 bearings ka quotation liya ${run}`),
  ).toBeVisible();
  await employee.getByRole("listitem").filter({ hasText: groupName }).click();
  await composer.fill(`Pipeline section B ka pressure test pending hai ${run}`);
  await composer.press("Enter");
  await expect(
    employee.getByText(
      `Pipeline section B ka pressure test pending hai ${run}`,
    ),
  ).toBeVisible();
  await employee
    .getByRole("listitem")
    .filter({ hasText: "My DWR Agent" })
    .click();
  await employee.getByRole("button", { name: "Use chat as report" }).click();
  const report = employee.getByRole("dialog").filter({ hasText: "My DWR" });
  await expect(report.getByText("Chat messages for this day")).toBeVisible();
  await expect(
    report.getByText(`Pipeline section B ka pressure test pending hai ${run}`),
  ).toBeVisible();
  await employee.screenshot({
    path: "docs/evidence/dwr-chat/browser-employee-report.png",
  });
  await report.getByRole("button", { name: "Submit DWR" }).click();
  await employee.getByRole("button", { name: "Confirm submission" }).click();
  await expect(employee.getByText("DWR submitted for review")).toBeVisible();
  await employee.keyboard.press("Escape");
  // The open chat picks up the new status on its next 5 s poll.
  await expect(
    employee.getByText("Today's DWR is with your reviewer."),
  ).toBeVisible({ timeout: 15000 });

  await page.getByRole("tab", { name: "Reports" }).click();
  await page.getByRole("button", { name: "Team & review" }).click();
  // The report list refreshes every 15 s; the submission appears without a reload.
  const submitted = page
    .getByRole("row")
    .filter({ hasText: "Arjun Mehta" })
    .filter({ hasText: "Today" })
    .filter({ hasText: "Submitted" })
    .first();
  await expect(submitted).toBeVisible({ timeout: 30000 });
  await submitted.getByRole("button", { name: "Open" }).click();
  const review = page.getByRole("dialog").filter({ hasText: "Arjun Mehta" });
  await expect(
    review.getByText(`Aaj pump house ka inspection kiya ${run}`),
  ).toBeVisible();
  await review
    .getByLabel("Reason for your decision")
    .fill("Reviewed the employee-reported chat for this day.");
  await review.getByRole("button", { name: "Approve", exact: true }).click();
  await expect(page.getByText("Decision recorded")).toBeVisible();
  const popup = page.waitForEvent("popup");
  await review.getByRole("link", { name: "Print" }).click();
  const printable = await popup;
  await printable.waitForLoadState();
  await expect(
    printable.getByRole("heading", { name: "Chat messages", exact: true }),
  ).toBeVisible();
  await printable.screenshot({
    path: "docs/evidence/dwr-chat/browser-print.png",
    fullPage: true,
  });
  await printable.close();
  await page.keyboard.press("Escape");
  await page.setViewportSize({ width: 390, height: 844 });
  await expect
    .poll(() => page.evaluate(() => document.documentElement.scrollWidth))
    .toBeLessThanOrEqual(390);
  await employee.goto("/#/access");
  await expect(
    employee.getByRole("heading", {
      name: "Access is not granted",
      exact: true,
    }),
  ).toBeVisible();
  await employeeContext.close();
});
