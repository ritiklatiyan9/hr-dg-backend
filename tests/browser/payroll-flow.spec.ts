import { test, expect, type Page } from "@playwright/test";
import { pool } from "../../packages/db/src/index.js";
import { ids } from "../../packages/db/src/seed.js";
import { totp } from "../../apps/api/src/security.js";
// Needs an isolated synthetic database (MIGRATION_DATABASE_URL → hr_test_*):
// it enrols MFA for seeded accounts and adds synthetic attendance.
const database = process.env.MIGRATION_DATABASE_URL!;
test.skip(
  !/\/hr_test_[a-z0-9_]+$/.test(new URL(database).pathname),
  "Run against an isolated hr_test_* database",
);
async function signIn(page: Page, email: string) {
  await page.goto("/");
  await page.getByLabel("Email ID").fill(email);
  await page
    .getByLabel("Password", { exact: true })
    .fill(process.env.SEED_PASSWORD!);
  await page.getByRole("button", { name: "Sign in", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Two-step verification" }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Set up authenticator" }).click();
  const secret = await page.locator(".secret").innerText();
  await page.getByLabel("Six-digit code").fill(totp(secret).generate());
  await page.getByRole("button", { name: "Verify and continue" }).click();
  await page
    .getByRole("button", { name: /Defence Garden.*Open workspace/ })
    .click();
}
const shot = (page: Page, name: string) =>
  page.screenshot({
    path: `docs/evidence/payroll-flow/${name}.png`,
    animations: "disabled",
  });
