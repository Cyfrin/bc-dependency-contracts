// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MintableERC20 is ERC20 {
    // 0.01 tokens with 18 decimals
    uint256 public constant MINT_AMOUNT = 0.01 ether;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint() external {
        _mint(msg.sender, MINT_AMOUNT);
    }
}
