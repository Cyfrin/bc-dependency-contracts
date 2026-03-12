// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Safe} from "@safe/Safe.sol";
import {SafeL2} from "@safe/SafeL2.sol";
import {SafeProxyFactory} from
    "@safe/proxies/SafeProxyFactory.sol";
import {CreateCall} from "@safe/libraries/CreateCall.sol";
import {MultiSend} from "@safe/libraries/MultiSend.sol";
import {MultiSendCallOnly} from
    "@safe/libraries/MultiSendCallOnly.sol";
import {SignMessageLib} from
    "@safe/libraries/SignMessageLib.sol";
import {SafeToL2Setup} from
    "@safe/libraries/SafeToL2Setup.sol";
import {TokenCallbackHandler} from
    "@safe/handler/TokenCallbackHandler.sol";
import {CompatibilityFallbackHandler} from
    "@safe/handler/CompatibilityFallbackHandler.sol";
import {ExtensibleFallbackHandler} from
    "@safe/handler/ExtensibleFallbackHandler.sol";

/// @notice Deploys the full Safe smart account suite.
contract DeployScript is Script {
    function run() public {
        vm.startBroadcast();

        Safe singleton = new Safe();
        SafeL2 singletonL2 = new SafeL2();
        SafeProxyFactory proxyFactory = new SafeProxyFactory();

        CreateCall createCall = new CreateCall();
        MultiSend multiSend = new MultiSend();
        MultiSendCallOnly multiSendCallOnly =
            new MultiSendCallOnly();
        SignMessageLib signMessageLib = new SignMessageLib();
        SafeToL2Setup safeToL2Setup = new SafeToL2Setup();

        TokenCallbackHandler tokenCallback =
            new TokenCallbackHandler();
        CompatibilityFallbackHandler compatHandler =
            new CompatibilityFallbackHandler();
        ExtensibleFallbackHandler extensibleHandler =
            new ExtensibleFallbackHandler();

        vm.stopBroadcast();

        console.log("Safe:", address(singleton));
        console.log("SafeL2:", address(singletonL2));
        console.log("SafeProxyFactory:", address(proxyFactory));
        console.log("CreateCall:", address(createCall));
        console.log("MultiSend:", address(multiSend));
        console.log(
            "MultiSendCallOnly:", address(multiSendCallOnly)
        );
        console.log("SignMessageLib:", address(signMessageLib));
        console.log("SafeToL2Setup:", address(safeToL2Setup));
        console.log(
            "TokenCallbackHandler:", address(tokenCallback)
        );
        console.log(
            "CompatibilityFallbackHandler:",
            address(compatHandler)
        );
        console.log(
            "ExtensibleFallbackHandler:",
            address(extensibleHandler)
        );
    }
}
