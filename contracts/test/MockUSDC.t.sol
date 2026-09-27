// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract MockUSDCTest is Test {
    MockUSDC usdc;
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");

    function setUp() public {
        usdc = new MockUSDC(owner);
    }

    function test_SixDecimals() public view {
        assertEq(usdc.decimals(), 6);
        assertEq(usdc.symbol(), "USDC");
    }

    function test_OwnerCanMint() public {
        vm.prank(owner);
        usdc.mint(alice, 1_000e6);
        assertEq(usdc.balanceOf(alice), 1_000e6);
    }

    function test_RevertWhen_NonOwnerMints() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        usdc.mint(alice, 1);
    }
}
