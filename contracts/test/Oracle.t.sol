// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MockAggregatorV3} from "../src/oracle/MockAggregatorV3.sol";
import {OracleLib} from "../src/oracle/OracleLib.sol";
import {AggregatorV3Interface} from "../src/oracle/AggregatorV3Interface.sol";

/// External wrapper so vm.expectRevert can catch library reverts.
contract Reader {
    function read(AggregatorV3Interface feed, uint256 maxAge) external view returns (uint256, uint8) {
        return OracleLib.readPrice(feed, maxAge);
    }
}

contract OracleTest is Test {
    MockAggregatorV3 feed;
    Reader reader = new Reader();
    address owner = makeAddr("owner");
    uint256 constant MAX_AGE = 1 hours;

    function setUp() public {
        vm.warp(1_700_000_000);
        feed = new MockAggregatorV3(owner, 8, "POTATO / USD");
        vm.prank(owner);
        feed.updateAnswer(2e8); // $2.00
    }

    function test_ReadsFreshPrice() public view {
        (uint256 price, uint8 dec) = reader.read(feed, MAX_AGE);
        assertEq(price, 2e8);
        assertEq(dec, 8);
    }

    function test_RoundIdIncrementsAndHistoryKept() public {
        vm.prank(owner);
        feed.updateAnswer(3e8);
        (uint80 id, int256 answer,,,) = feed.latestRoundData();
        assertEq(id, 2);
        assertEq(answer, 3e8);
        (, int256 old,,,) = feed.getRoundData(1);
        assertEq(old, 2e8);
    }

    function test_RevertWhen_Stale() public {
        vm.warp(block.timestamp + MAX_AGE + 1);
        vm.expectRevert(abi.encodeWithSelector(OracleLib.StalePrice.selector, MAX_AGE + 1, MAX_AGE));
        reader.read(feed, MAX_AGE);
    }

    function test_RevertWhen_NonPositive() public {
        vm.prank(owner);
        feed.updateAnswer(0);
        vm.expectRevert(abi.encodeWithSelector(OracleLib.InvalidPrice.selector, int256(0)));
        reader.read(feed, MAX_AGE);
    }

    function test_RevertWhen_NeverUpdated() public {
        MockAggregatorV3 empty = new MockAggregatorV3(owner, 8, "EMPTY");
        vm.expectRevert(OracleLib.NoData.selector);
        reader.read(empty, MAX_AGE);
    }

    function test_RevertWhen_NonOwnerPushes() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        feed.updateAnswer(1);
    }
}
