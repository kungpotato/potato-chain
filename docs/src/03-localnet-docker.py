from diagram import Diagram

d = Diagram("03-localnet-docker", 450, "Four validator localnet on docker compose",
            "localnet_init.sh builds shared genesis and per-node homes under .localnet, each mounted into "
            "one of four potatod containers on a docker network. Nodes peer over P2P 26656, node0 exposes "
            "RPC ports to the host, and stopping node3 leaves 75 percent voting power so blocks continue.")

d.box(40, 30, 180, 52, "localnet_init.sh", "genesis 4 gentx")
d.box(260, 30, 180, 52, ".localnet/node0..3", "home dir ต่อ node")
d.box(480, 30, 160, 52, "Dockerfile", "image potatod")
d.line(222, 56, 256, 56)

d.frame(40, 120, 600, 205)
d.text(140, 312, "docker network: potato-net", cls="th", anchor="start", color="#2C2C2A")

d.line(350, 84, 350, 150, arrow=False)
d.text(360, 108, "volume mount")
d.line(118, 150, 568, 150, arrow=False)
xs = [55, 205, 355, 505]
for i, x in enumerate(xs):
    cx = x + 62.5
    d.line(cx, 150, cx, 176)
    d.box(x, 178, 125, 56, f"node{i}", "val · 25% power", ramp="teal")
for x in xs[:-1]:
    d.line(x + 127, 206, x + 148, 206, color="#1D9E75", dash="3 3")
d.text(340, 262, "P2P :26656 full mesh (persistent_peers)", anchor="middle")

d.line(117, 236, 117, 358)
d.box(40, 360, 260, 52, "host ports (node0)", ":26657  :8545  :1317")
d.line(567, 236, 567, 358, color="#D85A30", dash="4 3")
d.box(380, 360, 260, 52, "stop node3", "เหลือ 75% > ⅔ ยังออกบล็อก", ramp="coral")

if __name__ == "__main__":
    d.main()
