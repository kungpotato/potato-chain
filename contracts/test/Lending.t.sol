// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {MockAggregatorV3} from "../src/oracle/MockAggregatorV3.sol";
import {OracleLib} from "../src/oracle/OracleLib.sol";
import {PotatoOracle} from "../src/lending/PotatoOracle.sol";
import {LinearIrm} from "../src/lending/LinearIrm.sol";
import {IMorpho, MarketParams, Market, Position, Id} from "@morpho-blue/interfaces/IMorpho.sol";
import {MarketParamsLib} from "@morpho-blue/libraries/MarketParamsLib.sol";

/// 18-decimal stand-in for WPOTATO (the real one is a chain precompile forge can't run).
contract MockPotato is ERC20 {
    constructor() ERC20("Wrapped Potato", "WPOTATO") {}
    function mint(address to, uint256 amt) external { _mint(to, amt); }
}

contract LendingTest is Test {
    using MarketParamsLib for MarketParams;

    uint256 constant LLTV = 0.77e18;
    uint256 constant MAX_AGE = 1 hours;

    IMorpho morpho;
    MockUSDC usdc;
    MockPotato potato;
    MockAggregatorV3 feed;
    PotatoOracle oracle;
    LinearIrm irm;
    MarketParams mp;
    Id id;

    address lender = makeAddr("lender");
    address borrower = makeAddr("borrower");
    address liquidator = makeAddr("liquidator");

    function setUp() public {
        vm.warp(1_700_000_000);
        morpho = IMorpho(deployCode("Morpho.sol:Morpho", abi.encode(address(this))));
        usdc = new MockUSDC(address(this));
        potato = new MockPotato();
        feed = new MockAggregatorV3(address(this), 8, "POTATO / USD");
        feed.updateAnswer(2e8); // $2
        oracle = new PotatoOracle(feed, MAX_AGE, 18, 6);
        irm = new LinearIrm(0.02e18, 0.2e18); // 2% base + 20% * utilization (APR)

        morpho.enableIrm(address(irm));
        morpho.enableLltv(LLTV);
        mp = MarketParams(address(usdc), address(potato), address(oracle), address(irm), LLTV);
        morpho.createMarket(mp);
        id = mp.id();

        usdc.mint(lender, 1_000e6);
        vm.startPrank(lender);
        usdc.approve(address(morpho), type(uint256).max);
        morpho.supply(mp, 1_000e6, 0, lender, "");
        vm.stopPrank();

        potato.mint(borrower, 100e18);
        vm.startPrank(borrower);
        potato.approve(address(morpho), type(uint256).max);
        morpho.supplyCollateral(mp, 100e18, borrower, ""); // worth $200
        vm.stopPrank();
    }

    // ---- oracle adapter ----
    function test_OraclePriceScale() public view {
        // 1 POTATO (1e18) = 2 USDC (2e6) -> Morpho price = 2e6 * 1e36 / 1e18
        assertEq(oracle.price(), 2e24);
    }

    function test_OracleStaleRevertsSoBorrowFailsClosed() public {
        vm.warp(block.timestamp + MAX_AGE + 1);
        vm.prank(borrower);
        vm.expectRevert(abi.encodeWithSelector(OracleLib.StalePrice.selector, MAX_AGE + 1, MAX_AGE));
        morpho.borrow(mp, 1e6, 0, borrower, borrower);
    }

    // ---- borrowing against LLTV ----
    function test_BorrowUpToLltv() public {
        vm.prank(borrower);
        morpho.borrow(mp, 150e6, 0, borrower, borrower); // 75% of $200
        assertEq(usdc.balanceOf(borrower), 150e6);
    }

    function test_RevertWhen_BorrowAboveLltv() public {
        vm.prank(borrower);
        vm.expectRevert(bytes("insufficient collateral"));
        morpho.borrow(mp, 155e6, 0, borrower, borrower); // 77.5% > 77%
    }

    // ---- interest ----
    function test_InterestAccruesWithUtilization() public {
        vm.prank(borrower);
        morpho.borrow(mp, 150e6, 0, borrower, borrower);
        // utilization 15% -> APR = 2% + 20% * 15% = 5%; Morpho compounds continuously: e^0.05 - 1 = 5.127%
        vm.warp(block.timestamp + 365 days);
        morpho.accrueInterest(mp); // needs no oracle, so a stale feed can't block interest
        uint256 debt = morpho.market(id).totalBorrowAssets;
        assertApproxEqAbs(debt, 157_690_000, 20_000, "150 USDC * e^0.05");
        assertEq(morpho.market(id).totalSupplyAssets - 1_000e6, debt - 150e6, "lenders earn all interest (no fee)");
    }

    // ---- liquidation after a price drop ----
    function test_LiquidateAfterPriceDrop() public {
        vm.prank(borrower);
        morpho.borrow(mp, 150e6, 0, borrower, borrower);

        feed.updateAnswer(1.8e8); // $1.80 -> LTV = 150 / 180 = 83% > 77%
        Position memory p = morpho.position(id, borrower);

        usdc.mint(liquidator, 200e6);
        vm.startPrank(liquidator);
        usdc.approve(address(morpho), type(uint256).max);
        (uint256 seized, uint256 repaid) = morpho.liquidate(mp, borrower, 10e18, 0, "");
        vm.stopPrank();

        assertEq(potato.balanceOf(liquidator), 10e18);
        assertEq(seized, 10e18);
        // incentive: liquidator pays less USDC than the collateral is worth at the oracle price
        assertLt(repaid, 18e6, "10 POTATO @ $1.80 = $18 of collateral");
        assertLt(morpho.position(id, borrower).collateral, p.collateral);
    }

    function test_RevertWhen_LiquidatingHealthyPosition() public {
        vm.prank(borrower);
        morpho.borrow(mp, 150e6, 0, borrower, borrower);
        vm.prank(liquidator);
        vm.expectRevert(bytes("position is healthy"));
        morpho.liquidate(mp, borrower, 1e18, 0, "");
    }
}
