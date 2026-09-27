// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

interface IFactory {
    function createPair(address a, address b) external returns (address);
    function getPair(address a, address b) external view returns (address);
}

interface IRouter {
    function addLiquidity(address a, address b, uint256 amtA, uint256 amtB, uint256 minA, uint256 minB, address to, uint256 deadline)
        external returns (uint256, uint256, uint256);
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external returns (uint256[] memory);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory);
}

interface IPair {
    function getReserves() external view returns (uint112, uint112, uint32);
}

/// Guards the one thing that silently breaks forks of Uniswap v2: the Router's hardcoded
/// Pair init code hash must match the Pair bytecode *we* compile.
contract UniswapV2Test is Test {
    IFactory factory;
    IRouter router;
    MockUSDC usdc;
    MockUSDC other; // any second ERC-20 (WPOTATO is a chain precompile, not available in forge's EVM)
    address lp = makeAddr("lp");
    address trader = makeAddr("trader");

    function setUp() public {
        factory = IFactory(deployCode("UniswapV2Factory.sol:UniswapV2Factory", abi.encode(address(this))));
        router = IRouter(deployCode("UniswapV2Router02.sol:UniswapV2Router02", abi.encode(address(factory), address(0xEeee))));
        usdc = new MockUSDC(address(this));
        other = new MockUSDC(address(this));
        usdc.mint(lp, 1_000_000e6);
        other.mint(lp, 1_000_000e6);
        usdc.mint(trader, 1_000e6);
    }

    function test_InitCodeHashMatchesCompiledPair() public view {
        bytes32 expected = keccak256(vm.getCode("UniswapV2Pair.sol:UniswapV2Pair"));
        bytes memory lib = bytes(vm.readFile("src/vendor/v2-periphery/contracts/libraries/UniswapV2Library.sol"));
        string memory needle = vm.replace(vm.toString(expected), "0x", "hex'"); // source form: hex'<64 hex>'
        assertTrue(_contains(lib, bytes(needle)), "patch UniswapV2Library init code hash");
    }

    function test_AddLiquidityThenSwap() public {
        factory.createPair(address(usdc), address(other));
        _addLiquidity(100_000e6, 100_000e6);

        address[] memory path = new address[](2);
        (path[0], path[1]) = (address(usdc), address(other));
        uint256 quoted = router.getAmountsOut(100e6, path)[1];

        vm.startPrank(trader);
        usdc.approve(address(router), 100e6);
        router.swapExactTokensForTokens(100e6, quoted, path, trader, block.timestamp);
        vm.stopPrank();

        assertEq(other.balanceOf(trader), quoted);
        assertLt(quoted, 100e6, "0.3% fee + price impact");
        (uint112 r0, uint112 r1,) = IPair(factory.getPair(address(usdc), address(other))).getReserves();
        assertGe(uint256(r0) * r1, uint256(100_000e6) * 100_000e6, "k must not decrease");
    }

    function _addLiquidity(uint256 a, uint256 b) internal {
        vm.startPrank(lp);
        usdc.approve(address(router), a);
        other.approve(address(router), b);
        router.addLiquidity(address(usdc), address(other), a, b, 0, 0, lp, block.timestamp);
        vm.stopPrank();
    }

    function _contains(bytes memory hay, bytes memory needle) internal pure returns (bool) {
        for (uint256 i; i + needle.length <= hay.length; i++) {
            bool ok = true;
            for (uint256 j; j < needle.length && ok; j++) ok = hay[i + j] == needle[j];
            if (ok) return true;
        }
        return false;
    }
}
