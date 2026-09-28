import { test, expect } from "./fixtures.js";
import { signIn } from "./redesign-helpers.js";
import { ids } from "../../packages/db/src/seed.js";

test("legacy HR and operations deep links retain shell; profile employment tab is usable", async ({
  page,
}) => {
  await signIn(page, "superadmin@example.test", ids.superAdmin);
  await page.evaluate(() => {
    (window as any).__legacyShell = document.querySelector(".sidebar");
  });
  for (const [width, height] of [
    [1366, 768],
    [1440, 900],
    [1920, 1080],
  ] as const) {
    await page.setViewportSize({ width, height });
    for (const route of ["hr", "operations"]) {
      await page.evaluate((route) => {
        location.hash = "/" + route;
      }, route);
      await expect(
        page.getByRole("heading", {
          name: route === "hr" ? "HR services" : "Your working day",
          exact: true,
        }),
      ).toBeVisible();
      await expect(page.locator("main .skeletons")).toHaveCount(0);
      await expect(page.locator("main .error-state")).toHaveCount(0);
      expect(
        await page.evaluate(
          () => document.documentElement.scrollWidth <= innerWidth,
        ),
      ).toBe(true);
      expect(
        await page.evaluate(
          () =>
            (window as any).__legacyShell ===
            document.querySelector(".sidebar"),
        ),
      ).toBe(true);
      await page.screenshot({
        path: `docs/evidence/hr-redesign/${width}-legacy-${route}.png`,
      });
    }
  }
  await page.getByRole("link", { name: "Employees", exact: true }).click();
  await page
    .getByRole("button", { name: "Open Arjun Mehta's profile" })
    .click();
  await page
    .getByRole("tab", { name: "Employment & history", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "Assignment history", exact: true }),
  ).toBeVisible();
  await page.screenshot({
    path: "docs/evidence/hr-redesign/employee-employment-history.png",
  });
  await page.keyboard.press("Escape");
  await expect(page.getByRole("dialog")).toHaveCount(0);
});
