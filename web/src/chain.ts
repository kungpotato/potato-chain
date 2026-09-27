import { defineChain, type Address } from "viem";
import deployments from "../../deployments/localnet.json";

// Single source of truth for addresses: written by contracts/script/*.s.sol
export const addr = deployments as unknown as {
  chainId: number;
  WPOTATO: Address;
  USDC: Address;
  UniswapV2Router02: Address;
  Pair_WPOTATO_USDC: Address;
  PotatoBridge: Address;
  Morpho: Address;
  PotatoOracle: Address;
  LinearIrm: Address;
  Market_WPOTATO_USDC: `0x${string}`;
};

export const RPC_URL = import.meta.env.VITE_RPC_URL ?? "http://localhost:8545";
export const INDEXER_URL = import.meta.env.VITE_INDEXER_URL ?? "http://localhost:42069";

export const potato = defineChain({
  id: addr.chainId, // 707070
  name: "Potato Localnet",
  nativeCurrency: { name: "Potato", symbol: "POTATO", decimals: 18 },
  rpcUrls: { default: { http: [RPC_URL] } },
  blockExplorers: { default: { name: "Blockscout", url: "http://localhost" } },
  contracts: { multicall3: { address: "0xcA11bde05977b3631167028862bE2a173976CA11" } }, // genesis preinstall
  testnet: true,
});
