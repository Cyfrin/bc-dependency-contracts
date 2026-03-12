// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MintableERC20V2 is ERC20 {
    uint8 private immutable _DECIMALS;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _DECIMALS = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _DECIMALS;
    }

    /// @notice Mints 1,000,000 tokens (scaled to decimals) to caller.
    function mint() external {
        _mint(msg.sender, 1_000_000 * 10 ** _DECIMALS);
    }

    /// @notice Mints arbitrary amount to a specific address.
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
