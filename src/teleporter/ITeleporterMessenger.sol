// SPDX-License-Identifier: LicenseRef-Ecosystem
pragma solidity 0.8.24;

struct TeleporterMessageReceipt {
    uint256 receivedMessageNonce;
    address relayerRewardAddress;
}

struct TeleporterMessageInput {
    bytes32 destinationBlockchainID;
    address destinationAddress;
    TeleporterFeeInfo feeInfo;
    uint256 requiredGasLimit;
    address[] allowedRelayerAddresses;
    bytes message;
}

struct TeleporterMessage {
    uint256 messageNonce;
    address originSenderAddress;
    bytes32 destinationBlockchainID;
    address destinationAddress;
    uint256 requiredGasLimit;
    address[] allowedRelayerAddresses;
    TeleporterMessageReceipt[] receipts;
    bytes message;
}

struct TeleporterFeeInfo {
    address feeTokenAddress;
    uint256 amount;
}

interface ITeleporterMessenger {
    event SendCrossChainMessage(
        bytes32 indexed messageID,
        bytes32 indexed destinationBlockchainID,
        TeleporterMessage message,
        TeleporterFeeInfo feeInfo
    );

    event AddFeeAmount(
        bytes32 indexed messageID,
        TeleporterFeeInfo updatedFeeInfo
    );

    event MessageExecutionFailed(
        bytes32 indexed messageID,
        bytes32 indexed sourceBlockchainID,
        TeleporterMessage message
    );

    event MessageExecuted(
        bytes32 indexed messageID,
        bytes32 indexed sourceBlockchainID
    );

    event ReceiveCrossChainMessage(
        bytes32 indexed messageID,
        bytes32 indexed sourceBlockchainID,
        address indexed deliverer,
        address rewardRedeemer,
        TeleporterMessage message
    );

    event RelayerRewardsRedeemed(
        address indexed redeemer,
        address indexed asset,
        uint256 amount
    );

    function sendCrossChainMessage(
        TeleporterMessageInput calldata messageInput
    ) external returns (bytes32);

    function retrySendCrossChainMessage(
        TeleporterMessage calldata message
    ) external;

    function addFeeAmount(
        bytes32 messageID,
        address feeTokenAddress,
        uint256 additionalFeeAmount
    ) external;

    function receiveCrossChainMessage(
        uint32 messageIndex,
        address relayerRewardAddress
    ) external;

    function retryMessageExecution(
        bytes32 sourceBlockchainID,
        TeleporterMessage calldata message
    ) external;

    function sendSpecifiedReceipts(
        bytes32 sourceBlockchainID,
        bytes32[] calldata messageIDs,
        TeleporterFeeInfo calldata feeInfo,
        address[] calldata allowedRelayerAddresses
    ) external returns (bytes32);

    function redeemRelayerRewards(
        address feeTokenAddress
    ) external;

    function getMessageHash(
        bytes32 messageID
    ) external view returns (bytes32);

    function messageReceived(
        bytes32 messageID
    ) external view returns (bool);

    function getRelayerRewardAddress(
        bytes32 messageID
    ) external view returns (address);

    function checkRelayerRewardAmount(
        address relayer,
        address feeTokenAddress
    ) external view returns (uint256);

    function getFeeInfo(
        bytes32 messageID
    ) external view returns (address, uint256);

    function getNextMessageID(
        bytes32 destinationBlockchainID
    ) external view returns (bytes32);

    function getReceiptQueueSize(
        bytes32 sourceBlockchainID
    ) external view returns (uint256);

    function getReceiptAtIndex(
        bytes32 sourceBlockchainID,
        uint256 index
    ) external view returns (TeleporterMessageReceipt memory);
}
