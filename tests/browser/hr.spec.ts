import { test, expect } from "./fixtures.js";
import { pool } from "../../packages/db/src/index.js";
import { decrypt, totp } from "../../apps/api/src/security.js";
import { ids } from "../../packages/db/src/seed.js";
import { writeFile } from "node:fs/promises";

test("HR signs in with MFA, switches sites, edits a persisted profile and logs out", async ({
  page,
  context,
}) => {
  const password = process.env.SEED_PASSWORD;
  if (!password) throw new Error("Load local .env");
  await page.goto("/");
  await page.getByLabel("Email ID").fill("hr@example.test");
  await page.getByLabel("Password", { exact: true }).fill(password);
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
        await p.query("SELECT mfa_secret FROM auth.users WHERE id=$1", [
          ids.admin,
        ])
      ).rows[0];
      secret = decrypt(row.mfa_secret, process.env.ENCRYPTION_KEY!);
      await p.query("UPDATE auth.users SET last_totp_step=-1 WHERE id=$1", [
        ids.admin,
      ]);
    } finally {
      await p.end();
    }
  }
  await writeFile(
    ".local/demo-authenticator.txt",
    totp(secret, "hr@example.test").toString(),
    { mode: 0o600 },
  );
  await page.getByLabel("Six-digit code").fill(totp(secret).generate());
  await page.getByRole("button", { name: "Verify and continue" }).click();
  await page
    .getByRole("button", { name: /Defence Garden.*Open workspace/ })
    .click();
  await expect(page.getByText("Arjun Mehta", { exact: true })).toBeVisible();
  await expect(page.getByText("Meera Kapoor", { exact: true })).toHaveCount(0);
  // Different tabs share authentication, but never their chosen site.
  const other = await context.newPage();
  await other.goto("/");
  await expect(
    other.getByRole("heading", { name: "Where are you working today?" }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Select site", exact: true }).click();
  await page.getByRole("option", { name: /River Green/ }).click();
  await expect(page.getByText("Meera Kapoor", { exact: true })).toBeVisible();
  await expect(
    other.getByRole("button", { name: "Select site", exact: true }),
  ).toContainText("Select a site");
  await page
    .getByRole("button", { name: "Open Arjun Mehta's profile" })
    .click();
  const phone = page.getByLabel("Phone number");
  const original = await phone.inputValue();
  await phone.fill("+91 9222222222");
  await page.getByRole("button", { name: "Save phone" }).click();
  // The profile sheet reloads the live record and stays open after saving.
  await expect(page.getByText("Phone number saved.")).toBeVisible();
  await page.getByRole("button", { name: "Close dialog" }).click();
  await expect(page.getByRole("dialog")).toHaveCount(0);
  await page.getByRole("button", { name: "Select site", exact: true }).click();
  await page.getByRole("option", { name: /Defence Garden/ }).click();
  await page
    .getByRole("button", { name: "Open Arjun Mehta's profile" })
    .click();
  await expect(page.getByLabel("Phone number")).toHaveValue("+91 9222222222");
  await page.getByLabel("Phone number").fill(original);
  await page.getByRole("button", { name: "Save phone" }).click();
  // The profile sheet reloads the live record and stays open after saving.
  await expect(page.getByText("Phone number saved.")).toBeVisible();
  await page.getByRole("button", { name: "Close dialog" }).click();
  await expect(page.getByRole("dialog")).toHaveCount(0);
  await page.getByRole("button", { name: "Export", exact: true }).click();
  await page
    .getByRole("button", { name: "Prepare export", exact: true })
    .click();
  await expect(page.getByRole("link", { name: "Download CSV" })).toBeVisible({
    timeout: 15000,
  });
  const [download] = await Promise.all([
    page.waitForEvent("download"),
    page.getByRole("link", { name: "Download CSV" }).click(),
  ]);
  const stream = await download.createReadStream();
  let csv = "";
  for await (const chunk of stream!) csv += chunk.toString();
  expect(csv).toContain("Arjun Mehta");
  expect(csv).not.toContain("Meera Kapoor");
  expect(csv).not.toContain("42000.00");
  await page.getByRole("button", { name: "Close dialog" }).click();
  await page.getByRole("button", { name: "Sign out", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Welcome back" }),
  ).toBeVisible();
  await other.reload();
  await expect(
    other.getByRole("heading", { name: "Welcome back" }),
  ).toBeVisible();
});
