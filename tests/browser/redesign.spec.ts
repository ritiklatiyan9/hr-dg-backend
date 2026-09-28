import { test, expect } from "./fixtures.js";
import { signIn } from "./redesign-helpers.js";
import { ids } from "../../packages/db/src/seed.js";
import { mkdir, writeFile } from "node:fs/promises";

test("login asks only for email ID and password and sends no tenant selector", async ({
  page,
}) => {
  let submitted: Record<string, unknown> | undefined;
  await page.route("**/auth/login", async (route) => {
    submitted = route.request().postDataJSON();
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({ mfaRequired: false, enrollmentRequired: false }),
    });
  });
  await page.goto("/");
  await expect(page.getByLabel("Organization ID")).toHaveCount(0);
  await expect(page.locator("form input")).toHaveCount(2);
  await page.getByLabel("Email ID").fill("employee@example.test");
  await page.getByLabel("Password", { exact: true }).fill("synthetic-password");
  await page.screenshot({
    path: "docs/evidence/hr-redesign/login-two-field.png",
  });
  await page.getByRole("button", { name: "Sign in", exact: true }).click();
  await expect.poll(() => submitted).toBeTruthy();
  expect(submitted).toEqual({
    email: "employee@example.test",
    password: "synthetic-password",
    kind: "web",
  });
});

test("authenticated redesign: persistent shell, scoped navigation, responsive routes and cached revisit", async ({
  page,
}) => {
  test.setTimeout(240000);
  const errors: string[] = [];
  page.on("pageerror", (e) => errors.push(e.message));
  await mkdir("docs/evidence/hr-redesign", { recursive: true });
  await page.setViewportSize({ width: 1440, height: 900 });
  await signIn(page, "superadmin@example.test", ids.superAdmin);
  await expect(
    page.getByRole("heading", { name: "Employees", exact: true }),
  ).toBeVisible();
  await page.evaluate(() => {
    (window as any).__shell = document.querySelector(".sidebar");
    (window as any).__header = document.querySelector(".topbar");
  });
  const routes = await page
    .locator('nav[aria-label="Main navigation"] a')
    .evaluateAll((as) =>
      as.map((a) => ({ href: a.getAttribute("href")!, name: a.textContent! })),
    );
  const measurements = [];
  for (const width of [1366, 1440, 1920]) {
    await page.setViewportSize({
      width,
      height: width === 1366 ? 768 : width === 1440 ? 900 : 1080,
    });
    for (const route of routes) {
      const start = Date.now();
      // By href: several labels share a prefix ("Attendance approvals").
      await page
        .locator(`nav[aria-label="Main navigation"] a[href="${route.href}"]`)
        .click();
      await expect(
        page.locator(
          `nav[aria-label="Main navigation"] a[href="${route.href}"]`,
        ),
      ).toHaveAttribute("aria-current", "page");
      await page.evaluate(
        () =>
          new Promise<void>((resolve) =>
            requestAnimationFrame(() => requestAnimationFrame(() => resolve())),
          ),
      );
      await expect(page.locator("main .skeletons")).toHaveCount(0, {
        timeout: 20000,
      });
      await expect(page.locator(".error-state")).toHaveCount(0);
      expect(
        await page.evaluate(
          () =>
            (window as any).__shell === document.querySelector(".sidebar") &&
            (window as any).__header === document.querySelector(".topbar"),
        ),
      ).toBe(true);
      expect(
        await page.evaluate(
          () => document.documentElement.scrollWidth <= innerWidth,
        ),
      ).toBe(true);
      measurements.push({
        width,
        route: route.href,
        clickToContentMs: Date.now() - start,
      });
      await page.screenshot({
        path: `docs/evidence/hr-redesign/${width}-${route.href.replace("#/", "")}.png`,
      });
    }
  }
  await page.getByRole("link", { name: "Employees", exact: true }).click();
  await expect(page.getByText("Arjun Mehta", { exact: true })).toBeVisible();
  await page
    .getByRole("button", { name: "Open Arjun Mehta's profile" })
    .click();
  await expect(page.getByRole("dialog")).toBeVisible();
  await page.keyboard.press("Tab");
  expect(
    await page.evaluate(
      () => !!document.activeElement?.closest('[role="dialog"]'),
    ),
  ).toBe(true);
  await page.screenshot({
    path: "docs/evidence/hr-redesign/employee-detail.png",
  });
  await page.keyboard.press("Escape");
  await expect(page.getByRole("dialog")).toHaveCount(0);
  await page.getByRole("button", { name: "Collapse navigation" }).click();
  await expect(page.locator(".shell")).toHaveClass(/is-collapsed/);
  await page.getByRole("button", { name: "Expand navigation" }).click();
  await page.getByRole("button", { name: "Select site", exact: true }).click();
  await expect(page.getByPlaceholder("Search sites…")).toBeVisible();
  await page.keyboard.press("Escape");
  await page.getByRole("button", { name: "Use dark theme" }).click();
  await page.screenshot({
    path: "docs/evidence/hr-redesign/dark-directory.png",
  });
  await page.setViewportSize({ width: 768, height: 1024 });
  await page.getByRole("button", { name: "Open navigation" }).click();
  await expect(page.getByRole("dialog")).toBeVisible();
  await page.screenshot({
    path: "docs/evidence/hr-redesign/tablet-navigation.png",
  });
  await page.keyboard.press("Escape");
  expect(errors).toEqual([]);
  await writeFile(
    "docs/evidence/hr-redesign/navigation.json",
    JSON.stringify({ measurements, errors }, null, 2),
  );
});

