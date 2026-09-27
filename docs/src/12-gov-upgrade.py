from diagram import Diagram

d = Diagram("12-gov-upgrade", 600, "Coordinated chain upgrade through x/gov and x/upgrade",
            "The operator submits a MsgSoftwareUpgrade proposal for plan potato-v2 at a future height. The four "
            "validators vote yes during the 30 second voting period, the proposal passes and x/upgrade stores the "
            "plan. At the upgrade height every node halts with UPGRADE NEEDED. The operator swaps in the v2 binary, "
            "whose handler raises the block gas limit from 10M to 30M and runs module migrations, and the chain "
            "resumes. Starting v2 before the height panics.")

cols = {"op": 80, "gov": 240, "upg": 410, "nodes": 580}
heads = [("op", "operator", "gray"), ("gov", "x/gov", "teal"),
         ("upg", "x/upgrade", "teal"), ("nodes", "4 nodes (v1→v2)", "purple")]
for k, label, ramp in heads:
    d.box(cols[k] - 64, 20, 128, 40, label, ramp=ramp)
    d.line(cols[k], 60, cols[k], 580, color="#B4B2A9", dash="3 4", arrow=False)


def msg(y, a, b, label, dash=None, lx=None):
    x1, x2 = cols[a], cols[b]
    s = 1 if x2 > x1 else -1
    d.line(x1 + 3 * s, y, x2 - 5 * s, y, color="#5F5E5A", dash=dash)
    d.text(lx or (x1 + x2) / 2, y - 7, label, anchor="middle")


def note(y, col, text, ramp="teal", w=150, h=30):
    d.box(cols[col] - w / 2, y, w, h, text, ramp=ramp, small=True)


msg(100, "op", "gov", "1 propose potato-v2 @ H")
msg(145, "nodes", "gov", "2 vote yes ×4", lx=410)
note(160, "gov", "3 30s → passed")
msg(225, "gov", "upg", "4 schedule plan")
note(250, "nodes", "5 height H: HALT", ramp="coral")
d.text(cols["nodes"], 298, "UPGRADE NEEDED", anchor="middle", color="#993C1D")
msg(340, "op", "nodes", "6 swap binary v2 (image)", lx=250)
msg(385, "nodes", "upg", "7 handler potato-v2")
note(400, "upg", "max_gas 10M → 30M", w=160)
note(450, "upg", "RunMigrations", w=160)
msg(510, "upg", "nodes", "8 resume H+1", dash="4 3")

d.box(40, 530, 330, 40, "v2 ก่อนถึง H → panic (BINARY UPDATED BEFORE TRIGGER)", ramp="coral", small=True)

if __name__ == "__main__":
    d.main()
