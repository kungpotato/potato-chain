import { erc20Abi, parseAbi } from "viem";
export { erc20Abi };

export const routerAbi = parseAbi([
  "function getAmountsOut(uint256 amountIn, address[] path) view returns (uint256[] amounts)",
  "function swapExactETHForTokens(uint256 amountOutMin, address[] path, address to, uint256 deadline) payable returns (uint256[] amounts)",
  "function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline) returns (uint256[] amounts)",
]);

export const bridgeAbi = parseAbi([
  "function bridge(string receiver) payable returns (uint64 sequence)",
  "function channel() view returns (string)",
  "event Bridged(address indexed from, string receiver, uint256 amount, uint64 sequence)",
]);

// Morpho Blue v1.0.0 (subset)
const MP = "(address loanToken, address collateralToken, address oracle, address irm, uint256 lltv)";
export const morphoAbi = parseAbi([
  `function supplyCollateral(${MP} marketParams, uint256 assets, address onBehalf, bytes data)`,
  `function borrow(${MP} marketParams, uint256 assets, uint256 shares, address onBehalf, address receiver) returns (uint256, uint256)`,
  `function repay(${MP} marketParams, uint256 assets, uint256 shares, address onBehalf, bytes data) returns (uint256, uint256)`,
  "function position(bytes32 id, address user) view returns (uint256 supplyShares, uint128 borrowShares, uint128 collateral)",
  "function market(bytes32 id) view returns (uint128 totalSupplyAssets, uint128 totalSupplyShares, uint128 totalBorrowAssets, uint128 totalBorrowShares, uint128 lastUpdate, uint128 fee)",
]);
export const oracleAbi = parseAbi(["function price() view returns (uint256)"]);
