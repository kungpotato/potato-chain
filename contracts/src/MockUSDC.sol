// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// Dev-only stablecoin stand-in. 6 decimals like real USDC, so price math bugs
/// (18 vs 6 decimals) show up on devnet instead of later.
contract MockUSDC is ERC20, Ownable {
    constructor(address owner_) ERC20("Mock USD Coin", "USDC") Ownable(owner_) {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
