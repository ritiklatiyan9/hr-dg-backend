import { test, expect } from "@playwright/test";
// Contract-driven synthetic UI test for phone presence. Server status rules are
// covered in tests/integration/tracking.test.ts; no real GPS or data involved.
test("a connected phone without new fixes shows Idle, never Signal lost", async ({
  page,
}) => {
  await page.route("https://tile.openstreetmap.org/**", (route) =>
    route.fulfill({
      contentType: "image/svg+xml",
      body: '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><rect width="256" height="256" fill="#e9eeea"/></svg>',
    }),
  );
  const errors: string[] = [];
  page.on("pageerror", (e) => errors.push(e.message));
  const inputs: any[] = [];
  const iso = (ms: number) => new Date(Date.now() + ms).toISOString();
  const fix = (id: string, ageMs: number, longitude: number) => ({
    id,
    latitude: 28.6,
    longitude,
    accuracy_m: 40,
    classification: "inside",
    roster_version: 1,
    policy_version: 1,
    observed_at: iso(-ageMs),
    received_at: iso(-ageMs + 1000),
  });
  const person = (
    id: string,
    name: string,
    status: string,
    extra: Record<string, unknown>,
  ) => ({
    id,
    employee_id: `employee-${id}`,
    display_name: name,
    starts_at: iso(-3600000),
    ends_at: iso(3600000),
    version: 1,
    status,
    location: null,
    seen_at: null,
    location_off: false,
    ...extra,
  });
  const everyone = [
    person("r1", "Asha Live", "fresh", {
      location: fix("p1", 20000, 77.2),
      seen_at: iso(-19000),
    }),
    // Still indoors: last fix 12 min ago, heartbeat 20 s ago.
    person("r2", "Bala Still", "idle", {
      location: fix("p2", 720000, 77.2004),
      seen_at: iso(-20000),
    }),
    person("r3", "Chitra Off", "location_off", {
      location: fix("p3", 900000, 77.2008),
      seen_at: iso(-25000),
      location_off: true,
    }),
    person("r4", "Dev Gone", "stale", {
      location: fix("p4", 900000, 77.2012),
      seen_at: iso(-600000),
    }),
  ];
  await page.route("**/auth/session", (route) =>
    route.fulfill({ json: { authenticated: true, mfaRequired: false } }),
  );
  await page.route("**/graphql", async (route) => {
    const { query, variables: v } = route.request().postDataJSON();
    let data: any;
    if (query.includes("query Bootstrap"))
      data = {
        bootstrap: {
          organization: { id: "org", name: "Synthetic HR" },
          actor: { id: "hr", permissionVersion: 1 },
          sites: [
            { id: "dg", name: "Defence Garden", timezone: "Asia/Kolkata" },
          ],
        },
      };
    else if (query.includes("query SiteScope"))
      data = {
        scope: {
          site: { id: "dg", name: "Defence Garden", timezone: "Asia/Kolkata" },
          workDate: "2026-09-26",
          capabilities: ["employee_tracking.view"],
          modules: [],
          decisions: [],
        },
      };
    else if (query.includes("query TrackingMonitor")) {
      inputs.push(v.input);
      data = {
        trackingMonitor: {
          serverTime: new Date().toISOString(),
          policy: {
            version: 1,
            enabled: true,
            mode: "roster",
            sample_seconds: 30,
            stale_seconds: 120,
            notice: "Synthetic HR duty tracking disclosure for employees.",
          },
          employees: v.input.employeeId
            ? everyone.filter((e) => e.employee_id === v.input.employeeId)
            : everyone,
          next: null,
          geofence: null,
        },
      };
    } else throw Error(`Unexpected UI request ${query.slice(0, 70)}`);
    await route.fulfill({ json: { data } });
  });
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto("/#/tracking");
  await page
    .getByRole("button", { name: /Defence Garden.*Open workspace/ })
    .click();
  const list = page.getByRole("list", { name: "Scheduled employees" });
  const row = (name: string) =>
    list.getByRole("listitem").filter({ hasText: name });
  await expect(
    row("Asha Live").getByText("Live", { exact: true }),
  ).toBeVisible();
  await expect(
    row("Bala Still").getByText("Idle", { exact: true }),
  ).toBeVisible();
  await expect(row("Bala Still")).toContainText(
    "not moving · last fix 12 min ago",
  );
  await expect(row("Bala Still")).toContainText("phone seen");
  await expect(
    row("Chitra Off").getByText("Location off", { exact: true }),
  ).toBeVisible();
  await expect(row("Chitra Off")).toContainText(
    "Phone location is off",
  );
  await expect(
    row("Dev Gone").getByText("Signal lost", { exact: true }),
  ).toBeVisible();
  // Exactly one phone is actually lost; the still one is counted as Idle.
  const metric = (label: string) =>
    page
      .locator(".tracking-metric")
      .filter({ hasText: label })
      .locator("strong");
  await expect(metric("Signal lost")).toHaveText("1");
  await expect(metric("Idle")).toHaveText("1");
  await expect(metric("Location off")).toHaveText("1");
  await page.screenshot({
    path: "docs/evidence/tracking-presence/presence-desktop.png",
    fullPage: false,
  });
  // Opened from an employee profile: the monitor is asked for that person only.
  await page.goto("/#/tracking?employee=employee-r2");
  await expect(page.getByText("Showing Bala Still")).toBeVisible();
  await expect(list.getByRole("listitem")).toHaveCount(1);
  expect(inputs.at(-1)).toEqual({ employeeId: "employee-r2" });
  await page.getByRole("button", { name: "Show everyone" }).click();
  await expect(list.getByRole("listitem")).toHaveCount(4);
  await page.setViewportSize({ width: 390, height: 844 });
  await expect(
    page.evaluate(
      "document.documentElement.scrollWidth <= document.documentElement.clientWidth",
    ),
  ).resolves.toBe(true);
  await page.screenshot({
    path: "docs/evidence/tracking-presence/presence-mobile.png",
    fullPage: false,
  });
  expect(errors).toEqual([]);
});
