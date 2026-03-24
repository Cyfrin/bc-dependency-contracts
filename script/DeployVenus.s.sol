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
        address dai,
        address usdt
    ) public {
        vm.startBroadcast();

        address comptroller = bcDeployCreate(
            abi.encodePacked(
                type(MockComptroller).creationCode,
                abi.encode(msg.sender)
            )
        );

        address[] memory markets = new address[](6);
        markets[0] = bcDeployCreate(
            abi.encodePacked(
                type(MockVToken).creationCode,
                abi.encode("Venus USDC", "vUSDC", usdc, msg.sender)
            )
        );
        markets[1] = bcDeployCreate(
            abi.encodePacked(
                type(MockVToken).creationCode,
                abi.encode("Venus WETH", "vWETH", weth, msg.sender)
            )
        );
        markets[2] = bcDeployCreate(
            abi.encodePacked(
                type(MockVToken).creationCode,
                abi.encode("Venus WBTC", "vWBTC", wbtc, msg.sender)
            )
        );
        markets[3] = bcDeployCreate(
            abi.encodePacked(
                type(MockVToken).creationCode,
                abi.encode("Venus DAI", "vDAI", dai, msg.sender)
            )
        );
        markets[4] = bcDeployCreate(
            abi.encodePacked(
                type(MockVBNB).creationCode,
                abi.encode(msg.sender)
            )
        );
        markets[5] = bcDeployCreate(
            abi.encodePacked(
                type(MockVToken).creationCode,
                abi.encode("Venus USDT", "vUSDT", usdt, msg.sender)
            )
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
        console.log("vUSDT:", markets[5]);
    }
}
