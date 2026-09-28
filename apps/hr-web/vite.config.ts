import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
// Local API target; override (e.g. DG_API_PROXY=http://127.0.0.1:4100) for an isolated QA API.
const api = process.env.DG_API_PROXY ?? "http://127.0.0.1:4000";
export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: { alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) } },
  server: {
    port: 5180,
    strictPort: true,
    proxy: {
      "/payroll": api,
      "/dwr": api,
      "/files": api,
      "/profile": api,
      "/analytics": api,
      "/auth": api,
      "/graphql": api,
      "/health": api,
    },
  },
});
