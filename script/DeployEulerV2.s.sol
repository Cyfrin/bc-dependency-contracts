// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BCDeploy} from "battlechain-lib/src/BCDeploy.sol";
import {MockEVC} from "src/euler-v2/MockEVC.sol";
import {MockEulerVault} from "src/euler-v2/MockEulerVault.sol";
import {console} from "forge-std/console.sol";

/// @notice Deploys Euler V2 mock: EVC + vaults for USDC and WETH.
contract DeployScript is BCDeploy {
    function run(address usdc, address weth) public {
        vm.startBroadcast();

        address evc = bcDeployCreate(type(MockEVC).creationCode);

        address usdcVault = bcDeployCreate(
            abi.encodePacked(
                type(MockEulerVault).creationCode,
                abi.encode(
                    usdc,
                    "Euler USDC Vault",
                    "eUSDC",
                    evc,
                    msg.sender
                )
            )
        );

        address wethVault = bcDeployCreate(
            abi.encodePacked(
                type(MockEulerVault).creationCode,
                abi.encode(
                    weth,
                    "Euler WETH Vault",
                    "eWETH",
                    evc,
                    msg.sender
                )
            )
        );

        vm.stopBroadcast();

        console.log("EVC:", evc);
        console.log("eUSDC Vault:", usdcVault);
        console.log("eWETH Vault:", wethVault);
    }
}
