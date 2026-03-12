// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BCDeploy} from "battlechain-lib/src/BCDeploy.sol";
import {MockSwapRouter} from "src/uniswap-v3/MockSwapRouter.sol";
import {console} from "forge-std/console.sol";

/// @notice Deploys Uniswap V3 mock swap router.
/// Real V3 contracts are Solidity 0.7.6 — cannot compile alongside 0.8.24.
/// This deploys the mock fallback router with configurable exchange rates.
/// If bytecode deploy becomes viable, replace this script.
contract DeployScript is BCDeploy {
    function run() public {
        vm.startBroadcast();

        address router = bcDeployCreate(
            type(MockSwapRouter).creationCode
        );

        vm.stopBroadcast();

        console.log("MockSwapRouter:", router);
    }
}
