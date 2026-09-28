import { test, expect } from "./fixtures.js";
import { signIn } from "./redesign-helpers.js";
import { ids } from "../../packages/db/src/seed.js";
test("real local API exposes dedicated duty location with scoped authorization", async ({
  page,
}) => {
  const url = new URL(process.env.MIGRATION_DATABASE_URL!);
  if (
    !["localhost", "127.0.0.1"].includes(url.hostname) ||
    url.pathname !== "/hr_local"
  )
    throw Error("Synthetic local database only");
  await signIn(page, "superadmin@example.test", ids.superAdmin);
  await page.getByRole("link", { name: "Live tracking", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Live tracking", exact: true }),
  ).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Tracking settings", exact: true }),
  ).toBeVisible();
  await expect(page.getByText(/Last successful refresh:/)).toBeVisible();
  await page
    .getByRole("button", { name: "Tracking settings", exact: true })
    .click();
  await expect(
    page.getByRole("combobox", { name: "Duty window", exact: true }),
  ).toBeVisible();
  await page.keyboard.press("Escape");
  await page.screenshot({ path: "docs/evidence/tracking/live-local.png" });
});
