from diagram import Diagram

d = Diagram("11-lending-morpho", 500, "Lending market on Morpho Blue: borrow USDC against WPOTATO",
            "Morpho Blue holds one isolated market defined by loan token USDC, collateral WPOTATO precompile, "
            "PotatoOracle, LinearIrm and an LLTV of 77 percent. Lenders supply USDC, borrowers supply WPOTATO "
            "collateral and borrow USDC. PotatoOracle converts the Chainlink-style POTATO/USD feed read through "
            "OracleLib into Morpho's 1e36-scaled price. When the price drops and the position exceeds the LLTV, a "
            "liquidator repays debt and seizes collateral.")

d.box(40, 30, 140, 52, "Lender", "supply USDC")
d.box(270, 30, 140, 52, "Borrower", "collateral + borrow")
d.box(500, 30, 140, 52, "Liquidator", "repay → seize")
for x in (110, 340, 570):
    d.line(x, 84, x, 126)

d.frame(40, 110, 600, 200)
d.text(628, 300, "Morpho Blue v1.0.0 (singleton)", anchor="end")
d.box(60, 128, 560, 60, "Market WPOTATO / USDC", "LLTV 77% · supply, borrow, repay, liquidate · shares", ramp="purple")
d.line(160, 190, 160, 218)
d.line(340, 190, 340, 218)
d.line(520, 190, 520, 218)
d.box(70, 220, 180, 52, "loan: USDC", "MockUSDC, 6 dec", ramp="teal")
d.box(265, 220, 150, 52, "collateral", "WPOTATO 0xEeee", ramp="teal")
d.box(430, 220, 190, 52, "LinearIrm", "rate = base + slope · util", ramp="purple")

d.box(60, 340, 250, 56, "PotatoOracle.price()", "feed · 1e16 → Morpho 1e36 scale", ramp="purple")
d.line(58, 368, 48, 368, arrow=False)
d.line(48, 368, 48, 158, arrow=False)
d.line(48, 158, 58, 158)
d.box(360, 340, 260, 56, "OracleLib + POTATO/USD feed", "stale / ≤ 0 → revert (fail closed)", ramp="teal")
d.line(358, 368, 312, 368)

d.box(60, 420, 560, 44, "ราคาลง (oracle_push.sh) → LTV > 77% → liquidate ได้", ramp="coral", small=True)

d.box(40, 476, 14, 14, "", ramp="purple", small=True)
d.text(62, 488, "ชิ้นใหม่รอบนี้")
d.box(180, 476, 14, 14, "", ramp="teal", small=True)
d.text(202, 488, "มีอยู่แล้ว")

if __name__ == "__main__":
    d.main()
