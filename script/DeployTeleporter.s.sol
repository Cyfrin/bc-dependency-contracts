// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BCDeploy} from "battlechain-lib/src/BCDeploy.sol";
import {MockTeleporterMessenger} from
    "src/teleporter/MockTeleporterMessenger.sol";
import {console} from "forge-std/console.sol";

/// @notice Deploys mock Teleporter Messenger for cross-chain message
/// testing.
/// Limitations:
/// - No actual cross-chain delivery (requires Avalanche Warp Messaging)
/// - receiveCrossChainMessage is admin-only (no Warp precompile)
/// - Deploys to a new address, NOT the canonical 0x253b...5fcf
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
