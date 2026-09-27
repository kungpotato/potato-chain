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
