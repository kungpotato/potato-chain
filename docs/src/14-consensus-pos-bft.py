from diagram import Diagram

d = Diagram("14-consensus-pos-bft", 360, "potato-chain consensus: PoS picks the validators, BFT agrees on blocks",
            "Cosmos SDK modules implement proof of stake: x/staking turns bonded POTATO into validator voting "
            "power, x/slashing punishes double signing and downtime, x/distribution and x/mint pay rewards. The "
            "validator set is handed to CometBFT, which runs propose, prevote and precommit rounds needing two "
            "thirds of voting power and commits blocks with instant finality. Evidence of double signing flows "
            "back to slashing. On potato-1 four validators hold 25 percent each.")

d.frame(20, 20, 640, 130)
d.text(32, 40, "Proof of Stake: ใครเป็น validator + เสียงหนักเท่าไหร่ (Cosmos SDK)", cls="th", color="#2C2C2A")
d.box(32, 54, 196, 56, "x/staking", "stake → voting power", ramp="purple")
d.box(242, 54, 196, 56, "x/slashing", "double sign 5% · offline 1%", ramp="purple")
d.box(452, 54, 196, 56, "x/distribution + mint", "รางวัล · inflation 7–20%", ramp="purple")

d.line(130, 112, 130, 222)
d.text(140, 172, "validator set + power")
d.line(372, 224, 372, 114, color="#D85A30", dash="4 3")
d.text(382, 172, "evidence (double sign)", color="#993C1D")

d.frame(20, 190, 640, 150)
d.text(648, 210, "BFT consensus: ตกลงบล็อก (CometBFT)", cls="th", anchor="end", color="#2C2C2A")
steps = [("1 Propose", "proposer หมุนเวียน"), ("2 Prevote", "vote ≥ ⅔ power"),
         ("3 Precommit", "lock ≥ ⅔ power"), ("4 Commit", "finality ทันที")]
for i, (t, s) in enumerate(steps):
    x = 32 + i * 155
    d.box(x, 226, 135, 56, t, s, ramp="teal")
    if i < 3:
        d.line(x + 137, 254, x + 153, 254)
d.text(340, 316, "potato-1: 4 validators × 1000 POTATO = 25% ต่อตัว → ปิด 1 ตัว (75%) ยังเดิน · ปิด 2 ตัว (50%) หยุด",
       anchor="middle")

if __name__ == "__main__":
    d.main()
