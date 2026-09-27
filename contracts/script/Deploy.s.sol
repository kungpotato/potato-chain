// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

interface IFactory {
    function createPair(address a, address b) external returns (address);
}

/// Deploys week-3 money + DEX contracts and writes deployments/<network>.json.
/// Deliberately makes NO calls into WPOTATO: it is a cosmos/evm precompile, which forge's
/// local simulation (revm) cannot execute. Liquidity is seeded against the real chain
/// by scripts/seed_pool.sh.
///
///   forge script script/Deploy.s.sol --rpc-url potato_local --private-key $PK --broadcast
contract Deploy is Script {
    address constant WPOTATO = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // genesis erc20 native precompile

    function run() external {
        string memory network = vm.envOr("NETWORK", string("localnet"));
        vm.startBroadcast();
        address deployer = msg.sender;

        MockUSDC usdc = new MockUSDC(deployer);
        usdc.mint(deployer, 1_000_000e6);

        address factory = deployCode("UniswapV2Factory.sol:UniswapV2Factory", abi.encode(deployer));
        address router = deployCode("UniswapV2Router02.sol:UniswapV2Router02", abi.encode(factory, WPOTATO));
        address pair = IFactory(factory).createPair(WPOTATO, address(usdc));

        vm.stopBroadcast();

        string memory o = "deployments";
        vm.serializeUint(o, "chainId", block.chainid);
        vm.serializeAddress(o, "WPOTATO", WPOTATO);
        vm.serializeAddress(o, "USDC", address(usdc));
        vm.serializeAddress(o, "UniswapV2Factory", factory);
        vm.serializeAddress(o, "UniswapV2Router02", router);
        string memory json = vm.serializeAddress(o, "Pair_WPOTATO_USDC", pair);
        vm.writeJson(json, string.concat("../deployments/", network, ".json"));
        console.log("pair WPOTATO/USDC:", pair);
    }
}
