// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.5.16;

// Pulls Uniswap v2-core into the build so artifacts exist for UniswapV2Factory/UniswapV2Pair
// (0.8 scripts can't import 0.5 sources; they deploy these by artifact name).
import "@uniswap/v2-core/contracts/UniswapV2Factory.sol";
