// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ITeleporterReceiver {
    function receiveTeleporterMessage(
        bytes32 sourceBlockchainID,
        address originSenderAddress,
        bytes calldata message
    ) external;
}
