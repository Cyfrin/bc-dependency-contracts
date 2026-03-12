// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BCSafeHarbor} from "battlechain-lib/src/BCSafeHarbor.sol";
import {Contact} from "battlechain-lib/src/types/AgreementTypes.sol";

contract DeployScript is BCSafeHarbor {
    function run(address[] calldata contracts) public {
        vm.startBroadcast();

        Contact[] memory contacts = new Contact[](1);
        contacts[0] = Contact({
            name: "Security Team",
            contact: "security@example.xyz"
        });

        address agreement = createAndAdoptAgreement(
            defaultAgreementDetails(
                "bc-dependency-contracts",
                contacts,
                contracts,
                msg.sender
            ),
            msg.sender,
            keccak256("v1")
        );

        requestAttackMode(agreement);

        vm.stopBroadcast();
    }
}
