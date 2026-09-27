// DEV ONLY faucet: POST /api/faucet {"address":"0x..."} -> 10 POTATO from dev0.
// Runs inside the Vite *dev server* (Node); the key comes from POTATO_FAUCET_KEY and never
// reaches the browser bundle. `apply: "serve"` keeps it out of production builds entirely.
import type { Plugin } from "vite";
import { createWalletClient, http, isAddress, parseEther, type Hex } from "viem";
import { privateKeyToAccount } from "viem/accounts";

const AMOUNT = parseEther("10");
const COOLDOWN_MS = 30_000;

export function faucet(rpcUrl: string): Plugin {
  const last = new Map<string, number>();
  return {
    name: "potato-dev-faucet",
    apply: "serve",
    configureServer(server) {
      const key = process.env.POTATO_FAUCET_KEY as Hex | undefined;
      if (!key) {
        server.config.logger.warn("[faucet] POTATO_FAUCET_KEY not set: /api/faucet disabled");
        return;
      }
      const account = privateKeyToAccount(key);
      const wallet = createWalletClient({ account, transport: http(rpcUrl) });

      server.middlewares.use("/api/faucet", (req, res) => {
        const reply = (code: number, body: object) => {
          res.statusCode = code;
          res.setHeader("content-type", "application/json");
          res.end(JSON.stringify(body));
        };
        if (req.method !== "POST") return reply(405, { error: "POST only" });
        let raw = "";
        req.on("data", (c) => (raw += c));
        req.on("end", async () => {
          try {
            const { address } = JSON.parse(raw || "{}");
            if (!isAddress(address)) return reply(400, { error: "invalid address" });
            const k = address.toLowerCase();
            const wait = (last.get(k) ?? 0) + COOLDOWN_MS - Date.now();
            if (wait > 0) return reply(429, { error: `cooldown: retry in ${Math.ceil(wait / 1000)}s` });
            last.set(k, Date.now());
            const hash = await wallet.sendTransaction({ to: address, value: AMOUNT, chain: null });
            reply(200, { hash, amount: "10" });
          } catch (e) {
            reply(500, { error: (e as Error).message.split("\n")[0] });
          }
        });
      });
    },
  };
}
