// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MintableERC20} from "../src/MintableERC20.sol";
import {WETH} from "../src/WETH.sol";

contract DeployScript is Script {
    function run() public {
        vm.startBroadcast();

        new MintableERC20("My Token", "MTK");
        new WETH();

        vm.stopBroadcast();
    }
}
