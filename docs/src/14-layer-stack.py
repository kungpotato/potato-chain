from diagram import Diagram

d = Diagram("14-layer-stack", 580, "potato-chain layer stack",
            "Eight stacked layers from bottom to top: local infra (Docker localnet, gaia-local, scripts), "
            "CometBFT consensus, the Cosmos SDK app potatod, the cosmos/evm engine, Solidity contracts, "
            "the node APIs, off-chain services (Blockscout, Ponder, Hermes, oracle and faucet), and the "
            "React frontend with wallets. Each layer uses the one below it.")

LAYERS = [  # top -> bottom: (label, note, ramp, chips)
    ("L8 Frontend", "หน้าเว็บ + wallet", "purple",
     [("React+wagmi", "web/ :5173"), ("MetaMask", "EVM wallet"), ("Keplr", "Cosmos wallet"), ("Burner", "dev only")]),
    ("L7 Off-chain", "บริการรอบ chain", "purple",
     [("Blockscout", "explorer"), ("Ponder", "indexer GraphQL"), ("Hermes", "IBC relayer"), ("Oracle push", "+ faucet")]),
    ("L6 API", "ประตูเข้า node", "teal",
     [("JSON-RPC", ":8545 EVM"), ("CometBFT RPC", ":26657"), ("REST", ":1317"), ("gRPC", ":9090")]),
    ("L5 Contracts", "Solidity · Foundry", "teal",
     [("Uniswap v2", "DEX + router"), ("Morpho Blue", "lending"), ("PotatoBridge", "IBC ICS-20"), ("MockUSDC", "+ price oracle")]),
    ("L4 EVM engine", "cosmos/evm v0.7.3", "teal",
     [("x/vm", "EVM state"), ("feemarket", "EIP-1559"), ("Precompiles", "WPOTATO, ICS-20"), ("Mempool", "EVM tx pool")]),
    ("L3 SDK app", "potatod · potato-1", "teal",
     [("bank/staking", "account, stake"), ("gov/upgrade", "potato-v2"), ("IBC core", "+ transfer"), ("mint/distr", "slashing ...")]),
    ("L2 Consensus", "CometBFT", "teal",
     [("4 validators", "node0 - node3"), ("BFT ≥ 2/3", "ทน 1 node ล่ม"), ("P2P gossip", ":26656"), ("ABCI", "↔ SDK app")]),
    ("L1 Infra", "รันบนเครื่อง", "amber",
     [("Docker", "localnet 4 node"), ("gaia-local", "chain ปลายทาง"), ("Scripts", "smoke tests"), ("Makefile", "build potatod")]),
]

Y0, STEP, H = 16, 66, 56
for i, (label, note, ramp, chips) in enumerate(LAYERS):
    y = Y0 + i * STEP
    d.box(12, y, 590, H, "", ramp="gray")
    d.text(24, y + 25, label, cls="th", color="#444441")
    d.text(24, y + 43, note)
    for j, (t, s) in enumerate(chips):
        d.box(152 + j * 111, y + 8, 103, 40, t, s, ramp=ramp)

# right-side brackets: which layers live where
for top, bot, lines in [(0, 1, ["off-chain"]), (2, 6, ["on-chain", "potatod"]), (7, 7, ["infra"])]:
    y1, y2 = Y0 + top * STEP + 4, Y0 + bot * STEP + H - 4
    d.line(610, y1, 616, y1, arrow=False)
    d.line(616, y1, 616, y2, arrow=False)
    d.line(610, y2, 616, y2, arrow=False)
    mid = (y1 + y2) / 2 - (len(lines) - 1) * 8
    for k, s in enumerate(lines):
        d.text(622, mid + 4 + k * 16, s)

ly = Y0 + 8 * STEP + 6
d.box(12, ly, 14, 14, "", ramp="purple", small=True)
d.text(32, ly + 12, "off-chain / ผู้ใช้")
d.box(150, ly, 14, 14, "", ramp="teal", small=True)
d.text(170, ly + 12, "on-chain node")
d.box(275, ly, 14, 14, "", ramp="amber", small=True)
d.text(295, ly + 12, "infra")
d.text(602, ly + 12, "ชั้นบนเรียกใช้ชั้นล่าง ↓", anchor="end")

if __name__ == "__main__":
    d.main()
