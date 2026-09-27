from diagram import Diagram

d = Diagram("00-layers", 670, "potato-chain layers: infra, on chain, off chain",
            "Infra: docker compose, four validator nodes where node0 also serves RPC, DevOps scripts; sentry nodes "
            "and CI are missing. On chain inside one potatod binary: CometBFT, app-side EVM mempool and API servers, "
            "then over ABCI the Cosmos SDK app with SDK modules, ibc-go and cosmos/evm modules, whose EVM hosts "
            "precompiles and smart contracts. Off chain: frontend, wallets, Blockscout and Ponder, Hermes, oracle "
            "and faucet scripts, and the gaia-local counterparty chain.")

# ---- Infra ----
d.frame(20, 20, 640, 100)
d.text(32, 40, "Infra", cls="th", color="#2C2C2A")
d.box(32, 52, 145, 52, "Docker compose", "4 val + gaia + explorer")
d.box(187, 52, 145, 52, "Validator ×4", "node0 = RPC ด้วย")
d.box(342, 52, 145, 52, "DevOps", "Makefile · scripts")
d.box(497, 52, 150, 52, "ยังไม่มี", "sentry/RPC แยก · CI", ramp="coral")

# ---- On chain ----
d.frame(20, 140, 640, 300)
d.text(32, 160, "On chain · potatod (binary เดียว)", cls="th", color="#2C2C2A")
d.box(32, 172, 220, 52, "CometBFT", "P2P · validators · BFT ≥ ⅔")
d.box(264, 172, 180, 52, "Mempool (app-side)", "EVM mempool", ramp="purple")
d.box(456, 172, 186, 52, "API servers", "JSON-RPC · gRPC · REST", ramp="purple")
d.line(142, 226, 142, 256)
d.text(152, 245, "ABCI")

d.frame(32, 258, 610, 170, dash="3 3")
d.text(44, 276, "Application: Cosmos SDK app (state machine)")
d.box(44, 286, 196, 52, "Cosmos SDK modules", "bank·auth·staking·gov·upgrade")
d.box(250, 286, 176, 52, "ibc-go (แยกจาก SDK)", "client·conn·chan·transfer", ramp="purple")
d.box(436, 286, 196, 52, "cosmos/evm modules", "x/vm · x/erc20 · feemarket")
d.line(534, 340, 534, 352, arrow=False)
d.line(316, 352, 536, 352, arrow=False)
d.line(316, 352, 316, 364)
d.line(536, 352, 536, 364)
d.box(206, 366, 220, 52, "Precompiles", "WERC20 0xEeee · ICS-20 0x0802", ramp="purple")
d.box(436, 366, 200, 52, "Smart contracts", "Uniswap·Morpho·Oracle·Bridge")

# ---- Off chain ----
d.frame(20, 460, 640, 166)
d.text(32, 480, "Off chain", cls="th", color="#2C2C2A")
d.box(32, 492, 196, 52, "Frontend", "React + wagmi (web/)")
d.box(240, 492, 196, 52, "Wallets", "MetaMask · Keplr · burner", ramp="purple")
d.box(448, 492, 194, 52, "Data", "Blockscout · Ponder")
d.box(32, 558, 196, 52, "Hermes relayer", "IBC packets")
d.box(240, 558, 196, 52, "oracle_push · faucet", "scripts + /api/faucet")
d.box(448, 558, 194, 52, "gaia-local", "อีกเชน (counterparty)", ramp="purple")

# ---- legend ----
d.box(20, 642, 14, 14, "", small=True)
d.text(42, 654, "ตรงกับภาพเดิม")
d.box(160, 642, 14, 14, "", ramp="purple", small=True)
d.text(182, 654, "เพิ่ม / แก้จากภาพเดิม")
d.box(340, 642, 14, 14, "", ramp="coral", small=True)
d.text(362, 654, "ยังไม่มีในโปรเจกต์")

if __name__ == "__main__":
    d.main()
