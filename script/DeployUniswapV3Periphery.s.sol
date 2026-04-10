// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {SwapRouter} from "src/uniswap-v3/v3-periphery/SwapRouter.sol";
import {NonfungiblePositionManager} from
    "src/uniswap-v3/v3-periphery/NonfungiblePositionManager.sol";
import {console} from "forge-std/console.sol";

/// @notice Redeploys Uniswap V3 periphery contracts against an existing
/// factory. Use after updating POOL_INIT_CODE_HASH in PoolAddress.sol.
contract DeployUniswapV3Periphery is Script {
    function run(address factory, address weth) public {
        vm.startBroadcast();

        SwapRouter router = new SwapRouter(factory, weth);

        NonfungiblePositionManager nftManager =
            new NonfungiblePositionManager(factory, weth, address(0));

        vm.stopBroadcast();

        console.log("SwapRouter:", address(router));
        console.log("NonfungiblePositionManager:", address(nftManager));
    }
}
