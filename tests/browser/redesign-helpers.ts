import { test, expect, type Page } from "./fixtures.js";
import { mkdir } from "node:fs/promises";
import { pool } from "../../packages/db/src/index.js";
import { decrypt, totp } from "../../apps/api/src/security.js";
import { ids } from "../../packages/db/src/seed.js";
export async function signIn(page: Page, email: string, userId: string) {
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
