// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IIrm} from "@morpho-blue/interfaces/IIrm.sol";
import {MarketParams, Market} from "@morpho-blue/interfaces/IMorpho.sol";

/// Stateless linear rate model: APR = base + slope * utilization.
/// Simpler than Morpho's AdaptiveCurveIrm, enough to see interest respond to utilization on a devnet.
contract LinearIrm is IIrm {
    uint256 internal constant WAD = 1e18;

    uint256 public immutable baseApr; // WAD
    uint256 public immutable slopeApr; // WAD, added at 100% utilization

    constructor(uint256 baseApr_, uint256 slopeApr_) {
        baseApr = baseApr_;
        slopeApr = slopeApr_;
    }

    /// @return per-second borrow rate (WAD), as Morpho expects
    function borrowRateView(MarketParams memory, Market memory market) public view returns (uint256) {
        uint256 util = market.totalSupplyAssets == 0 ? 0 : uint256(market.totalBorrowAssets) * WAD / market.totalSupplyAssets;
        return (baseApr + slopeApr * util / WAD) / 365 days;
    }

    function borrowRate(MarketParams memory mp, Market memory market) external view returns (uint256) {
        return borrowRateView(mp, market);
    }
}
