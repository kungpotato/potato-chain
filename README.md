# potato-chain

EVM-compatible Cosmos appchain for learning, built block by block on top of
[`cosmos/evm`](https://github.com/cosmos/evm) (pinned: **v0.7.3**).

## Lego roadmap (devnet goal)

| Week | Blocks | Status |
|------|--------|--------|
| 1 | ① Consensus (CometBFT) + ② Execution (Cosmos SDK + EVM) | in progress |
| 2 | ④ JSON-RPC, wallets (MetaMask/Keplr), explorer, faucet | — |
| 3 | ⑦ ⑧ Preinstalls, WETH-like token, mock USDC, DEX | — |
| 4-5 | ⑥ IBC/Hyperlane bridge, oracle, indexer | — |
| 6 | Lending, frontend, `x/gov` upgrade drill | — |

## Quickstart

```bash
scripts/local_node.sh          # fresh single-validator chain (~1s blocks)
scripts/local_node.sh --keep   # restart with existing data
```

| Identity | Value |
|---|---|
| Cosmos chain-id | `potato-1` |
| EVM chain id | `707070` |
| Denom | `apotato` (18 decimals) → `POTATO` |
| Address prefix | `potato1...` |
| JSON-RPC | `http://localhost:8545` |

Workflow: trunk-based, small batches, every commit builds (Accelerate).
