// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PotatoBridge} from "../src/ibc/PotatoBridge.sol";
import {ICS20_PRECOMPILE, IICS20, Height} from "../src/ibc/IICS20.sol";

/// Stand-in for the chain's ICS-20 precompile (forge's EVM has no cosmos precompiles).
/// Enforces the same sender rule and records the last call.
contract MockICS20 {
    string public lastChannel;
    string public lastDenom;
    uint256 public lastAmount;
    address public lastSender;
    string public lastReceiver;
    uint64 public lastTimeout;
    uint64 public seq;

    function transfer(
        string memory, string memory ch, string memory denom, uint256 amount, address sender,
        string memory receiver, Height memory, uint64 timeoutTs, string memory
    ) external returns (uint64) {
        require(sender == msg.sender, "requester is not msg sender");
        (lastChannel, lastDenom, lastAmount, lastSender, lastReceiver, lastTimeout) =
            (ch, denom, amount, sender, receiver, timeoutTs);
        return ++seq;
    }
}

contract PotatoBridgeTest is Test {
    PotatoBridge bridge;
    MockICS20 ics20;
    address alice = makeAddr("alice");
    string constant TO = "cosmos1ltn66ayhh7thvmms0wt09ywuyaqdhwm0dppahq";

    function setUp() public {
        vm.etch(ICS20_PRECOMPILE, address(new MockICS20()).code);
        ics20 = MockICS20(ICS20_PRECOMPILE);
        bridge = new PotatoBridge("channel-0", 10 minutes);
        vm.deal(alice, 10 ether);
        vm.warp(1_700_000_000);
    }

    function test_BridgesMsgValueWithContractAsSender() public {
        vm.prank(alice);
        uint64 seq = bridge.bridge{value: 1 ether}(TO);

        assertEq(seq, 1);
        assertEq(ics20.lastSender(), address(bridge), "precompile requires sender == msg.sender");
        assertEq(ics20.lastAmount(), 1 ether);
        assertEq(ics20.lastDenom(), "apotato");
        assertEq(ics20.lastChannel(), "channel-0");
        assertEq(ics20.lastReceiver(), TO);
        assertEq(ics20.lastTimeout(), uint64((block.timestamp + 10 minutes) * 1e9), "timeout in ns");
    }

    function test_EmitsBridgedWithOriginalCaller() public {
        vm.expectEmit(true, false, false, true);
        emit PotatoBridge.Bridged(alice, TO, 1 ether, 1);
        vm.prank(alice);
        bridge.bridge{value: 1 ether}(TO);
    }

    function test_RevertWhen_ZeroValue() public {
        vm.expectRevert(PotatoBridge.ZeroAmount.selector);
        bridge.bridge(TO);
    }

    function test_RevertWhen_EmptyReceiver() public {
        vm.expectRevert(PotatoBridge.EmptyReceiver.selector);
        bridge.bridge{value: 1}("");
    }
}
