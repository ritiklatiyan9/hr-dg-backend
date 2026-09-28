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
test("connected policy, photo attendance, tasks and durable inbox across admin and employee", async ({
  page,
  browser,
}) => {
  test.setTimeout(120000);
  page.setDefaultTimeout(15000);
  const database = new URL(process.env.MIGRATION_DATABASE_URL!);
  if (
    !["localhost", "127.0.0.1"].includes(database.hostname) ||
    database.pathname !== "/hr_local"
  )
    throw Error("Synthetic loopback hr_local database required");
  // A browser login gets a new session/device. Reset only this synthetic fixture's
  // abandoned open duty; never impersonate its prior device or weaken checkout.
  const fixture = pool(database.toString(), 1);
  try {
    await fixture.query(
      "UPDATE app.duty_sessions SET status='closed',closed_at=now(),version=version+1 WHERE organization_id=$1 AND employee_id=$2 AND status='open'",
      [ids.org, ids.employeeProfile],
    );
  } finally {
    await fixture.end();
  }
  await mkdir("docs/evidence/phase3", { recursive: true });
  await page.setViewportSize({ width: 1440, height: 1050 });
  await signIn(page, "superadmin@example.test", ids.superAdmin);
  await page.getByRole("link", { name: "Attendance", exact: true }).click();
  await page.getByRole("tab", { name: "Policy & roster", exact: true }).click();
  await page
    .getByRole("button", { name: "Configure policy", exact: true })
    .click();
  const dialog = page.getByRole("dialog");
  await dialog.getByLabel("Permit encrypted offline capture").check();
  for (const [key, v] of Object.entries({
    offlineMaxHours: 4,
    maxAccuracyM: 100,
    freshnessSeconds: 120,
    clockSkewSeconds: 30,
    gapSeconds: 120,
    maxSessionHours: 18,
    lateGraceMinutes: 10,
    earlyGraceMinutes: 10,
  }))
    await dialog.locator(`[name="${key}"]`).fill(String(v));
  await dialog.getByLabel("Attendance approver").selectOption(ids.admin);
  await dialog
    .getByLabel("Reason / review note")
    .fill("Synthetic browser acceptance policy only; not company rules");
  await dialog.getByRole("button", { name: "Save", exact: true }).click();
  await expect(dialog).toHaveCount(0);
  await page.getByRole("button", { name: "Edit boundary" }).click();
  await dialog
    .getByLabel("Boundary name")
    .fill("Synthetic Delhi test boundary");
  await dialog
    .getByLabel("Closed polygon: longitude,latitude per line")
    .fill("77.19,28.59\n77.21,28.59\n77.21,28.61\n77.19,28.61\n77.19,28.59");
  await dialog
    .getByLabel("Reason / review note")
    .fill("Synthetic browser and emulator geofence");
  await dialog.getByRole("button", { name: "Save", exact: true }).click();
  await expect(dialog).toHaveCount(0);
  await page.screenshot({
    path: "docs/evidence/phase3/web-policy.png",
    fullPage: true,
  });
  await page.getByRole("tab", { name: "Tasks", exact: true }).click();
  await page.getByRole("button", { name: "Assign task", exact: true }).click();
  const title = `Synthetic site inspection ${Date.now()}`;
  await dialog
    .getByRole("combobox", { name: "Employee", exact: true })
    .selectOption(ids.employeeProfile);
  await dialog.getByLabel("Task title").fill(title);
  await dialog
    .getByLabel("Details")
    .fill("Verify assigned work and report a synthetic result.");
  await dialog.getByLabel("Deadline").fill("2026-10-01T17:00");
  await dialog.getByLabel("Priority").selectOption("high");
  await dialog.getByRole("button", { name: "Save", exact: true }).click();
  await expect(dialog).toHaveCount(0);
  await expect(page.getByText(title, { exact: true })).toBeVisible();
  const employeeContext = await browser.newContext({
    permissions: ["geolocation"],
    geolocation: { latitude: 28.6, longitude: 77.2, accuracy: 10 },
    viewport: { width: 1280, height: 950 },
  });
  const employee = await employeeContext.newPage();
  await employee.goto("/#/operations");
  await employee.getByLabel("Email ID").fill("employee@example.test");
  await employee
    .getByLabel("Password", { exact: true })
    .fill(process.env.SEED_PASSWORD!);
  await employee.getByRole("button", { name: "Sign in", exact: true }).click();
  await employee
    .getByRole("button", { name: /Defence Garden.*Open workspace/ })
    .click();
  await expect(
    employee.getByRole("heading", { name: "Your working day" }),
  ).toBeVisible();
  await employee.getByRole("tab", { name: "Tasks", exact: true }).click();
  await expect(employee.getByText(title, { exact: true })).toBeVisible();
  await employee
    .getByRole("row")
    .filter({ hasText: title })
    .getByRole("button", { name: "Open task" })
    .click();
  await employee
    .getByLabel(`Status ${title}`, { exact: true })
    .selectOption("in_progress");
  const task = employee.locator(".ops-task").filter({ hasText: title });
  await task.getByRole("button", { name: "Comment", exact: true }).click();
  await employee
    .getByRole("dialog")
    .getByLabel("Comment", { exact: true })
    .fill("Synthetic mobile-team workflow verified.");
  await employee
    .getByRole("dialog")
    .getByRole("button", { name: "Save", exact: true })
    .click();
  await expect(
    employee.getByRole("dialog", { name: "Add comment", exact: true }),
  ).toHaveCount(0);
  await expect(
    employee.getByRole("dialog", { name: "Task details", exact: true }),
  ).toBeVisible();
  await employee.screenshot({
    path: "docs/evidence/phase3/web-employee-tasks.png",
    fullPage: true,
  });
  await employee
    .getByRole("button", { name: "Close dialog", exact: true })
    .click();
  await employee.getByRole("tab", { name: "Today", exact: true }).click();
  const photo = await sharp({
    create: { width: 80, height: 80, channels: 3, background: "#277052" },
  })
    .jpeg()
    .toBuffer();
  const checkIn = employee.getByRole("button", {
    name: "Photo check-in",
    exact: true,
  });
  // This journey owns its new duty; checkout must retain the same session/device.
  async function punch(label: string) {
    const chooser = employee.waitForEvent("filechooser");
    await employee.getByRole("button", { name: label, exact: true }).click();
    await (
      await chooser
    ).setFiles({
      name: "synthetic-evidence.jpg",
      mimeType: "image/jpeg",
      buffer: photo,
    });
  }
  if (
    await employee
      .getByRole("button", { name: "Photo check-out", exact: true })
      .isVisible()
  ) {
    await punch("Photo check-out");
    await expect(checkIn).toBeVisible();
  }
  await punch("Photo check-in");
  await expect(
    employee.getByRole("button", { name: "Photo check-out", exact: true }),
  ).toBeVisible();
  await employee.getByRole("tab", { name: "Attendance", exact: true }).click();
  await employee.getByRole("button", { name: "View evidence" }).first().click();
  await expect(
    employee
      .getByRole("dialog")
      .locator("p", { hasText: "Check-in" })
      .filter({ hasText: "Verified" })
      .first(),
  ).toBeVisible();
  await employee.screenshot({
    path: "docs/evidence/phase3/web-duty-evidence.png",
    fullPage: true,
  });
  await employee.getByRole("button", { name: "Close dialog" }).click();
  await employee.getByRole("tab", { name: "Today", exact: true }).click();
  await punch("Photo check-out");
  await expect(checkIn).toBeVisible();
  await page.reload();
  await page
    .getByRole("button", { name: /Defence Garden.*Open workspace/ })
    .click();
  await page.getByRole("tab", { name: "Tasks", exact: true }).click();
  await page
    .getByRole("row")
    .filter({ hasText: title })
    .getByRole("button", { name: "Open task" })
    .click();
  await expect(page.getByLabel(`Status ${title}`, { exact: true })).toHaveValue(
    "in_progress",
  );
  await expect(
    page
      .locator(".ops-task")
      .filter({ hasText: title })
      .getByText("Synthetic mobile-team workflow verified."),
  ).toBeVisible();
  await page.screenshot({
    path: "docs/evidence/phase3/web-admin-tasks.png",
    fullPage: true,
  });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.screenshot({
    path: "docs/evidence/phase3/web-mobile.png",
    fullPage: true,
  });
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBe(true);
  await employeeContext.close();
});
