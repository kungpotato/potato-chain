from diagram import Diagram

d = Diagram("08-oracle", 430, "Oracle design: mock Chainlink feed now, Pyth adapter later",
            "A price pusher script updates MockAggregatorV3 for POTATO/USD. Consumers such as week 6 lending read "
            "it only through OracleLib, which rejects zero, negative and stale prices. Later a Pyth feed wrapped "
            "in PythAggregatorV3 implements the same AggregatorV3Interface, so switching is a config change. "
            "The DEX spot price is not used as an oracle because it can be manipulated.")

d.box(40, 30, 180, 54, "oracle_push.sh", "cast send updateAnswer")
d.line(222, 62, 268, 62)

d.frame(250, 20, 390, 150)
d.text(262, 160, "AggregatorV3Interface (Chainlink)")
d.box(270, 35, 170, 54, "MockAggregatorV3", "POTATO/USD, 8 dec", ramp="purple")
d.box(455, 35, 170, 54, "PythAggregatorV3", "Pyth adapter (ทีหลัง)")
d.line(355, 91, 355, 118, arrow=False)
d.line(540, 91, 540, 118, color="#888780", dash="4 3", arrow=False)
d.line(355, 118, 540, 118, arrow=False)
d.line(447, 118, 447, 198)

d.box(340, 200, 215, 56, "OracleLib.readPrice", "revert: ≤ 0, stale, round เก่า", ramp="purple")
d.line(447, 258, 447, 298)
d.box(360, 300, 175, 54, "Lending (สัปดาห์ 6)", "ใช้ราคาคิด collateral")

d.box(40, 200, 250, 56, "DEX spot price", "ห้ามใช้เป็น oracle", ramp="coral")
d.text(52, 280, "flash loan ดันราคาใน 1 tx ได้")
d.line(292, 228, 336, 228, color="#D85A30", dash="4 3")
d.text(314, 218, "✕", anchor="middle", color="#D85A30")

d.box(40, 390, 14, 14, "", ramp="purple", small=True)
d.text(62, 402, "deploy รอบนี้")
d.box(170, 390, 14, 14, "", ramp="gray", small=True)
d.text(192, 402, "ภายนอก / ทีหลัง")
d.box(320, 390, 14, 14, "", ramp="coral", small=True)
d.text(342, 402, "anti-pattern")

if __name__ == "__main__":
    d.main()
