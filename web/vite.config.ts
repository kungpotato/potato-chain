import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  // deployments/localnet.json lives in the repo root, outside web/
  server: { port: 5173, fs: { allow: [".."] } },
});