test("site switch, cache reuse, table controls and permission downgrade discard old records", async ({
  page,
}) => {
  test.setTimeout(90000);
  await signIn(page, "superadmin@example.test", ids.superAdmin);
  await expect(page.getByText("Arjun Mehta", { exact: true })).toBeVisible();
  let employeeReads = 0;
  page.on("request", (r) => {
    if (r.postData()?.includes("query Employees(")) employeeReads++;
  });
  await page.getByRole("link", { name: "Documents", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Documents", exact: true }),
  ).toBeVisible();
  await page.getByRole("link", { name: "Employees", exact: true }).click();
  await expect(page.getByText("Arjun Mehta", { exact: true })).toBeVisible();
  expect(employeeReads).toBe(0);
  await page.getByRole("button", { name: "Columns", exact: true }).click();
  await page.getByRole("menuitemcheckbox", { name: /Department/ }).click();
  await page.keyboard.press("Escape");
  await expect(
    page.getByRole("columnheader", { name: /Department/ }),
  ).toHaveCount(0);
  await page.getByRole("button", { name: "Select site", exact: true }).click();
  await page.getByRole("option", { name: /River Green/ }).click();
  await expect(page.getByText("Arjun Mehta", { exact: true })).toHaveCount(0);
  await expect(page.getByText("Meera Kapoor", { exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Select site", exact: true }).click();
  await page.getByRole("option", { name: /Defence Garden/ }).click();
  await expect(page.getByText("Arjun Mehta", { exact: true })).toBeVisible();
  // Frontend boundary test: real scoped responses narrowed to a downgraded view.
  await page.route("**/graphql", async (route) => {
    if (!route.request().postData()?.includes("query SiteScope"))
      return route.continue();
    const response = await route.fetch();
    const json = await response.json();
    json.data.scope.capabilities = json.data.scope.capabilities.filter(
      (c: string) => !c.startsWith("employees.") && !c.startsWith("access."),
    );
    await route.fulfill({ response, json });
  });
  await page.evaluate(() =>
    window.dispatchEvent(new Event("dg:scope-changed")),
  );
  await expect(
    page.getByRole("heading", { name: "Access is not granted" }),
  ).toBeVisible();
  await expect(page.getByText("Arjun Mehta", { exact: true })).toHaveCount(0);
  await expect(
    page.getByRole("link", { name: "Employees", exact: true }),
  ).toHaveCount(0);
});

test("table URL sorting stays responsive and request errors recover inside the shell", async ({
  page,
}) => {
  await signIn(page, "superadmin@example.test", ids.superAdmin);
  await page.getByRole("link", { name: "Payroll", exact: true }).click();
  await expect(
    page.getByRole("table", { name: "Payroll results" }),
  ).toBeVisible();
  await page.evaluate(() => {
    (window as any).__historyWrites = 0;
    const original = history.pushState.bind(history);
    history.pushState = (...args) => {
      (window as any).__historyWrites++;
      return original(...args);
    };
  });
  const sort = page
    .getByRole("columnheader", { name: /Pay period/ })
    .getByRole("button");
  await sort.click();
  await expect(page).toHaveURL(/sort=Pay\+period%3Aasc/);
  await sort.click();
  await expect(page).toHaveURL(/sort=Pay\+period%3Adesc/);
  await page.goBack();
  await expect(
    page.getByRole("columnheader", { name: /Pay period/ }),
  ).toHaveAttribute("aria-sort", "ascending");
  await page.getByRole("link", { name: "Employees", exact: true }).click();
  expect(
    await page.evaluate(() => (window as any).__historyWrites),
  ).toBeLessThan(6);
  let fail = true;
  await page.route("**/graphql", async (route) => {
    const body = route.request().postDataJSON();
    if (fail && body?.query?.includes("query Employees("))
      return route.fulfill({
        status: 503,
        contentType: "application/json",
        body: JSON.stringify({
          code: "INTERNAL_ERROR",
          message: "synthetic internal exception",
        }),
      });
    return route.continue();
  });
  await page.getByLabel("Search employees").fill("Arjun");
  await expect(
    page.getByText("We couldn’t load this information.", { exact: false }),
  ).toBeVisible();
  await expect(page.getByText("synthetic internal exception")).toHaveCount(0);
  await expect(page.locator(".sidebar")).toBeVisible();
  fail = false;
  await page.getByRole("button", { name: "Try again", exact: true }).click();
  await expect(page.getByText("Arjun Mehta", { exact: true })).toBeVisible();
});
