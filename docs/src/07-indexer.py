from diagram import Diagram

d = Diagram("07-indexer", 510, "Ponder indexer for the WPOTATO/USDC pool",
            "The pair emits Swap, Sync, Mint and Burn events. Ponder's sync engine reads them from node0 JSON-RPC "
            "starting at the deploy block, not block 0, runs indexing functions that write pool and swap tables, "
            "and serves them over GraphQL and SQL on port 42069 for the frontend.")

d.box(40, 30, 190, 54, "Pair WPOTATO/USDC", "Swap · Sync · Mint · Burn", ramp="teal")
d.line(232, 57, 248, 57)
d.box(250, 30, 160, 54, "node0 JSON-RPC", ":8545", ramp="teal")
d.box(430, 30, 210, 54, "startBlock = deploy block", "ไม่ใช่ 0 (บั๊ก getLogs)", ramp="coral")

d.frame(40, 110, 600, 290)
d.text(52, 392, "indexer/ (Ponder 0.17, Node.js)")
d.line(330, 86, 330, 138)
d.box(250, 140, 160, 54, "sync engine", "getLogs + poll", ramp="purple")
d.line(535, 86, 535, 167, color="#D85A30", dash="4 3", arrow=False)
d.line(535, 167, 414, 167, color="#D85A30", dash="4 3")

d.line(330, 196, 330, 228)
d.box(250, 230, 160, 54, "indexing functions", "src/pool.ts", ramp="purple")
d.line(330, 286, 330, 300, arrow=False)
d.line(225, 300, 405, 300, arrow=False)
d.line(225, 300, 225, 316)
d.line(405, 300, 405, 316)
d.box(150, 318, 150, 52, "table pool", "reserves, price", ramp="purple")
d.box(330, 318, 150, 52, "table swap", "1 แถวต่อ swap", ramp="purple")

d.line(482, 344, 490, 344, arrow=False)
d.line(490, 344, 490, 257, arrow=False)
d.line(490, 257, 498, 257)
d.box(500, 230, 130, 54, "API :42069", "GraphQL / SQL", ramp="purple")
d.line(565, 286, 565, 418)
d.box(470, 420, 170, 52, "frontend / curl", "ราคา + volume")

d.box(40, 482, 14, 14, "", ramp="teal", small=True)
d.text(62, 494, "บนเชน")
d.box(140, 482, 14, 14, "", ramp="purple", small=True)
d.text(162, 494, "ชิ้นใหม่รอบนี้")
d.box(280, 482, 14, 14, "", ramp="coral", small=True)
d.text(302, 494, "จุดที่ต้องระวัง")

if __name__ == "__main__":
    d.main()
