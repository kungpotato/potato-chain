from diagram import Diagram

d = Diagram("06-money-and-dex", 480, "Week 3 contracts: preinstalls, WPOTATO, mock USDC and Uniswap v2",
            "Genesis provides Create2, Multicall3, Permit2 and Safe factory preinstalls plus the WPOTATO WERC20 "
            "precompile at 0xEeee. We deploy MockUSDC, UniswapV2Factory and UniswapV2Router02 with forge script. "
            "The router uses the factory and WPOTATO, and the factory creates the WPOTATO/USDC pair.")

d.frame(40, 20, 600, 110)
d.text(52, 40, "genesis (มีตั้งแต่ block 0)")
for i, (t, s) in enumerate([("Create2", "0x4e59…"), ("Multicall3", "0xcA11…"),
                            ("Permit2", "0x0000…BA3"), ("Safe factory", "0x914d…")]):
    d.box(55 + i * 145, 55, 135, 52, t, s, ramp="teal")

d.box(40, 160, 180, 56, "WPOTATO", "precompile 0xEeee…", ramp="teal")
d.box(250, 160, 180, 56, "UniswapV2Router02", "addLiquidity / swap", ramp="purple")
d.box(460, 160, 180, 56, "UniswapV2Factory", "createPair (CREATE2)", ramp="purple")
d.line(248, 188, 222, 188)
d.line(432, 188, 458, 188)

d.box(460, 280, 180, 56, "Pair WPOTATO/USDC", "x · y = k", ramp="purple")
d.line(550, 218, 550, 278)
d.text(560, 252, "สร้าง")
d.box(250, 280, 180, 56, "MockUSDC", "ERC-20, 6 decimals", ramp="purple")
d.line(432, 308, 458, 308)

d.box(40, 380, 390, 52, "forge script Deploy.s.sol", "deploy USDC → Factory → Router → pool แรก")
d.line(340, 378, 340, 338)
d.box(460, 380, 180, 52, "init code hash", "ต้อง patch ใน Router", ramp="coral")
d.line(550, 378, 550, 338, color="#D85A30", dash="4 3")

d.box(40, 446, 14, 14, "", ramp="teal", small=True)
d.text(62, 458, "มีอยู่แล้วบนเชน")
d.box(190, 446, 14, 14, "", ramp="purple", small=True)
d.text(212, 458, "deploy รอบนี้")
d.box(330, 446, 14, 14, "", ramp="coral", small=True)
d.text(352, 458, "จุดที่พังบ่อย")

if __name__ == "__main__":
    d.main()
