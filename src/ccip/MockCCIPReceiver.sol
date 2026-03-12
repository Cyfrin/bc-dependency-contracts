// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Client, IAny2EVMMessageReceiver} from "src/ccip/CCIPTypes.sol";

/// @notice Base contract for CCIP message receivers.
/// Protocol teams can inherit this to test their receive logic.
abstract contract MockCCIPReceiver is IAny2EVMMessageReceiver {
    address public immutable CCIP_ROUTER;

    error OnlyRouter();

    modifier onlyRouter() {
        _onlyRouter();
        _;
    }

    constructor(address router) {
        CCIP_ROUTER = router;
    }

    function ccipReceive(
        Client.Any2EVMMessage calldata message
    ) external override onlyRouter {
        _ccipReceive(message);
    }

    function _ccipReceive(
        Client.Any2EVMMessage calldata message
    ) internal virtual;

    function supportsInterface(
        bytes4 interfaceId
    ) public pure virtual returns (bool) {
        return interfaceId ==
            type(IAny2EVMMessageReceiver).interfaceId;
    }

    function _onlyRouter() private view {
        if (msg.sender != CCIP_ROUTER) revert OnlyRouter();
    }
}
