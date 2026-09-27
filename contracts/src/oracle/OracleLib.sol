// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";

/// The only way protocol code should read a price. Fails closed: a lending market that
/// can't get a trustworthy price must stop, not guess.
library OracleLib {
    error NoData();
    error InvalidPrice(int256 answer);
    error StalePrice(uint256 age, uint256 maxAge);
    error IncompleteRound(uint80 roundId, uint80 answeredInRound);

    /// @return price answer as uint, in `decimals` fixed point
    function readPrice(AggregatorV3Interface feed, uint256 maxAge) internal view returns (uint256 price, uint8 decimals) {
        (uint80 roundId, int256 answer,, uint256 updatedAt, uint80 answeredInRound) = feed.latestRoundData();
        if (updatedAt == 0) revert NoData();
        if (answer <= 0) revert InvalidPrice(answer);
        if (answeredInRound < roundId) revert IncompleteRound(roundId, answeredInRound);
        uint256 age = block.timestamp - updatedAt;
        if (age > maxAge) revert StalePrice(age, maxAge);
        return (uint256(answer), feed.decimals());
    }
}
