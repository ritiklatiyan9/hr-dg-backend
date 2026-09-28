import { test, expect } from "./fixtures.js";
import { signIn } from "./redesign-helpers.js";
import { ids } from "../../packages/db/src/seed.js";
import { mkdir } from "node:fs/promises";

test("attendance pages are discoverable and geofence coordinates draw on desktop and mobile", async ({
  page,
}) => {
  const url = new URL(process.env.MIGRATION_DATABASE_URL!);
  if (
    !["localhost", "127.0.0.1"].includes(url.hostname) ||
    url.pathname !== "/hr_local"
  )
    throw Error("Synthetic local database only");
  await mkdir("docs/evidence/attendance-flow", { recursive: true });
  const errors: string[] = [];
  page.on("pageerror", (e) => errors.push(e.message));
  await page.setViewportSize({ width: 1440, height: 1000 });
  await signIn(page, "superadmin@example.test", ids.superAdmin);
  for (const name of [
    "Mark IN / OUT",
    "Attendance",
    "Attendance approvals",
    "Site geofence",
    "Attendance policy",
  ]) {
    await expect(page.getByRole("link", { name, exact: true })).toBeVisible();
  }
  await page.getByRole("link", { name: "Site geofence", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Site geofence", exact: true }),
  ).toBeVisible();
  await expect(page.locator(".leaflet-container")).toBeVisible();
  await page
    .getByRole("textbox", { name: "Go to latitude, longitude" })
    .fill("28.6139, 77.2090");
  await page
    .getByRole("button", { name: "Use as centre", exact: true })
    .click();
  await expect(
    page.getByRole("spinbutton", { name: "Radius (metres)" }),
  ).toHaveValue("100");
  const ring = JSON.parse(
    await page.locator('input[name="coordinates"]').inputValue(),
  );
  expect(ring.length).toBe(33);
  expect(ring[0]).toEqual(ring.at(-1));
  await expect
    .poll(
      async () =>
        (await page.locator(".leaflet-tile-loaded").count()) > 0 ||
        (await page
          .getByText(
            "Map tiles are unavailable. You can still define the boundary using coordinates.",
          )
          .isVisible()),
      { timeout: 15000 },
    )
    .toBe(true);
  // Preview only: no site policy, boundary, attendance or employee data is changed.
  await page.screenshot({
    path: "docs/evidence/attendance-flow/geofence-desktop.png",
  });
  await page.setViewportSize({ width: 390, height: 844 });
  await expect
    .poll(() =>
      page.evaluate(() => document.documentElement.scrollWidth <= innerWidth),
    )
    .toBe(true);
  await page.screenshot({
    path: "docs/evidence/attendance-flow/geofence-mobile.png",
    fullPage: true,
  });
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page
    .getByRole("link", { name: "Attendance approvals", exact: true })
    .click();
  await expect(
    page
      .getByRole("heading", { name: "Attendance approvals", exact: true })
      .first(),
  ).toBeVisible();
  await openLatestPendingDay(page);
  await expect(page.getByText(/^Assigned approver:/)).toBeVisible();
  // Approval is assigned to HR; the site super_admin may still decide.
  await expect(page.getByText("You can decide · admin")).toBeVisible();
  await expect(page.getByText("Deciding as site admin")).toBeVisible();
  await expect(page.getByRole("button", { name: "Approve" })).toBeVisible();
  await page.getByRole("button", { name: /Choose review date/ }).click();
  await expect(page.getByRole("grid")).toBeVisible();
  await page.keyboard.press("Escape");
  const photo = page.locator(".attendance-review-photo img").first();
  await expect(photo).toBeVisible();
  await expect
    .poll(() => photo.evaluate((image: HTMLImageElement) => image.naturalWidth))
    .toBeGreaterThan(0);
  const preview = await page
    .context()
    .request.get((await photo.getAttribute("src"))!);
  expect(preview.ok()).toBe(true);
  expect(preview.headers()["content-disposition"]).toContain("inline");
  await page
    .getByRole("button", { name: /Enlarge photo evidence/ })
    .first()
    .click();
  await expect(
    page.getByRole("dialog", { name: /Photo evidence/ }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Close dialog" }).click();
  await page.screenshot({
    path: "docs/evidence/attendance-flow/approvals-desktop.png",
  });
  await page.getByRole("link", { name: "Mark IN / OUT", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Mark IN / OUT", exact: true }),
  ).toBeVisible();
  expect(errors).toEqual([]);
});

test("assigned approver sees decisions alongside attendance evidence", async ({
  page,
}) => {
  await signIn(page, "hr@example.test", ids.admin);
  await page
    .getByRole("link", { name: "Attendance approvals", exact: true })
    .click();
  await openLatestPendingDay(page);
  await expect(page.getByText("You can decide", { exact: true })).toBeVisible();
  await expect(page.getByText("Deciding as assigned approver")).toBeVisible();
  const inspector = page.getByRole("complementary", { name: "Request details" });
  await expect(inspector.getByText("Evidence", { exact: true })).toBeVisible();
  await inspector.getByRole("button", { name: "Reject" }).click();
  const decision = page.getByRole("dialog", { name: /^Review / });
  await expect(
    decision.getByRole("radio", { name: /^Reject / }),
  ).toBeChecked();
  await decision.getByRole("button", { name: "Cancel" }).click();
});

/** Steps back from today to the most recent day that has pending requests. */
async function openLatestPendingDay(page: import("@playwright/test").Page) {
  const pending = page.getByRole("tab", { name: /To review/ });
  for (let i = 0; i < 21; i++) {
    await expect(page.locator(".rd-skeleton-row")).toHaveCount(0);
    if (Number(await pending.locator("span").textContent()) > 0) return;
    const loaded = page.waitForResponse(
      (r) =>
        r.url().includes("/graphql") &&
        (r.request().postData() ?? "").includes("AttendanceReview"),
    );
    await page.getByRole("button", { name: "Previous day" }).click();
    await loaded;
  }
  throw Error("No pending attendance requests in the last three weeks");
}
