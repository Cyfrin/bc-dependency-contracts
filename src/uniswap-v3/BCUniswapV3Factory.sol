// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import {UniswapV3Factory} from "@uniswap/v3-core/contracts/UniswapV3Factory.sol";

/// @notice UniswapV3Factory wrapper that accepts an owner parameter,
/// allowing deployment via CreateX/BCDeploy without losing ownership.
contract BCUniswapV3Factory is UniswapV3Factory {
    constructor(address _owner) {
        owner = _owner;
        emit OwnerChanged(msg.sender, _owner);
    }
}
