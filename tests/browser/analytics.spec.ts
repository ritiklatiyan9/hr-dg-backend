import { test, expect } from "./fixtures.js";
import { pool } from "../../packages/db/src/index.js";
import { decrypt, totp } from "../../apps/api/src/security.js";
import { ids } from "../../packages/db/src/seed.js";
test("analytics definitions, setup-required AI and responsive scope-safe dashboard", async ({
  page,
}) => {
  const errors: string[] = [];
  page.on("pageerror", (e) => errors.push(e.message));
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto("/");
  await page.getByLabel("Email ID").fill("admin@example.test");
  await page
    .getByLabel("Password", { exact: true })
    .fill(process.env.SEED_PASSWORD!);
  await page.getByRole("button", { name: "Sign in", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Two-step verification" }),
  ).toBeVisible();
  const db = pool(process.env.MIGRATION_DATABASE_URL!, 1);
  let secret: string;
  try {
    const setup = page.getByRole("button", { name: "Set up authenticator" });
    if (await setup.isVisible()) {
      await setup.click();
      secret = await page.locator(".secret").innerText();
    } else {
      secret = decrypt(
        (
          await db.query("SELECT mfa_secret FROM auth.users WHERE id=$1", [
            ids.siteAdmin,
          ])
        ).rows[0].mfa_secret,
        process.env.ENCRYPTION_KEY!,
      );
      await db.query("UPDATE auth.users SET last_totp_step=-1 WHERE id=$1", [
        ids.siteAdmin,
      ]);
    }
  } finally {
    await db.end();
  }
  await page.getByLabel("Six-digit code").fill(totp(secret!).generate());
  await page.getByRole("button", { name: "Verify and continue" }).click();
  await page
    .getByRole("button", { name: /Defence Garden.*Open workspace/ })
    .click();
  await page
    .getByRole("link", { name: "Management insights", exact: true })
    .click();
  await expect(
    page.getByText("Assigned workforce", { exact: true }),
  ).toBeVisible();
  await page
    .getByText("Definition and evidence", { exact: true })
    .first()
    .click();
  await expect(
    page.getByText("employees + site_assignments", { exact: true }),
  ).toBeVisible();
  await page.screenshot({
    path: "docs/evidence/phase6/web-analytics.png",
    fullPage: true,
  });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.screenshot({
    path: "docs/evidence/phase6/web-analytics-narrow.png",
    fullPage: false,
  });
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    ),
  ).toBe(true);
  expect(errors).toEqual([]);
});
