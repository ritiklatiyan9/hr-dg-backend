import { test, expect } from "@playwright/test";
// Contract-driven synthetic UI test. Real RLS/persistence is covered separately
// in tests/integration/tracking.test.ts; no production data or real GPS involved.
test("duty location page, settings, route, disconnection and scope isolation", async ({
  page,
}) => {
  let failTiles = false;
  if (!process.env.REAL_MAP_TILES)
    await page.route("https://tile.openstreetmap.org/**", (route) =>
      failTiles
        ? route.abort()
        : route.fulfill({
            contentType: "image/svg+xml",
            body: '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><rect width="256" height="256" fill="#e9eeea"/><path d="M0 80H256M70 0V256M0 210H256M220 0V256" stroke="#fff" stroke-width="9"/><path d="M0 80H256M70 0V256M0 210H256M220 0V256" stroke="#d5dbd4" stroke-width="1"/><text x="90" y="150" fill="#809084" font-size="11">TEST TILE</text></svg>',
          }),
    );
  const errors: string[] = [];
  page.on("pageerror", (e) => errors.push(e.message));
  let enabled = true,
    fail = false;
  const commands: any[] = [];
  let serverNow = Date.now();
  let sampleNumber = 1;
  let location = {
    id: "point-1",
    latitude: 28.6,
    longitude: 77.2,
    accuracy_m: 8,
    classification: "inside",
    roster_version: 1,
    policy_version: 1,
    observed_at: new Date(serverNow - 30000).toISOString(),
    received_at: new Date(serverNow - 29000).toISOString(),
  };
  const now = () => new Date(serverNow).toISOString();
  const nextFix = (longitude: number, delayed = false) => {
    serverNow += 15000 + (delayed ? 120000 : 0);
    location = {
      ...location,
      id: `point-${++sampleNumber}`,
      longitude,
      observed_at: new Date(serverNow - (delayed ? 120000 : 0)).toISOString(),
      received_at: new Date(serverNow + 1000).toISOString(),
    };
  };
  const policy = () => ({
    version: 1,
    enabled,
    mode: "roster",
    sample_seconds: 30,
    stale_seconds: 120,
    notice: "Synthetic HR duty tracking disclosure for employees.",
  });
  const employee = () => ({
    id: "roster-1",
    display_name: "Arjun Mehta · Synthetic",
    starts_at: new Date(Date.now() - 3600000).toISOString(),
    ends_at: new Date(Date.now() + 3600000).toISOString(),
    status: enabled ? "fresh" : "disabled",
    version: 1,
    location,
  });
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
            { id: "rg", name: "River Green", timezone: "Asia/Kolkata" },
          ],
        },
      };
    else if (query.includes("query SiteScope"))
      data = {
        scope: {
          site: {
            id: v.siteId,
            name: v.siteId === "dg" ? "Defence Garden" : "River Green",
            timezone: "Asia/Kolkata",
          },
          workDate: "2026-09-25",
          capabilities: ["employee_tracking.view", "employee_tracking.manage"],
          modules: [],
          decisions: [],
        },
      };
    else if (query.includes("mutation TrackingCommand")) {
      commands.push(v);
      enabled = v.input.enabled;
      data = { trackingCommand: { id: "policy-2", version: 2 } };
    } else if (query.includes("query TrackingMonitor")) {
      if (fail)
        return route.fulfill({
          status: 503,
          json: { message: "Temporary synthetic failure" },
        });
      data = {
        trackingMonitor: v.input.rosterId
          ? {
              serverTime: now(),
              policy: policy(),
              roster: employee(),
              points: [location],
              next: null,
            }
          : {
              serverTime: now(),
              policy: policy(),
              employees: v.siteId === "dg" ? [employee()] : [],
              next: null,
              geofence: {
                type: "Polygon",
                coordinates: [
                  [
                    [77.199, 28.599],
                    [77.201, 28.599],
                    [77.201, 28.601],
                    [77.199, 28.601],
                    [77.199, 28.599],
                  ],
                ],
              },
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
  await expect(
    page.getByRole("heading", { name: "Live tracking", exact: true }),
  ).toBeVisible();
  await expect(
    page.getByText("Arjun Mehta · Synthetic", { exact: true }),
  ).toBeVisible();
  await expect(
    page
      .getByRole("list", { name: "Scheduled employees" })
      .getByText("Live", { exact: true }),
  ).toBeVisible();
  await expect
    .poll(async () =>
      page.locator(".main").evaluate((e) => e.getBoundingClientRect().left),
    )
    .toBeGreaterThan(247);

  await expect(page.locator(".leaflet-tile-loaded").first()).toBeVisible();
  await expect(
    page.getByRole("region", { name: "Employee location overview map" }),
  ).toBeVisible();
  await expect(page.getByRole("link", { name: "OpenStreetMap" })).toBeVisible();
  const mapBefore = await page
    .locator(".duty-leaflet-map")
    .evaluate((e: any) => e._leaflet_id);
  await page.getByRole("button", { name: "Refresh", exact: true }).click();
  expect(
    await page.locator(".duty-leaflet-map").evaluate((e: any) => e._leaflet_id),
  ).toBe(mapBefore);
  // Actual marker motion: intermediate screen positions, exact stop and stable map.
  const overviewPin = page.locator(".duty-map-pin");
  const refresh = async (name = "Refresh") => {
    await Promise.all([
      page.waitForResponse(
        (r) =>
          r.url().endsWith("/graphql") &&
          r.request().postDataJSON()?.query?.includes("query TrackingMonitor"),
      ),
      page.getByRole("button", { name, exact: true }).click(),
    ]);
    await expect(
      name === "Refresh"
        ? page.locator(".duty-map-pin").first()
        : page.getByRole("dialog").locator(".duty-map-head"),
    ).toHaveAttribute("data-observed-at", location.observed_at);
  };
  const screenX = () =>
    overviewPin.evaluate((e) => e.getBoundingClientRect().x);
  const startX = await screenX();
  nextFix(77.201);
  await refresh();
  await expect(overviewPin).toHaveAttribute("data-motion", "gliding");
  await page.waitForTimeout(650);
  const middleX = await screenX();
  expect(middleX).toBeGreaterThan(startX);
  await expect(overviewPin).toHaveAttribute("data-motion", "settled");
  expect(await screenX()).toBeGreaterThan(middleX);
  await expect(overviewPin).toHaveAttribute("data-heading", "true");
  const endX = await screenX();
  await refresh();
  await expect(overviewPin).toHaveAttribute("data-motion", "settled");
  expect(await screenX()).toBe(endX);
  // A delivered old sample must never look like current travel.
  nextFix(77.202, true);
  await refresh();
  await expect(overviewPin).toHaveAttribute("data-motion", "settled");
  await expect(overviewPin).toHaveAttribute("data-heading", "false");
  nextFix(77.2005);
  await refresh();
  // The first new point after a gap snaps; subsequent fresh fixes can glide again.
  await expect(overviewPin).toHaveAttribute("data-motion", "settled");
  await page.emulateMedia({ reducedMotion: "reduce" });
  nextFix(77.2008);
  await refresh();
  await expect(overviewPin).toHaveAttribute("data-motion", "settled");
  await page.emulateMedia({ reducedMotion: "no-preference" });
  await page
    .getByRole("textbox", { name: "Search scheduled employees" })
    .fill("No match");
  await expect(
    page.getByText("No matching employees", { exact: true }),
  ).toBeVisible();
  await expect(page.locator(".duty-map-pin")).toHaveCount(0);
  await page
    .getByRole("textbox", { name: "Search scheduled employees" })
    .clear();
  await page
    .getByRole("heading", { name: "Live tracking", exact: true })
    .click();
  await expect
    .poll(() =>
      page
        .locator(".leaflet-tile-loaded")
        .first()
        .evaluate((e) => getComputedStyle(e).opacity),
    )
    .toBe("1");
  await page.screenshot({
    path: "docs/evidence/tracking-motion/desktop.png",
    fullPage: false,
  });
  await page.getByRole("button", { name: /Arjun Mehta.*open route/ }).click();
  await expect(
    page.getByRole("region", { name: /Received duty positions/ }),
  ).toBeVisible();
  const routePin = page.getByRole("dialog").locator(".duty-map-head");
  await expect(routePin).toHaveAttribute("data-motion", "settled");
  nextFix(77.2013);
  await refresh("Refresh route");
  await expect(routePin).toHaveAttribute("data-motion", "gliding");
  await page.screenshot({
    path: "docs/evidence/tracking-motion/gliding.png",
    fullPage: false,
  });
  await expect(routePin).toHaveAttribute("data-motion", "settled");
  await expect(routePin).toHaveAttribute("data-heading", "true");
  await page.setViewportSize({ width: 390, height: 844 });
  nextFix(77.2006);
  await refresh("Refresh route");
  await expect(routePin).toHaveAttribute("data-motion", "gliding");
  await page.emulateMedia({ reducedMotion: "reduce" });
  await expect(routePin).toHaveAttribute("data-motion", "settled");
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBe(true);
  await page.emulateMedia({ reducedMotion: "no-preference" });
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.getByRole("button", { name: "Follow latest" }).click();
  await expect(
    page.getByRole("button", { name: "Follow latest" }),
  ).toHaveAttribute("aria-pressed", "true");
  await page
    .getByRole("dialog")
    .getByRole("button", { name: "Fit locations" })
    .click();
  await expect(
    page.getByRole("button", { name: "Follow latest" }),
  ).toHaveAttribute("aria-pressed", "false");
  await expect
    .poll(() =>
      page
        .getByRole("dialog")
        .locator(".leaflet-tile-loaded")
        .first()
        .evaluate((e) => getComputedStyle(e).opacity),
    )
    .toBe("1");
  await page.screenshot({
    path: "docs/evidence/tracking-motion/route.png",
    fullPage: false,
  });
  nextFix(77.2008);
  await refresh("Refresh route");
  await expect(routePin).toHaveAttribute("data-motion", "gliding");
  // Unmount an active animation; no queued frame may touch the removed map.
  await page.keyboard.press("Escape");
  if (!process.env.REAL_MAP_TILES) {
    failTiles = true;
    await page.getByRole("button", { name: "View route" }).click();
    await page
      .getByRole("dialog")
      .getByRole("button", { name: "Zoom in", exact: true })
      .click();
    await expect(
      page.getByRole("status").filter({ hasText: "Basemap unavailable" }),
    ).toBeVisible();
    await expect(
      page
        .getByRole("region", { name: /Received duty positions/ })
        .locator("svg path")
        .first(),
    ).toBeVisible();
    failTiles = false;
    await page.getByRole("button", { name: "Retry basemap" }).click();
    await expect(
      page.getByRole("dialog").locator(".leaflet-tile-loaded").first(),
    ).toBeVisible();
    await expect(page.getByText(/Basemap unavailable/)).toHaveCount(0);
    await page.keyboard.press("Escape");
  }
  await page.getByRole("button", { name: "Tracking settings" }).click();
  await page
    .getByLabel("Enable automatic sharing for assigned duty windows")
    .uncheck();
  await page
    .getByLabel("Reason for this change")
    .fill("Synthetic settings save validation");
  await page.getByRole("button", { name: "Save tracking settings" }).click();
  await expect(
    page.getByText("Duty sharing is disabled", { exact: true }),
  ).toBeVisible();
  expect(commands[0].input.mode).toBe("roster");
  expect(commands[0].siteId).toBe("dg");
  fail = true;
  await refresh();
  await expect(page.getByRole("alert")).toContainText(
    "Live refresh is interrupted",
  );
  fail = false;
  await page.getByRole("button", { name: "Retry", exact: true }).click();
  await expect(page.getByRole("alert")).toHaveCount(0);
  await page.setViewportSize({ width: 390, height: 844 });
  await page.screenshot({
    path: "docs/evidence/tracking-motion/mobile-web.png",
    fullPage: true,
  });
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBe(true);
  await page.setViewportSize({ width: 1440, height: 900 });
  // Simulate a new authorized policy snapshot, then switch site mid-flight.
  enabled = true;
  nextFix(77.2009);
  await refresh();
  nextFix(77.2012);
  await refresh();
  await expect(overviewPin).toHaveAttribute("data-motion", "gliding");
  await page.getByRole("button", { name: "Select site", exact: true }).click();
  await page.getByRole("option", { name: "River Green" }).click();
  await expect(
    page.getByText("No scheduled employees", { exact: true }),
  ).toBeVisible();
  await expect(
    page.getByText("Arjun Mehta · Synthetic", { exact: true }),
  ).toHaveCount(0);
  await expect(page.locator(".duty-map-pin")).toHaveCount(0);
  await page.emulateMedia({ reducedMotion: "reduce" });
  expect(
    await page
      .locator(".tracking-page")
      .evaluate((e) => getComputedStyle(e).animationName),
  ).toBe("none");
  expect(errors).toEqual([]);
});
