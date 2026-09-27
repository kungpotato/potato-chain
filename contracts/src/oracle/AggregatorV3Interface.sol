// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// Chainlink's price feed interface (same ABI as the chainlink/contracts package). Pyth ships an
/// adapter (PythAggregatorV3) with this ABI, so consumers never depend on the provider.
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    function getRoundData(uint80 roundId)
        external view returns (uint80 roundId_, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function latestRoundData()
        external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
