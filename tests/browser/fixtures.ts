import { test as base, expect, type Page } from "@playwright/test";
// The suite reuses synthetic accounts. Respect the production per-actor limit
// between accelerated journeys instead of disabling security for browser tests.
let nextJourneyAt = 0;
export const test = base.extend<{ accountBudget: void }>({
  accountBudget: [
    async ({ page }, use) => {
      const delay = nextJourneyAt - Date.now();
      if (delay > 0) await new Promise((resolve) => setTimeout(resolve, delay));
      page.on("response", (response) => {
        if (new URL(response.url()).pathname !== "/graphql") return;
        const headers = response.headers();
        const remaining = Number(headers["x-ratelimit-remaining"]);
        const reset = Number(headers["x-ratelimit-reset"]);
        if (
          Number.isFinite(remaining) &&
          remaining < 90 &&
          reset > 0 &&
          reset <= 60
        ) {
          nextJourneyAt = Math.max(
            nextJourneyAt,
            Date.now() + reset * 1000 + 250,
          );
        }
        if (response.status() === 429)
          console.log(
            "Browser journey reached the real API rate limit; Retry-After must be respected.",
          );
      });
      await use();
    },
    { auto: true, timeout: 70000 },
  ],
});
export { expect, type Page };
