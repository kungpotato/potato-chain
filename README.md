# potato-chain 🥔

> An EVM-compatible Cosmos appchain built block by block on top of [`cosmos/evm`](https://github.com/cosmos/evm) (pinned to **v0.7.3**) and CometBFT consensus.

![High-level Architecture](docs/01-high-level-architecture.png)

---

## ⚡ Chain Identity

| Parameter | Value |
|---|---|
| **Cosmos Chain ID** | `potato-1` |
| **EVM Chain ID** | `707070` |
| **Native Denom** | `apotato` (18 decimals) → `POTATO` |
| **Bech32 Prefix** | `potato1...` |
| **JSON-RPC Endpoint** | `http://localhost:8545` |
| **CometBFT RPC** | `http://localhost:26657` |
| **Cosmos REST** | `http://localhost:1317` |
| **gRPC Endpoint** | `localhost:9090` |

---

## 🗺️ Completed Lego Roadmap

| Week | Milestone & Modules | Status |
|:---:|---|:---:|
| **1** | ① CometBFT Consensus (4-validator localnet) + ② Cosmos SDK Execution + EVM Engine | ✅ Completed |
| **2** | ④ JSON-RPC, Blockscout Explorer, Dev Faucet, Keplr / MetaMask integration | ✅ Completed |
| **3** | ⑦ ⑧ Precompiles (WPOTATO), MockUSDC, Uniswap v2 DEX & Factory | ✅ Completed |
| **4-5** | ⑥ IBC Cross-Chain Bridge with `gaia-local` (Hermes relayer, ICS-20 precompile), Ponder Indexer, Price Oracle | ✅ Completed |
| **6** | ⑪ Morpho Blue Lending, React + Wagmi Frontend, `x/gov` Software Upgrade Drill (`potato-v2`) | ✅ Completed |

---

## 🎬 Visual Demos & Showcase

### 1. Web Application (`/web`)
Modern decentralized web application built with **React**, **Vite**, **wagmi 3**, **viem 2**, and **TailwindCSS**. Features embedded burner wallet, dev faucet, and full protocol integration.

![Frontend Overview](docs/media/web-overview.png)

<table width="100%">
  <tr>
    <td width="50%" align="center">
      <b>Faucet & DEX Swap (Ponder Real-Time Sync)</b><br/>
      <img src="docs/media/web-faucet-swap.gif" alt="Faucet and Swap Demo" />
    </td>
    <td width="50%" align="center">
      <b>Morpho Blue Lending (Deposit & Borrow)</b><br/>
      <img src="docs/media/web-lend.gif" alt="Lending Demo" />
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <b>IBC Cross-Chain Bridge (PotatoBridge to Gaia Cosmos Hub)</b><br/>
      <img src="docs/media/web-bridge.gif" alt="IBC Bridge Demo" width="70%" />
    </td>
  </tr>
</table>

---

### 2. Blockscout Explorer & Ponder GraphQL Indexer

<table width="100%">
  <tr>
    <td width="50%" align="center">
      <b>Blockscout Homepage (Live Blocks & Transactions)</b><br/>
      <img src="docs/media/explorer-home.png" alt="Blockscout Homepage" />
    </td>
    <td width="50%" align="center">
      <b>DEX Swap Transaction Details (Clean View)</b><br/>
      <img src="docs/media/explorer-swap-tx.png" alt="Swap Transaction Details" />
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <b>Uniswap V2 Pair (WPOTATO / USDC) Token Transfers</b><br/>
      <img src="docs/media/explorer-pool.png" alt="Pool Token Transfers" />
    </td>
    <td width="50%" align="center">
      <b>WPOTATO ERC-20 Precompile Token Page</b><br/>
      <img src="docs/media/explorer-wpotato.png" alt="WPOTATO Token Page" />
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <b>Ponder GraphQL Interface (Executed Query on Pools & Recent Swaps)</b><br/>
      <img src="docs/media/ponder-graphql.png" alt="Ponder GraphQL Demo" width="70%" />
    </td>
  </tr>
</table>

---

### 3. Core Engine & Terminal Execution Demos

<table width="100%">
  <tr>
    <td width="50%" align="center">
      <b>EVM JSON-RPC & Precompiles Smoke Test</b><br/>
      <img src="docs/media/cli-smoke.gif" alt="Smoke Test Demo" />
    </td>
    <td width="50%" align="center">
      <b>Foundry Smart Contracts Suite (22/22 Passed)</b><br/>
      <img src="docs/media/cli-forge.gif" alt="Forge Test Demo" />
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <b>CometBFT Fault Tolerance (Stopping Node 3, Consensus Continues)</b><br/>
      <img src="docs/media/cli-bft.gif" alt="BFT Fault Tolerance Demo" />
    </td>
    <td width="50%" align="center">
      <b>IBC Round-Trip Relay (Potato ↔ Gaia)</b><br/>
      <img src="docs/media/cli-ibc.gif" alt="IBC Smoke Test Demo" />
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <b>On-Chain DEX Swap (Uniswap V2 & WPOTATO)</b><br/>
      <img src="docs/media/cli-dex.gif" alt="DEX Smoke Demo" />
    </td>
    <td width="50%" align="center">
      <b>On-Chain Morpho Blue Lending & Liquidation</b><br/>
      <img src="docs/media/cli-lending.gif" alt="Lending Smoke Demo" />
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <b>Governance Software Upgrade Drill (<code>potato-v2</code> Block Gas 10M → 30M)</b><br/>
      <i>(Recorded execution from the live upgrade drill)</i><br/>
      <img src="docs/media/cli-upgrade.gif" alt="Upgrade Drill Demo" width="70%" />
    </td>
  </tr>
</table>

---

## 🛠️ Architecture Diagrams

| Subsystem | Sequence / Architecture Diagram |
|---|---|
| **Consensus & Localnet** | ![Localnet Docker](docs/03-localnet-docker.png) |
| **EVM Transaction Lifecycle** | ![EVM Lifecycle](docs/04-evm-tx-lifecycle.png) |
| **Explorer & Faucet** | ![Explorer & Faucet](docs/05-explorer-faucet.png) |
| **Money & DEX (Uniswap v2)** | ![DEX](docs/06-money-and-dex.png) |
| **Indexer (Ponder)** | ![Indexer](docs/07-indexer.png) |
| **Oracle Feed** | ![Oracle](docs/08-oracle.png) |
| **IBC Cross-Chain Bridge** | ![IBC Transfer](docs/09-ibc-transfer.png) |
| **ICS-20 EVM Precompile** | ![ICS-20 Precompile](docs/10-ics20-precompile.png) |
| **Lending (Morpho Blue)** | ![Morpho Blue](docs/11-lending-morpho.png) |
| **Governance Upgrade** | ![Gov Upgrade](docs/12-gov-upgrade.png) |
| **Frontend Web App** | ![Frontend](docs/13-frontend.png) |

---

## 🚀 Quickstart & Makefile Commands

### 1. 4-Validator Localnet
```bash
# Initialize node keys and shared genesis
make localnet-init

# Start 4 validator containers with Docker Compose
make localnet-up

# Tail logs
make localnet-logs

# Stop localnet
make localnet-down
```

### 2. Blockscout Explorer & Smoke Tests
```bash
# Start Blockscout explorer at http://localhost
make explorer-up

# Send 10 POTATO to any address
scripts/faucet.sh <0x...|potato1...> 10

# Run EVM end-to-end smoke test
make smoke
```

### 3. Smart Contracts & DEX
```bash
# Run Foundry test suite
make contracts-test

# Deploy MockUSDC & Uniswap v2 Factory/Router
make deploy

# Seed pool liquidity (100 POTATO + 200 USDC)
make seed-pool

# Run DEX smoke test (round-trip swap)
make smoke-dex
```

### 4. Ponder Indexer & Oracle
```bash
# Install and start Ponder indexer at http://localhost:42069/graphql
make indexer-install
make indexer-dev

# Deploy mock Chainlink POTATO/USD price feed
make deploy-oracle

# Push updated price feed
scripts/oracle_push.sh 2.15

# Verify indexer sync against on-chain pool reserves
make smoke-indexer
```

### 5. Cross-Chain IBC (Gaia Local + Hermes)
```bash
# Start Gaia local chain and install Hermes
make ibc-up

# Configure relayer keys and establish IBC transfer channel-0
make hermes-keys
make ibc-channel

# Run Hermes relayer
make relayer

# Deploy PotatoBridge contract (EVM-to-Cosmos bridge)
make deploy-bridge

# Run full IBC round-trip smoke test
make smoke-ibc
```

### 6. Morpho Blue Lending
```bash
# Deploy Morpho Blue, PotatoOracle adapter, Linear IRM, and initialize market
make deploy-lending

# Run lending smoke test (deposit collateral -> borrow -> price drop -> liquidation)
make smoke-lending
```

### 7. Governance Upgrade Drill
```bash
# Pre-stage next binary as potato-chain/potatod:v2
make upgrade-image

# Execute one-shot upgrade drill (propose -> vote -> halt at H -> swap container -> resume)
make upgrade-drill
```

### 8. Frontend Web App
```bash
# Install web dependencies
make web-install

# Run Vite dev server with dev burner wallet and local faucet endpoint
make web-dev
# Open http://localhost:5173
```

---

## 🔍 Upstream Quirks & Known Issues

During the development on `cosmos/evm` v0.7.3, several subtle upstream behaviors were identified and documented:
- **`eth_getLogs` with `fromBlock: 0`**: Duplicates the latest block's logs because CometBFT treats block 0 as `nil` (latest).
- **`eth_fillTransaction`**: Estimates gas against block 0 instead of the latest block in Viem local burner accounts.

Detailed root causes, reproductions, and workarounds are cataloged in [`docs/known-issues.md`](docs/known-issues.md).

---

## 📄 License

This project is licensed under the **Apache-2.0 License** (compatible with upstream `cosmos/evm`).
See [LICENSE](LICENSE) for details.
