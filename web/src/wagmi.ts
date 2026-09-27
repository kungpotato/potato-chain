import { createConfig, http, injected } from "wagmi";
import { potato, RPC_URL } from "./chain";
import { burnerProvider } from "./burner";

const connectors = [injected()]; // MetaMask & other browser wallets
if (import.meta.env.VITE_DEV_BURNER === "1") {
  connectors.push(
    injected({ target: { id: "burner", name: "Burner (dev)", provider: burnerProvider() as never } }),
  );
}

export const config = createConfig({
  chains: [potato],
  connectors,
  transports: { [potato.id]: http(RPC_URL) },
});

declare module "wagmi" {
  interface Register {
    config: typeof config;
  }
}
