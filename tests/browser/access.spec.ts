import { test, expect, type Page } from "./fixtures.js";
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
test("Super Admin previews and saves scoped access; captures desktop, dark Hindi, mobile web and foundation evidence", async ({
  page,
}) => {
  test.setTimeout(90000);
  const exceptions: string[] = [];
  page.on("pageerror", (e) => exceptions.push(e.message));
  await mkdir("docs/evidence/phase2", { recursive: true });
  await page.setViewportSize({ width: 1512, height: 1100 });
  await signIn(page, "superadmin@example.test", ids.superAdmin);
  await expect(page.getByText("Arjun Mehta", { exact: true })).toBeVisible();
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({
    path: "docs/evidence/phase2/web-directory.png",
    fullPage: true,
  });
  await page
    .getByRole("link", { name: "Users & module access", exact: true })
    .click();
  await page.getByRole("listitem").filter({ hasText: "Arjun Mehta" }).click();
  await expect(
    page.getByRole("heading", { name: "Arjun Mehta", exact: true }),
  ).toBeVisible();
  await page.getByRole("tab", { name: "Detailed permissions" }).click();
  if (
    (await page.getByLabel("employees.field.salary override").inputValue()) !==
    "inherit"
  ) {
    await page
      .getByLabel("employees.field.salary override")
      .selectOption("inherit");
    await page
      .getByLabel("Reason for changes")
      .fill("Browser verification: restore interrupted synthetic test");
    await page
      .getByRole("button", { name: "Preview changes", exact: true })
      .click();
    await page.getByRole("button", { name: "Confirm access changes" }).click();
    await expect(
      page.getByText("Access updated. Existing sessions were signed out."),
    ).toBeVisible();
  }
  await expect(page.getByLabel("employees.field.salary override")).toHaveValue(
    "inherit",
  );
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({
    path: "docs/evidence/phase2/web-access.png",
    fullPage: true,
  });
  await page.getByLabel("employees.field.salary override").selectOption("deny");
  await page
    .getByLabel("Reason for changes")
    .fill("Browser verification: explicit salary restriction");
  await page
    .getByRole("button", { name: "Preview changes", exact: true })
    .click();
  await expect(page.getByRole("dialog")).toBeVisible();
  await expect(
    page.getByRole("dialog").getByText("Explicit deny at this site"),
  ).toBeVisible();
  // Native dialog contains keyboard focus; Tab cannot move into background navigation.
  await page.keyboard.press("Tab");
  expect(
    await page.evaluate(
      () => !!document.activeElement?.closest('[role="dialog"]'),
    ),
  ).toBe(true);
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({
    path: "docs/evidence/phase2/web-access-preview.png",
    fullPage: true,
  });
  await page.getByRole("button", { name: "Confirm access changes" }).click();
  await expect(
    page.getByText("Access updated. Existing sessions were signed out."),
  ).toBeVisible();
  await page.getByRole("tab", { name: "Change history" }).click();
  await expect(
    page
      .getByText("Browser verification: explicit salary restriction", {
        exact: true,
      })
      .first(),
  ).toBeVisible();
  // Restore the synthetic account through the same audited UI workflow.
  await page.getByRole("tab", { name: "Detailed permissions" }).click();
  await page
    .getByLabel("employees.field.salary override")
    .selectOption("inherit");
  await page
    .getByLabel("Reason for changes")
    .fill("Browser verification: restore original synthetic access");
  await page
    .getByRole("button", { name: "Preview changes", exact: true })
    .click();
  await page.getByRole("button", { name: "Confirm access changes" }).click();
  await expect(
    page.getByText("Access updated. Existing sessions were signed out."),
  ).toBeVisible();
  await page.getByRole("button", { name: "Use dark theme" }).click();
  await page.getByLabel("Language", { exact: true }).selectOption("hi");
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({
    path: "docs/evidence/phase2/web-access-dark-hindi.png",
    fullPage: true,
  });
  await page.getByLabel("Language", { exact: true }).selectOption("en");
  await page.getByRole("button", { name: "Use light theme" }).click();
  await page
    .getByRole("link", { name: "Site & employee setup", exact: true })
    .click();
  await expect(
    page.getByRole("tab", { name: "Departments", exact: true }),
  ).toBeVisible();
  await page.getByRole("tab", { name: "Shifts", exact: true }).click();
  await expect(
    page
      .getByRole("table", { name: "Shifts" })
      .getByText("General shift", { exact: true }),
  ).toBeVisible();
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({
    path: "docs/evidence/phase2/web-site-setup.png",
    fullPage: true,
  });
  await page
    .getByRole("link", { name: "All Sites · reporting", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "Organization overview" }),
  ).toBeVisible();
  await expect(
    page.getByRole("cell", { name: "River Green", exact: true }),
  ).toBeVisible();
  await page.getByRole("link", { name: "Employees", exact: true }).click();
  await page
    .getByRole("button", { name: "Open Arjun Mehta's profile" })
    .click();
  await expect(page.getByText("₹42,000.00", { exact: true })).toBeVisible();
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({
    path: "docs/evidence/phase2/web-employee-profile.png",
    fullPage: true,
  });
  await page.getByRole("button", { name: "Close dialog" }).click();
  await page.setViewportSize({ width: 390, height: 844 });
  await page.getByRole("button", { name: "Open navigation" }).click();
  await page
    .getByRole("link", { name: "Users & module access", exact: true })
    .click();
  await page.getByRole("listitem").filter({ hasText: "Arjun Mehta" }).click();
  await expect(page.getByLabel("employees.view override")).toBeVisible();
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth + 1,
    ),
  ).toBe(true);
  const heading = await page.locator(".editor-header").boundingBox();
  expect(heading!.x).toBeGreaterThanOrEqual(0);
  expect(heading!.x + heading!.width).toBeLessThanOrEqual(390);
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({
    path: "docs/evidence/phase2/web-mobile-access.png",
    fullPage: true,
  });
  expect(exceptions).toEqual([]);
});
test("HR direct forbidden access route performs no administration fetch; released HR documents remain separate", async ({
  page,
}) => {
  await signIn(page, "hr@example.test", ids.admin);
  const forbiddenRequests: string[] = [];
  page.on("request", (r) => {
    if (r.postData()?.includes("query AccessUsers"))
      forbiddenRequests.push(r.url());
  });
  await page.goto("/#/access");
  await page.reload();
  await page
    .getByRole("button", { name: /Defence Garden.*Open workspace/ })
    .click();
  await expect(
    page.getByRole("heading", { name: "Access is not granted" }),
  ).toBeVisible();
  expect(forbiddenRequests).toEqual([]);
  await page.getByRole("link", { name: "Documents", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Documents", exact: true }),
  ).toBeVisible();
  await page.getByRole("link", { name: "Employees", exact: true }).click();
  await page
    .getByRole("button", { name: "Open Arjun Mehta's profile" })
    .click();
  await expect(page.getByText("₹42,000.00", { exact: true })).toHaveCount(0);
  await expect(page.getByText("DEMO-ONLY-1234", { exact: true })).toHaveCount(
    0,
  );
});
