// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IOracle} from "@morpho-blue/interfaces/IOracle.sol";
import {AggregatorV3Interface} from "../oracle/AggregatorV3Interface.sol";
import {OracleLib} from "../oracle/OracleLib.sol";

/// Adapts a Chainlink-style COLLATERAL/USD feed to Morpho Blue's IOracle, assuming loan token = $1 (USDC).
/// Morpho wants: price of 1 collateral asset in loan assets, scaled by 1e36 * 10^(loanDec - collDec).
/// Reads through OracleLib, so a stale/invalid feed reverts and Morpho borrow/liquidate fail closed.
contract PotatoOracle is IOracle {
    AggregatorV3Interface public immutable feed;
    uint256 public immutable maxAge;
    uint256 public immutable scale; // 10^(36 + loanDec - collDec - feedDec)

    error BadDecimals();

    constructor(AggregatorV3Interface feed_, uint256 maxAge_, uint8 collateralDecimals, uint8 loanDecimals) {
        feed = feed_;
        maxAge = maxAge_;
        uint256 exp = 36 + uint256(loanDecimals);
        uint256 sub = uint256(collateralDecimals) + feed_.decimals();
        if (sub > exp) revert BadDecimals();
        scale = 10 ** (exp - sub);
    }

    function price() external view returns (uint256) {
        (uint256 answer,) = OracleLib.readPrice(feed, maxAge);
        return answer * scale;
    }
}
