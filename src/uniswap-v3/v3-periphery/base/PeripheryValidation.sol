// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;

import "src/uniswap-v3/v3-periphery/base/BlockTimestamp.sol";

abstract contract PeripheryValidation is BlockTimestamp {
    modifier checkDeadline(uint256 deadline) {
        require(_blockTimestamp() <= deadline, 'Transaction too old');
        _;
    }
}
