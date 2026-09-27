// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";

/// Dev-only price feed: the owner pushes answers (scripts/oracle_push.sh).
/// Same ABI as a Chainlink aggregator, so it can later be swapped for PythAggregatorV3.
contract MockAggregatorV3 is AggregatorV3Interface, Ownable {
    struct Round {
        int256 answer;
        uint256 updatedAt;
    }

    uint8 public immutable override decimals;
    string public override description;
    uint256 public constant override version = 1;

    uint80 public latestRound;
    mapping(uint80 => Round) internal rounds;

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

    constructor(address owner_, uint8 decimals_, string memory description_) Ownable(owner_) {
        decimals = decimals_;
        description = description_;
    }

    function updateAnswer(int256 answer) external onlyOwner {
        latestRound++;
        rounds[latestRound] = Round(answer, block.timestamp);
        emit AnswerUpdated(answer, latestRound, block.timestamp);
    }

    function getRoundData(uint80 roundId) public view override returns (uint80, int256, uint256, uint256, uint80) {
        Round memory r = rounds[roundId];
        return (roundId, r.answer, r.updatedAt, r.updatedAt, roundId);
    }

    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        return getRoundData(latestRound);
    }
}
