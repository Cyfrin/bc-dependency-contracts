// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {UniswapV3Pool} from
    "src/uniswap-v3/v3-core/UniswapV3Pool.sol";

contract ComputePoolInitCodeHash is Script {
    function run() public pure {
        bytes32 hash = keccak256(type(UniswapV3Pool).creationCode);
        console.log("POOL_INIT_CODE_HASH:");
        console.logBytes32(hash);
    }
}
