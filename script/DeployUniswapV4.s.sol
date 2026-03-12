// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BCDeploy} from "battlechain-lib/src/BCDeploy.sol";
import {PoolManager} from "v4-core/src/PoolManager.sol";
import {console} from "forge-std/console.sol";

/// @notice Deploys Uniswap V4 PoolManager singleton.
contract DeployScript is BCDeploy {
    function run() public {
        vm.startBroadcast();

        address poolManager = bcDeployCreate(
            abi.encodePacked(
                type(PoolManager).creationCode,
                abi.encode(msg.sender)
            )
        );

        vm.stopBroadcast();

        console.log("PoolManager:", poolManager);
    }
}