test("HR sets salary and sends attendance-based payroll; Admin approves and publishes", async ({
  browser,
}) => {
  test.setTimeout(180000);
  const month = new Date().toLocaleDateString("en-CA").slice(0, 7);
  const day = Number(new Date().toLocaleDateString("en-CA").slice(8, 10));
  test.skip(day < 20, "The run dialog defaults to the previous month");
  // Synthetic attendance: rostered 1st–5th, checked in 1st–3rd only.
  const db = pool(database, 1);
  try {
    const shift = (
      await db.query(
        "SELECT id FROM app.site_reference_items WHERE site_id=$1 AND kind='shift' LIMIT 1",
        [ids.dg],
      )
    ).rows[0].id;
    await db.query(
      `INSERT INTO app.shift_rosters(organization_id,site_id,employee_id,shift_id,work_date,starts_at,ends_at)
      SELECT $1,$2,$3,$4,d::date,(d::date+time '09:00') AT TIME ZONE 'Asia/Kolkata',(d::date+time '18:00') AT TIME ZONE 'Asia/Kolkata'
      FROM generate_series($5::date,$5::date+4,interval '1 day') d ON CONFLICT DO NOTHING`,
      [ids.org, ids.dg, ids.employeeProfile, shift, `${month}-01`],
    );
    await db.query(
      `WITH s AS (INSERT INTO app.duty_sessions(organization_id,site_id,employee_id,user_id,device_id,policy_version,geofence_version,status,opened_at,closed_at)
      SELECT $1,$2,$3,$4,gen_random_uuid(),1,1,'closed',(d::date+time '09:30') AT TIME ZONE 'Asia/Kolkata',(d::date+time '18:00') AT TIME ZONE 'Asia/Kolkata'
      FROM generate_series($5::date,$5::date+2,interval '1 day') d RETURNING id,opened_at),
      e AS (INSERT INTO app.duty_events(organization_id,site_id,employee_id,user_id,duty_id,client_event_id,device_id,sequence,kind,captured_at,payload_version,payload_hash,payload)
      SELECT $1,$2,$3,$4,s.id,gen_random_uuid(),gen_random_uuid(),1,'IN',s.opened_at,1,'synthetic','{}' FROM s RETURNING id,captured_at)
      INSERT INTO app.event_verifications(organization_id,site_id,employee_id,event_id,status,reason,effective_at) SELECT $1,$2,$3,e.id,'accepted','synthetic',e.captured_at FROM e`,
      [ids.org, ids.dg, ids.employeeProfile, ids.employee, `${month}-01`],
    );
  } finally {
    await db.end();
  }
  const errors: string[] = [];
  const hrCtx = await browser.newContext({
    viewport: { width: 1440, height: 1000 },
  });
  const hr = await hrCtx.newPage();
  hr.on("pageerror", (e) => errors.push(e.message));
  await signIn(hr, "hr@example.test");
  // 1. Salaries: HR sets Arjun's monthly salary; their own row has no button.
  await hr.goto("/#/salaries");
  await expect(
    hr.getByRole("heading", { name: "Salaries", exact: true }),
  ).toBeVisible();
  const arjun = hr.getByRole("row").filter({ hasText: "Arjun Mehta" });
  await expect(
    hr.getByRole("row").filter({ hasText: "Aditi Sharma" }).getByRole("button"),
  ).toHaveCount(0);
  await arjun.getByRole("button", { name: "Set salary" }).click();
  const salary = hr.getByRole("dialog");
  await salary.getByLabel("Basic").fill("25000");
  await salary.getByLabel("House rent allowance (HRA)").fill("5000");
  await salary.getByLabel("Provident fund (PF)").fill("1800");
  await expect(salary).toContainText("₹28,200.00");
  await shot(hr, "salary-dialog");
  await salary.getByRole("button", { name: "Save salary" }).click();
  await expect(salary).toHaveCount(0);
  await expect(arjun).toContainText("₹28,200.00");
  await shot(hr, "salaries");
  // 2. Run payroll: pay is suggested from attendance (28 of 30 days).
  await hr.goto("/#/payroll");
  await hr.getByRole("button", { name: "Run payroll" }).click();
  const run = hr.getByRole("dialog");
  await expect(run.getByLabel("Pay month")).toHaveValue(month);
  await run.getByRole("checkbox").check();
  await run.getByRole("button", { name: "Prepare drafts" }).click();
  await expect(run).toContainText("pay suggested from attendance");
  await run.getByRole("button", { name: "Done" }).click();
  const row = hr.getByRole("row").filter({ hasText: "Arjun Mehta" });
  await expect(row).toContainText("payable");
  await row.getByRole("button", { name: "Open" }).click();
  const slip = hr.getByRole("dialog");
  await expect(slip).toContainText("Attendance used for this pay");
  await expect(slip).toContainText("₹26,200.00");
  await shot(hr, "draft-attendance");
  await expect(slip.getByRole("button", { name: "Approve" })).toHaveCount(0);
  await slip.getByRole("button", { name: "Send for approval" }).click();
  const send = hr.getByRole("dialog").last();
  await send.getByRole("button", { name: "Send for approval" }).click();
  await expect(hr.getByRole("dialog")).toHaveCount(0);
  await expect(row).toContainText("Awaiting approval");
  // 3. Admin: final approval, then publish.
  const adminCtx = await browser.newContext({
    viewport: { width: 1440, height: 1000 },
  });
  const admin = await adminCtx.newPage();
  admin.on("pageerror", (e) => errors.push(e.message));
  await signIn(admin, "admin@example.test");
  await admin.goto("/#/payroll");
  const pending = admin.getByRole("row").filter({ hasText: "Arjun Mehta" });
  await pending.getByRole("button", { name: "Open" }).click();
  await admin
    .getByRole("dialog")
    .getByRole("button", { name: "Approve" })
    .click();
  await admin
    .getByRole("dialog")
    .last()
    .getByRole("button", { name: "Approve" })
    .click();
  await expect(admin.getByRole("dialog")).toHaveCount(0);
  await expect(pending).toContainText("Approved");
  await pending.getByRole("button", { name: "Open" }).click();
  await admin
    .getByRole("dialog")
    .getByRole("button", { name: "Publish payslip" })
    .click();
  await admin
    .getByRole("dialog")
    .last()
    .getByRole("button", { name: "Publish payslip" })
    .click();
  await expect(admin.getByRole("dialog")).toHaveCount(0);
  await expect(pending).toContainText("Published");
  await shot(admin, "published");
  // 4. Roles & permissions: who does what, and the payroll flow.
  await admin.goto("/#/permissions");
  await expect(
    admin.getByRole("heading", { name: "Roles & permissions" }),
  ).toBeVisible();
  const payroll = admin
    .getByRole("table", { name: "Role defaults by module" })
    .getByRole("row")
    .filter({ hasText: "Payroll administration" });
  await expect(payroll).toContainText("Full");
  await expect(payroll).toContainText("View · Create · Edit · Export");
  await shot(admin, "roles-permissions");
  await admin.setViewportSize({ width: 390, height: 844 });
  expect(
    await admin.evaluate(
      "document.documentElement.scrollWidth <= document.documentElement.clientWidth",
    ),
  ).toBe(true);
  await shot(admin, "roles-permissions-mobile");
  expect(errors).toEqual([]);
  await hrCtx.close();
  await adminCtx.close();
});
