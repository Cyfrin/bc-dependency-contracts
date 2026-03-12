// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BCDeploy} from "battlechain-lib/src/BCDeploy.sol";
import {MockV3Aggregator} from "src/MockChainlink.sol";
import {console} from "forge-std/console.sol";

contract DeployScript is BCDeploy {
    uint8 constant FEED_DECIMALS = 8;

    function run() public {
        vm.startBroadcast();

        address ethUsd = bcDeployCreate(
            abi.encodePacked(
                type(MockV3Aggregator).creationCode,
                abi.encode(FEED_DECIMALS, int256(2000e8))
            )
        );
        address btcUsd = bcDeployCreate(
            abi.encodePacked(
                type(MockV3Aggregator).creationCode,
                abi.encode(FEED_DECIMALS, int256(60_000e8))
            )
        );
        address linkUsd = bcDeployCreate(
            abi.encodePacked(
                type(MockV3Aggregator).creationCode,
                abi.encode(FEED_DECIMALS, int256(15e8))
            )
        );
        address usdcUsd = bcDeployCreate(
            abi.encodePacked(
                type(MockV3Aggregator).creationCode,
                abi.encode(FEED_DECIMALS, int256(1e8))
            )
        );

        vm.stopBroadcast();

        console.log("ETH/USD:", ethUsd);
        console.log("BTC/USD:", btcUsd);
        console.log("LINK/USD:", linkUsd);
        console.log("USDC/USD:", usdcUsd);
    }
}
