// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BCDeploy} from "battlechain-lib/src/BCDeploy.sol";
import {MockCCIPRouter} from "src/ccip/MockCCIPRouter.sol";
import {console} from "forge-std/console.sol";

/// @notice Deploys mock CCIP Router for cross-chain message testing.
/// Limitations:
/// - No actual cross-chain message delivery (requires off-chain DON)
/// - Fee collection is a no-op (accepts LINK but doesn't route)
/// - No DON validation
contract DeployScript is BCDeploy {
    function run() public {
        vm.startBroadcast();

        address router = bcDeployCreate(
            abi.encodePacked(
                type(MockCCIPRouter).creationCode,
                abi.encode(msg.sender)
            )
        );

        vm.stopBroadcast();

        console.log("MockCCIPRouter:", router);
    }
}
