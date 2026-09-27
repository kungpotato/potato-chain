from diagram import Diagram

d = Diagram("13-frontend", 520, "potato-chain dApp frontend architecture",
            "A Vite React app uses wagmi and viem with a potato chain definition and addresses from deployments json. "
            "Pages cover swap, bridge, lending and faucet. Wallets are MetaMask via the injected connector, a "
            "dev-only burner wallet, and Keplr for the Cosmos view. Reads and writes go to node0 JSON-RPC, prices "
            "and swap history come from Ponder GraphQL, and the faucet calls a Vite dev-server endpoint that holds "
            "the dev key server side, never in the browser bundle.")

d.frame(40, 20, 600, 250)
d.text(52, 40, "browser: Vite + React (web/)")
for i, (t, s) in enumerate([("Swap", "Router02"), ("Bridge", "PotatoBridge"),
                            ("Lend", "Morpho"), ("Faucet", "ขอ POTATO")]):
    d.box(55 + i * 145, 55, 135, 50, t, s, ramp="purple")
d.line(340, 107, 340, 129)
d.box(170, 131, 340, 50, "wagmi + viem", "chain potato 707070 · deployments.json", ramp="purple")
d.line(340, 183, 340, 200, arrow=False)
d.line(125, 200, 555, 200, arrow=False)
for x in (125, 340, 555):
    d.line(x, 200, x, 212)
d.box(55, 214, 140, 44, "MetaMask", ramp="gray", small=True)
d.box(250, 214, 180, 44, "burner (dev only)", ramp="coral", small=True)
d.box(485, 214, 140, 44, "Keplr (cosmos)", ramp="gray", small=True)

d.line(125, 260, 125, 318)
d.line(340, 260, 340, 280, arrow=False)
d.line(340, 280, 180, 280, arrow=False)
d.line(180, 280, 180, 318)
d.box(40, 320, 200, 52, "node0 JSON-RPC", ":8545 read + write", ramp="teal")
d.box(260, 320, 170, 52, "Ponder GraphQL", "fetch ราคา, swaps", ramp="teal")
d.line(555, 260, 555, 318)
d.box(450, 320, 190, 52, "node0 REST/RPC", ":1317 / :26657", ramp="teal")

d.box(260, 420, 380, 56, "vite dev server: POST /api/faucet", "dev0 key อยู่ฝั่ง Node เท่านั้น ไม่เข้า bundle", ramp="coral")
d.line(600, 107, 600, 118, arrow=False)
d.line(600, 118, 650, 118, arrow=False)
d.line(650, 118, 650, 448, arrow=False)
d.line(650, 448, 642, 448)
d.line(258, 448, 140, 448, arrow=False)
d.line(140, 448, 140, 374)

d.box(40, 490, 14, 14, "", ramp="purple", small=True)
d.text(62, 502, "โค้ดใหม่")
d.box(150, 490, 14, 14, "", ramp="teal", small=True)
d.text(172, 502, "มีอยู่แล้ว")
d.box(270, 490, 14, 14, "", ramp="coral", small=True)
d.text(292, 502, "dev only / ความปลอดภัย")

if __name__ == "__main__":
    d.main()
