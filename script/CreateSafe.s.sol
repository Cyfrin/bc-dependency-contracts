// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Safe} from "@safe/Safe.sol";
import {SafeProxy} from "@safe/proxies/SafeProxy.sol";
import {SafeProxyFactory} from
    "@safe/proxies/SafeProxyFactory.sol";

/// @notice Creates a Safe proxy with a single 1-of-1 owner.
contract CreateSafe is Script {
    function run(
        address owner,
        address factory,
        address singleton,
        address fallbackHandler,
        uint256 saltNonce
    ) public {
        address[] memory owners = new address[](1);
        owners[0] = owner;

        bytes memory initializer = abi.encodeCall(
            Safe.setup,
            (
                owners,
                1,
                address(0),
                "",
                fallbackHandler,
                address(0),
                0,
                payable(address(0))
            )
        );

        vm.startBroadcast();
        SafeProxy proxy = SafeProxyFactory(factory)
            .createProxyWithNonce(singleton, initializer, saltNonce);
        vm.stopBroadcast();

        Safe safe = Safe(payable(address(proxy)));
        require(safe.isOwner(owner), "owner not set");
        require(safe.getThreshold() == 1, "threshold not 1");

        console.log("Safe created:", address(proxy));
        console.log("Owner:", owner);
        console.log("Threshold: 1");
    }
}
