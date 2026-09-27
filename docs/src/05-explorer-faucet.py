from diagram import Diagram

d = Diagram("05-explorer-faucet", 440, "Blockscout explorer and faucet on potato-chain",
            "Browser hits an nginx proxy that routes to the Blockscout frontend and backend. The backend indexer "
            "reads node0 over JSON-RPC inside the potato-net docker network and stores data in postgres and "
            "redis. A faucet script sends POTATO through node0 JSON-RPC.")

d.box(160, 30, 150, 50, "Browser", "localhost:80")
d.line(235, 82, 235, 108)

d.frame(40, 92, 390, 293)
d.text(52, 377, "blockscout (docker compose)")
d.box(150, 110, 170, 50, "nginx proxy", "/ และ /api", ramp="purple")
d.line(235, 162, 235, 180, arrow=False)
d.line(140, 180, 330, 180, arrow=False)
d.line(140, 180, 140, 198)
d.line(330, 180, 330, 198)
d.box(60, 200, 160, 52, "frontend", "Next.js :3000", ramp="purple")
d.box(250, 200, 160, 52, "backend", "indexer + API :4000", ramp="purple")
d.line(330, 254, 330, 276, arrow=False)
d.line(235, 276, 360, 276, arrow=False)
d.line(235, 276, 235, 298)
d.line(360, 276, 360, 298)
d.box(180, 300, 110, 50, "postgres", "ข้อมูลที่ index", ramp="purple")
d.box(310, 300, 100, 50, "redis", "cache", ramp="purple")

d.box(480, 30, 140, 50, "faucet.sh", "cast send")
d.line(550, 82, 550, 198)
d.frame(460, 170, 180, 215)
d.text(472, 377, "potato-net")
d.line(412, 226, 476, 226, color="#1D9E75")
d.text(444, 217, "RPC", anchor="middle")
d.box(480, 200, 140, 52, "node0", ":8545  ws :8546", ramp="teal")
d.line(550, 254, 550, 298, color="#1D9E75", dash="3 3")
d.box(480, 300, 140, 50, "node1..3", "validators", ramp="teal")

d.box(40, 406, 14, 14, "", ramp="purple", small=True)
d.text(62, 418, "ชิ้นใหม่รอบนี้")
d.box(170, 406, 14, 14, "", ramp="teal", small=True)
d.text(192, 418, "เชนที่มีอยู่แล้ว")

if __name__ == "__main__":
    d.main()
