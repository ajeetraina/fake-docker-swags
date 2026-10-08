import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Binds to 0.0.0.0 so the dev/preview server is reachable from the host
// after `sbx ports ... --publish`. Inside a sandbox, 127.0.0.1 would be
// invisible to the host proxy.
export default defineConfig({
  plugins: [react()],
  server: { host: "0.0.0.0", port: 3000 },
  preview: { host: "0.0.0.0", port: 3000 },
});
