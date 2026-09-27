# potato-chain

EVM-compatible Cosmos appchain for learning, built block by block on top of
[`cosmos/evm`](https://github.com/cosmos/evm) (pinned: **v0.7.3**).

## Lego roadmap (devnet goal)

| Week | Blocks | Status |
|------|--------|--------|
| 1 | ① Consensus (CometBFT) + ② Execution (Cosmos SDK + EVM) | done |
| 2 | ④ JSON-RPC, wallets (MetaMask/Keplr), explorer, faucet | done (Keplr pending) |
| 3 | ⑦ ⑧ Preinstalls, WETH-like token, mock USDC, DEX | done |
| 4-5 | ⑥ IBC/Hyperlane bridge, oracle, indexer | done (IBC w/ gaia; Hyperlane pending) |
| 6 | Lending, frontend, `x/gov` upgrade drill | — |

## Quickstart

```bash
scripts/local_node.sh          # fresh single-validator chain (~1s blocks)
scripts/local_node.sh --keep   # restart with existing data
```

4-validator localnet (docker, see `docs/03-localnet-docker.png`):

```bash
make localnet-init   # generate .localnet/node0..3 (keys + shared genesis)
make localnet-up     # build image + start 4 containers (node0 exposes RPC ports)
make localnet-down
```

Explorer + faucet (needs the localnet, see `docs/05-explorer-faucet.png`):

```bash
make explorer-up                          # Blockscout at http://localhost
scripts/faucet.sh <0x...|potato1...> 10   # send 10 POTATO from dev0 (max 100)
make smoke                                # end-to-end EVM check
```

DEX (week 3, see `docs/06-money-and-dex.png`):

```bash
make contracts-test   # forge tests (incl. Uniswap init code hash guard)
make deploy           # MockUSDC + UniswapV2Factory/Router02 -> deployments/localnet.json
make seed-pool        # first liquidity: 100 POTATO + 200 USDC (real chain, uses WPOTATO precompile)
make smoke-dex        # swap round trip on-chain
```

Indexer (weeks 4-5, see `docs/07-indexer.png`):

```bash
make indexer-install && make indexer-dev   # Ponder -> http://localhost:42069/graphql
make smoke-indexer                         # swap on-chain, assert indexer == getReserves()
make deploy-oracle                         # POTATO/USD mock feed (Chainlink ABI), see docs/08-oracle.png
scripts/oracle_push.sh 2.15                # push a price (dev stand-in for a keeper)
```

IBC with gaia-local (see `docs/09-ibc-transfer.png`):

```bash
make ibc-up && make hermes-keys && make ibc-channel   # one-time: gaia + relayer keys + channel-0
make relayer                                          # Hermes (keep running)
make smoke-ibc                                        # 1 POTATO potato-1 -> gaia -> back
```

| Identity | Value |
|---|---|
| Cosmos chain-id | `potato-1` |
| EVM chain id | `707070` |
| Denom | `apotato` (18 decimals) → `POTATO` |
| Address prefix | `potato1...` |
| JSON-RPC | `http://localhost:8545` |

Workflow: trunk-based, small batches, every commit builds (Accelerate).
