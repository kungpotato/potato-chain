import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { faucet } from "./faucet-plugin.ts";

export default defineConfig({
  plugins: [react(), faucet(process.env.VITE_RPC_URL ?? "http://localhost:8545")],
  // deployments/localnet.json lives in the repo root, outside web/
  server: { port: 5173, fs: { allow: [".."] } },
});
