// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BCDeploy} from "battlechain-lib/src/BCDeploy.sol";
import {MockKyberSwapRouter} from
    "src/kyberswap/MockKyberSwapRouter.sol";
import {console} from "forge-std/console.sol";

/// @notice Deploys mock KyberSwap Router for swap testing.
/// Limitations:
/// - No actual DEX aggregation or routing
/// - Exchange rates are admin-set, not market-driven
contract DeployScript is BCDeploy {
    function run() public {
        vm.startBroadcast();

        address router = bcDeployCreate(
            abi.encodePacked(
                type(MockKyberSwapRouter).creationCode,
                abi.encode(msg.sender)
            )
        );

        vm.stopBroadcast();

        console.log("MockKyberSwapRouter:", router);
    }
}
