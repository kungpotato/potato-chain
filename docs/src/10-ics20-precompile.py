from diagram import Diagram

d = Diagram("10-ics20-precompile", 520, "IBC transfer from the EVM through the ICS-20 precompile",
            "Path A: an EOA such as MetaMask calls the ICS-20 precompile at 0x0802 directly with itself as sender. "
            "Path B: an EOA calls PotatoBridge.bridge with POTATO as msg.value; the contract then calls the "
            "precompile with sender set to its own address, because the precompile requires sender to equal "
            "msg.sender. The precompile escrows POTATO in the transfer module and emits the packet that Hermes "
            "relays to gaia-local.")

cols = {"eoa": 80, "bridge": 230, "ics20": 400, "gaia": 590}
heads = [("eoa", "EOA / MetaMask", "gray"), ("bridge", "PotatoBridge", "purple"),
         ("ics20", "ICS-20 0x0802", "teal"), ("gaia", "gaia (Hermes)", "teal")]
for k, label, ramp in heads:
    d.box(cols[k] - 62, 20, 124, 40, label, ramp=ramp)
    d.line(cols[k], 60, cols[k], 500, color="#B4B2A9", dash="3 4", arrow=False)


def msg(y, a, b, label, dash=None, lx=None):
    x1, x2 = cols[a], cols[b]
    s = 1 if x2 > x1 else -1
    d.line(x1 + 3 * s, y, x2 - 5 * s, y, color="#5F5E5A", dash=dash)
    d.text(lx or (x1 + x2) / 2, y - 7, label, anchor="middle")


d.frame(20, 76, 640, 104)
d.text(30, 94, "A: EOA เรียกตรง")
msg(130, "eoa", "ics20", "transfer(..., sender = EOA)", lx=240)
d.box(cols["ics20"] - 75, 142, 150, 28, "escrow + packet", ramp="teal", small=True)

d.frame(20, 196, 640, 184)
d.text(30, 214, "B: ผ่าน contract")
msg(250, "eoa", "bridge", "bridge{value}(to)")
msg(300, "bridge", "ics20", "transfer(..., sender = this)")
d.box(cols["ics20"] - 75, 312, 150, 28, "escrow + packet", ramp="teal", small=True)
d.box(cols["bridge"] - 90, 340, 180, 30, "sender ≠ msg.sender → revert", ramp="coral", small=True)

msg(420, "ics20", "gaia", "packet → mint ibc/…", dash="4 3")
d.text(cols["ics20"] + 95, 450, "(relay เหมือน diagram 09)", anchor="middle")

if __name__ == "__main__":
    d.main()
