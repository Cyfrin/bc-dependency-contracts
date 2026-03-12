// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BCDeploy} from "battlechain-lib/src/BCDeploy.sol";
import {MockComptroller} from "src/venus/MockComptroller.sol";
import {MockVToken} from "src/venus/MockVToken.sol";
import {MockVBNB} from "src/venus/MockVBNB.sol";
import {console} from "forge-std/console.sol";

/// @notice Deploys Venus mock: Comptroller + VToken markets.
contract DeployScript is BCDeploy {
    uint256 constant COLLATERAL_FACTOR = 0.75e18;

    function run(
        address usdc,
        address weth,
        address wbtc,
        address dai
    ) public {
        vm.startBroadcast();

        address comptroller = bcDeployCreate(
            type(MockComptroller).creationCode
        );

        address[] memory markets = new address[](5);
        markets[0] = bcDeployCreate(
            abi.encodePacked(
                type(MockVToken).creationCode,
                abi.encode("Venus USDC", "vUSDC", usdc)
            )
        );
        markets[1] = bcDeployCreate(
            abi.encodePacked(
                type(MockVToken).creationCode,
                abi.encode("Venus WETH", "vWETH", weth)
            )
        );
        markets[2] = bcDeployCreate(
            abi.encodePacked(
                type(MockVToken).creationCode,
                abi.encode("Venus WBTC", "vWBTC", wbtc)
            )
        );
        markets[3] = bcDeployCreate(
            abi.encodePacked(
                type(MockVToken).creationCode,
                abi.encode("Venus DAI", "vDAI", dai)
            )
        );
        markets[4] = bcDeployCreate(
            type(MockVBNB).creationCode
        );

        for (uint256 i; i < markets.length; i++) {
            MockComptroller(comptroller).listMarket(
                markets[i], COLLATERAL_FACTOR
            );
        }

        vm.stopBroadcast();

        console.log("Comptroller:", comptroller);
        console.log("vUSDC:", markets[0]);
        console.log("vWETH:", markets[1]);
        console.log("vWBTC:", markets[2]);
        console.log("vDAI:", markets[3]);
        console.log("vBNB:", markets[4]);
    }
}
