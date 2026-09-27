// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MockAggregatorV3} from "../src/oracle/MockAggregatorV3.sol";

/// Deploys the POTATO/USD mock feed and merges its address into deployments/<network>.json.
///   forge script script/DeployOracle.s.sol --rpc-url potato_local --private-key $PK --broadcast
contract DeployOracle is Script {
    function run() external {
        string memory path = string.concat("../deployments/", vm.envOr("NETWORK", string("localnet")), ".json");
        vm.startBroadcast();
        MockAggregatorV3 feed = new MockAggregatorV3(msg.sender, 8, "POTATO / USD");
        feed.updateAnswer(2e8); // seed at $2.00, matching the pool's initial price
        vm.stopBroadcast();

        vm.writeJson(vm.toString(address(feed)), path, ".Feed_POTATO_USD");
        console.log("POTATO/USD feed:", address(feed));
    }
}
