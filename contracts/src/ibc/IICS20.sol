// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Subset of cosmos/evm v0.7.3 precompiles/ics20/ICS20I.sol that we use.
address constant ICS20_PRECOMPILE = 0x0000000000000000000000000000000000000802;

struct Height {
    uint64 revisionNumber;
    uint64 revisionHeight;
}

interface IICS20 {
    /// @dev Reverts unless `sender == msg.sender` (checked by the precompile).
    function transfer(
        string memory sourcePort,
        string memory sourceChannel,
        string memory denom,
        uint256 amount,
        address sender,
        string memory receiver,
        Height memory timeoutHeight,
        uint64 timeoutTimestamp,
        string memory memo
    ) external returns (uint64 nextSequence);
}
