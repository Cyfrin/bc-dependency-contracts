// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {UniswapV3Factory} from "src/uniswap-v3/v3-core/UniswapV3Factory.sol";
import {SwapRouter} from "src/uniswap-v3/v3-periphery/SwapRouter.sol";
import {NonfungiblePositionManager} from "src/uniswap-v3/v3-periphery/NonfungiblePositionManager.sol";
import {console} from "forge-std/console.sol";

/// @notice Deploys Uniswap V3 core + periphery contracts
/// directly (no CreateX) to avoid factory gas limits.
contract DeployScript is Script {
    function run(address weth) public {
        vm.startBroadcast();

        UniswapV3Factory factory = new UniswapV3Factory();

        SwapRouter router = new SwapRouter(address(factory), weth);

        NonfungiblePositionManager nftManager = new NonfungiblePositionManager(address(factory), weth, address(0));

        vm.stopBroadcast();

        console.log("UniswapV3Factory:", address(factory));
        console.log("SwapRouter:", address(router));
        console.log("NonfungiblePositionManager:", address(nftManager));
    }
}
