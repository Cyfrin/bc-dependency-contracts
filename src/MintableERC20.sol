// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MintableERC20 is ERC20 {
    // 0.01 tokens with 18 decimals
    uint256 public constant MINT_AMOUNT = 0.01 ether;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint() external {
        _mint(msg.sender, MINT_AMOUNT);
    }
}
