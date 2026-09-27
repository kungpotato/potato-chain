from diagram import Diagram

d = Diagram("09-ibc-transfer", 560, "IBC ICS-20 transfer from potato-1 to gaia-local via Hermes",
            "Setup: Hermes creates light clients on both chains, a connection and a transfer channel. Transfer: "
            "the user sends MsgTransfer on potato-1, which escrows POTATO and commits a packet. Hermes sees the "
            "event, submits RecvPacket with a proof to gaia, which verifies it with its light client and mints "
            "an ibc voucher denom. Hermes relays the acknowledgement back so potato-1 clears the commitment.")

cols = {"user": 90, "potato": 250, "hermes": 420, "gaia": 590}
heads = [("user", "user / EVM", "gray"), ("potato", "potato-1", "teal"),
         ("hermes", "Hermes (host)", "purple"), ("gaia", "gaia-local", "teal")]
for k, label, ramp in heads:
    d.box(cols[k] - 60, 20, 120, 40, label, ramp=ramp)
    d.line(cols[k], 60, cols[k], 540, color="#B4B2A9", dash="3 4", arrow=False)


def msg(y, a, b, label, dash=None, lx=None):
    x1, x2 = cols[a], cols[b]
    s = 1 if x2 > x1 else -1
    d.line(x1 + 3 * s, y, x2 - 5 * s, y, color="#5F5E5A", dash=dash)
    d.text(lx or (x1 + x2) / 2, y - 7, label, anchor="middle")


def note(y, col, text, ramp="teal", w=150):
    d.box(cols[col] - w / 2, y, w, 30, text, ramp=ramp, small=True)


d.frame(160, 72, 500, 108)
d.text(262, 90, "setup ครั้งเดียว")
msg(118, "hermes", "potato", "0 client + conn + chan")
msg(160, "hermes", "gaia", "client + conn + chan")

msg(220, "user", "potato", "1 MsgTransfer 10 POTATO")
note(236, "potato", "2 escrow + commit")
msg(300, "potato", "hermes", "3 SendPacket event", dash="4 3")
msg(340, "hermes", "gaia", "4 RecvPacket + proof")
note(356, "gaia", "5 verify + mint", w=130)
msg(420, "gaia", "hermes", "6 ack event", dash="4 3")
msg(460, "hermes", "potato", "7 Ack + proof")
note(476, "potato", "8 ลบ commitment")

if __name__ == "__main__":
    d.main()
