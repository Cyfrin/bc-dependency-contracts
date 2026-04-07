// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BCDeploy} from "battlechain-lib/src/BCDeploy.sol";
import {MockTeleporterMessenger} from
    "src/teleporter/MockTeleporterMessenger.sol";
import {console} from "forge-std/console.sol";

/// @notice Deploys mock Teleporter Messenger for cross-chain message
/// testing.
/// Limitations:
/// - No actual Avalanche Warp Messaging or canonical Teleporter verification
/// - Cross-chain delivery must be simulated through the mock's explicit
///   delivery helpers
/// - `receiveCrossChainMessage` is admin-only because BattleChain does not have
///   the Warp precompile / validator flow
contract DeployScript is BCDeploy {
    function run(bytes32 blockchainID) public {
        vm.startBroadcast();

        address messenger = bcDeployCreate(
            abi.encodePacked(
                type(MockTeleporterMessenger).creationCode,
                abi.encode(msg.sender, blockchainID)
            )
        );

        vm.stopBroadcast();

        console.log("MockTeleporterMessenger:", messenger);
    }
}
