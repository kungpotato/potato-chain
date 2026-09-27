// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "../src/oracle/AggregatorV3Interface.sol";
import {PotatoOracle} from "../src/lending/PotatoOracle.sol";
import {LinearIrm} from "../src/lending/LinearIrm.sol";
import {IMorpho, MarketParams} from "@morpho-blue/interfaces/IMorpho.sol";
import {MarketParamsLib} from "@morpho-blue/libraries/MarketParamsLib.sol";

/// Morpho Blue + WPOTATO/USDC market + 10k USDC initial supply. Merges addresses into deployments json.
/// Makes no calls into WPOTATO (collateral): forge's local simulation can't execute the precompile.
contract DeployLending is Script {
    using MarketParamsLib for MarketParams;

    uint256 constant LLTV = 0.77e18;
    uint256 constant FEED_MAX_AGE = 1 days; // devnet: prices are pushed by hand

    function run() external {
        string memory path = string.concat("../deployments/", vm.envOr("NETWORK", string("localnet")), ".json");
        string memory json = vm.readFile(path);
        address usdc = vm.parseJsonAddress(json, ".USDC");
        address wpotato = vm.parseJsonAddress(json, ".WPOTATO");
        address feed = vm.parseJsonAddress(json, ".Feed_POTATO_USD");

        vm.startBroadcast();
        IMorpho morpho = IMorpho(deployCode("Morpho.sol:Morpho", abi.encode(msg.sender)));
        LinearIrm irm = new LinearIrm(0.02e18, 0.2e18);
        PotatoOracle oracle = new PotatoOracle(AggregatorV3Interface(feed), FEED_MAX_AGE, 18, 6);

        morpho.enableIrm(address(irm));
        morpho.enableLltv(LLTV);
        MarketParams memory mp = MarketParams(usdc, wpotato, address(oracle), address(irm), LLTV);
        morpho.createMarket(mp);

        IERC20(usdc).approve(address(morpho), 10_000e6);
        morpho.supply(mp, 10_000e6, 0, msg.sender, "");
        vm.stopBroadcast();

        vm.writeJson(vm.toString(address(morpho)), path, ".Morpho");
        vm.writeJson(vm.toString(address(oracle)), path, ".PotatoOracle");
        vm.writeJson(vm.toString(address(irm)), path, ".LinearIrm");
        vm.writeJson(vm.toString(abi.encode(mp.id())), path, ".Market_WPOTATO_USDC");
        console.log("Morpho:", address(morpho));
    }
}
