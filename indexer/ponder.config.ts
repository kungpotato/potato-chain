import { readFileSync } from "node:fs";
import { createConfig } from "ponder";
import type { Address } from "viem";

import { UniswapV2PairAbi } from "./abis/UniswapV2PairAbi";

// Single source of truth for addresses + startBlock: written by contracts/script/Deploy.s.sol
const network = process.env.NETWORK ?? "localnet";
export const deployments = JSON.parse(
  readFileSync(new URL(`../deployments/${network}.json`, import.meta.url), "utf8"),
) as {
  chainId: number;
  startBlock: number;
  WPOTATO: Address;
  USDC: Address;
  Pair_WPOTATO_USDC: Address;
};

if (!deployments.startBlock) {
  // docs/known-issues.md: eth_getLogs with fromBlock=0 double-counts the tip block on cosmos/evm v0.7.3
  throw new Error("deployments.startBlock must be > 0");
}

export default createConfig({
  chains: {
    potato: {
      id: deployments.chainId,
      rpc: process.env.PONDER_RPC_URL_707070 ?? "http://localhost:8545",
      pollingInterval: 1_000, // ~1s blocks
    },
  },
  contracts: {
    Pair: {
      chain: "potato",
      abi: UniswapV2PairAbi,
      address: deployments.Pair_WPOTATO_USDC,
      startBlock: deployments.startBlock,
    },
  },
});
