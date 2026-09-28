import { defineConfig } from "@playwright/test";
export default defineConfig({
  testDir: "tests/browser",
  workers: 1,
  timeout: 60_000,
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL ?? "http://localhost:5180",
    headless: true,
    channel: "chrome",
    trace: "off",
    screenshot: "off",
    video: "off",
  },
  reporter: "list",
});
