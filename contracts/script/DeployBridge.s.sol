// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {PotatoBridge} from "../src/ibc/PotatoBridge.sol";

/// Deploys PotatoBridge on the IBC channel to gaia and merges it into deployments/<network>.json.
contract DeployBridge is Script {
    function run() external {
        string memory path = string.concat("../deployments/", vm.envOr("NETWORK", string("localnet")), ".json");
        string memory channel = vm.envOr("IBC_CHANNEL", string("channel-0"));
        vm.startBroadcast();
        PotatoBridge bridge = new PotatoBridge(channel, 10 minutes);
        vm.stopBroadcast();
        vm.writeJson(vm.toString(address(bridge)), path, ".PotatoBridge");
        console.log("PotatoBridge:", address(bridge));
    }
}
