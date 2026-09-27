// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// First contract on potato-chain: proves deploy + write + read + events over JSON-RPC.
contract Counter {
    uint256 public number;

    event Incremented(address indexed by, uint256 newValue);

    function increment() external {
        number += 1;
        emit Incremented(msg.sender, number);
    }
}
