// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BCDeploy} from "battlechain-lib/src/BCDeploy.sol";
import {MintableERC20} from "src/MintableERC20.sol";
import {MintableERC20V2} from "src/MintableERC20V2.sol";
import {WETH} from "src/WETH.sol";
import {console} from "forge-std/console.sol";

contract DeployScript is BCDeploy {
    function run() public {
        vm.startBroadcast();

        address mtk = bcDeployCreate(
            abi.encodePacked(
                type(MintableERC20).creationCode,
                abi.encode("My Token", "MTK")
            )
        );
        address weth = bcDeployCreate(type(WETH).creationCode);

        address usdc = bcDeployCreate(
            abi.encodePacked(
                type(MintableERC20V2).creationCode,
                abi.encode("USD Coin", "USDC", uint8(6))
            )
        );
        address usdt = bcDeployCreate(
            abi.encodePacked(
                type(MintableERC20V2).creationCode,
                abi.encode("Tether USD", "USDT", uint8(6))
            )
        );
        address dai = bcDeployCreate(
            abi.encodePacked(
                type(MintableERC20V2).creationCode,
                abi.encode("Dai Stablecoin", "DAI", uint8(18))
            )
        );
        address wbtc = bcDeployCreate(
            abi.encodePacked(
                type(MintableERC20V2).creationCode,
                abi.encode("Wrapped BTC", "WBTC", uint8(8))
            )
        );
        address link = bcDeployCreate(
            abi.encodePacked(
                type(MintableERC20V2).creationCode,
                abi.encode("Chainlink Token", "LINK", uint8(18))
            )
        );

        vm.stopBroadcast();

        console.log("MTK:", mtk);
        console.log("WETH:", weth);
        console.log("USDC:", usdc);
        console.log("USDT:", usdt);
        console.log("DAI:", dai);
        console.log("WBTC:", wbtc);
        console.log("LINK:", link);
    }
}
