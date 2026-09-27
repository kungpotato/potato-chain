// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ICS20_PRECOMPILE, IICS20, Height} from "./IICS20.sol";

/// Send native POTATO over IBC from any EVM wallet/contract: `bridge{value: amount}(cosmosReceiver)`.
///
/// The ICS-20 precompile only lets `msg.sender` spend its own coins (sender == msg.sender), so the
/// POTATO arrives here as msg.value first and the bridge transfers *its own* balance in the same tx.
/// On timeout or error ack the refund goes to this contract (the IBC sender), not the user:
/// fine for a devnet demo, a production bridge must track and return refunds.
contract PotatoBridge {
    string public constant PORT = "transfer";
    string public constant DENOM = "apotato";

    string public channel;
    uint64 public immutable timeoutSeconds;

    event Bridged(address indexed from, string receiver, uint256 amount, uint64 sequence);

    error ZeroAmount();
    error EmptyReceiver();

    constructor(string memory channel_, uint64 timeoutSeconds_) {
        channel = channel_;
        timeoutSeconds = timeoutSeconds_;
    }

    function bridge(string calldata receiver) external payable returns (uint64 sequence) {
        if (msg.value == 0) revert ZeroAmount();
        if (bytes(receiver).length == 0) revert EmptyReceiver();

        uint64 timeoutNs = uint64((block.timestamp + timeoutSeconds) * 1e9); // IBC timeouts are unix nanoseconds
        sequence = IICS20(ICS20_PRECOMPILE).transfer(
            PORT, channel, DENOM, msg.value, address(this), receiver, Height(0, 0), timeoutNs, ""
        );
        emit Bridged(msg.sender, receiver, msg.value, sequence);
    }
}
