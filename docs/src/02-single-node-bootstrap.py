from diagram import Diagram

d = Diagram("02-single-node-bootstrap", 560, "Single node bootstrap sequence",
            "Script builds potatod, init writes config and genesis, genesis is patched with apotato, "
            "accounts and gentx are added, then potatod start runs CometBFT which calls InitChain and "
            "FinalizeBlock on the app every second.")

cols = {"script": 90, "cli": 220, "files": 350, "comet": 480, "app": 600}
heads = [("script", "local_node.sh", "gray"), ("cli", "potatod CLI", "teal"),
         ("files", "~/.potatod", "gray"), ("comet", "CometBFT", "teal"), ("app", "App + EVM", "teal")]
for k, label, ramp in heads:
    d.box(cols[k] - 55, 20, 110, 40, label, ramp=ramp)
    d.line(cols[k], 60, cols[k], 530, color="#B4B2A9", dash="3 4", arrow=False)


def msg(y, a, b, label, dash=None, lx=None):
    x1, x2 = cols[a], cols[b]
    s = 1 if x2 > x1 else -1
    d.line(x1 + 3 * s, y, x2 - 5 * s, y, color="#5F5E5A", dash=dash)
    d.text(lx or (x1 + x2) / 2, y - 7, label, anchor="middle")


msg(100, "script", "cli", "1 make build")
msg(140, "cli", "files", "2 init potato-1")
msg(180, "script", "files", "3 jq: denom apotato", lx=285)
msg(220, "cli", "files", "4 genesis accounts")
msg(260, "cli", "files", "5 gentx + collect")
msg(300, "script", "comet", "6 potatod start", lx=415)
msg(340, "comet", "files", "7 load genesis")
msg(380, "comet", "app", "8 InitChain")
d.frame(425, 408, 240, 104)
d.text(540, 427, "loop ทุก ~1s", anchor="middle")
msg(460, "comet", "app", "9 FinalizeBlock")
msg(495, "app", "comet", "10 app hash", dash="4 3")

if __name__ == "__main__":
    d.main()
