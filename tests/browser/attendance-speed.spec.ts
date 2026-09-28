import { test, expect } from "./fixtures.js";
import { signIn } from "./redesign-helpers.js";
import { ids } from "../../packages/db/src/seed.js";
test("attendance loads only its dated query and filters by date and employee without resetting the controls", async ({
  page,
}) => {
  const db = new URL(process.env.MIGRATION_DATABASE_URL!);
  if (!["localhost", "127.0.0.1"].includes(db.hostname))
    throw Error("Local synthetic data only");
  await signIn(page, "superadmin@example.test", ids.superAdmin);
  const queries: string[] = [];
  page.on("request", (r) => {
    if (new URL(r.url()).pathname === "/graphql")
      queries.push(r.postData() ?? "");
  });
  await page.getByRole("link", { name: "Attendance", exact: true }).click();
  const date = page.getByLabel("Attendance date"),
    employee = page.getByLabel("Attendance employee");
  await expect(date).toBeVisible();
  await expect(employee).toBeVisible();
  await expect(page.getByText("Loading attendance…")).toHaveCount(0);
  const chosen = await employee.locator("option").nth(1).getAttribute("value");
  await employee.selectOption(chosen!);
  await date.fill("2026-09-28");
  await expect
    .poll(() =>
      queries.some((q) => {
        const p = JSON.parse(q);
        return (
          p.query.includes("AttendanceDay") &&
          p.variables.workDate === "2026-09-28" &&
          p.variables.employeeId === chosen
        );
      }),
    )
    .toBe(true);
  await expect(date).toHaveValue("2026-09-28");
  await expect(employee).toHaveValue(chosen!);
  expect(
    queries.some((q) => /query Operations\(/.test(JSON.parse(q).query)),
  ).toBe(false);
  expect(
    queries.some((q) => /query Employees\(/.test(JSON.parse(q).query)),
  ).toBe(false);
});

test("DWR chat skips report snapshots and keeps the thread through a workspace refresh", async ({
  page,
}) => {
  await signIn(page, "hr@example.test", ids.admin);
  const queries: any[] = [];
  page.on("request", (r) => {
    if (new URL(r.url()).pathname === "/graphql")
      queries.push(JSON.parse(r.postData() ?? "{}"));
  });
  await page.goto("/#/dwr");
  await expect(
    page.getByRole("heading", { name: "Daily work reports" }),
  ).toBeVisible();
  await expect
    .poll(() => queries.some((q) => q.variables?.input?.view === "thread"))
    .toBe(true);
  const initial = queries.filter(
    (q) => q.variables?.input?.view === "thread" && !q.variables.input.since,
  ).length;
  await page.evaluate(() =>
    document.dispatchEvent(new Event("visibilitychange")),
  );
  await expect
    .poll(() => queries.some((q) => q.query?.includes("query Bootstrap")))
    .toBe(true);
  // Wait for the next change poll, which must use its retained cursor.
  await expect
    .poll(
      () =>
        queries.some(
          (q) =>
            q.variables?.input?.view === "thread" && q.variables.input.since,
        ),
      { timeout: 12000 },
    )
    .toBe(true);
  expect(
    queries.filter(
      (q) => q.variables?.input?.view === "thread" && !q.variables.input.since,
    ).length,
  ).toBe(initial);
  expect(queries.some((q) => /query Dwr\(/.test(q.query ?? ""))).toBe(false);
});
