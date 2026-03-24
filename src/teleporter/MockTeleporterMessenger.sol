// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {
    ITeleporterMessenger,
    TeleporterMessageInput,
    TeleporterMessage,
    TeleporterMessageReceipt,
    TeleporterFeeInfo
} from "src/teleporter/ITeleporterMessenger.sol";
import {IERC20} from
    "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Mock TeleporterMessenger for testing cross-chain message
/// encoding/dispatch on BattleChain.
/// Limitations:
/// - No actual cross-chain delivery (requires Avalanche Warp Messaging)
/// - receiveCrossChainMessage is admin-only (no Warp precompile)
/// - Fee collection accepts tokens but doesn't route to relayers
contract MockTeleporterMessenger is ITeleporterMessenger {
    using SafeERC20 for IERC20;

    bytes32 public immutable blockchainID;
    uint256 private _nonce;

    mapping(bytes32 => bytes32) private _sentMessageHashes;
    mapping(bytes32 => bool) private _receivedMessages;
    mapping(bytes32 => address) private _relayerRewardAddresses;
    mapping(bytes32 => TeleporterFeeInfo) private _messageFees;

    address public immutable admin;

    error NotAdmin();
    error MessageNotFound(bytes32 messageID);

    constructor(address _admin, bytes32 _blockchainID) {
        admin = _admin;
        blockchainID = _blockchainID;
    }

    function sendCrossChainMessage(
        TeleporterMessageInput calldata messageInput
    ) external override returns (bytes32) {
        if (
            messageInput.feeInfo.feeTokenAddress != address(0)
                && messageInput.feeInfo.amount > 0
        ) {
            IERC20(messageInput.feeInfo.feeTokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                messageInput.feeInfo.amount
            );
        }

        _nonce++;

        bytes32 messageID = _computeMessageID(
            messageInput.destinationBlockchainID, _nonce
        );

        TeleporterMessageReceipt[] memory emptyReceipts =
            new TeleporterMessageReceipt[](0);

        TeleporterMessage memory teleporterMessage = TeleporterMessage({
            messageNonce: _nonce,
            originSenderAddress: msg.sender,
            destinationBlockchainID: messageInput.destinationBlockchainID,
            destinationAddress: messageInput.destinationAddress,
            requiredGasLimit: messageInput.requiredGasLimit,
            allowedRelayerAddresses: messageInput.allowedRelayerAddresses,
            receipts: emptyReceipts,
            message: messageInput.message
        });

        _sentMessageHashes[messageID] =
            keccak256(abi.encode(teleporterMessage));
        _messageFees[messageID] = messageInput.feeInfo;

        emit SendCrossChainMessage(
            messageID,
            messageInput.destinationBlockchainID,
            teleporterMessage,
            messageInput.feeInfo
        );

        return messageID;
    }

    function retrySendCrossChainMessage(
        TeleporterMessage calldata message
    ) external view override {
        bytes32 messageID = _computeMessageID(
            message.destinationBlockchainID, message.messageNonce
        );
        bytes32 storedHash = _sentMessageHashes[messageID];
        if (storedHash == bytes32(0)) revert MessageNotFound(messageID);
    }

    function addFeeAmount(
        bytes32 messageID,
        address feeTokenAddress,
        uint256 additionalFeeAmount
    ) external override {
        if (_sentMessageHashes[messageID] == bytes32(0)) {
            revert MessageNotFound(messageID);
        }

        IERC20(feeTokenAddress).safeTransferFrom(
            msg.sender, address(this), additionalFeeAmount
        );

        TeleporterFeeInfo storage fee = _messageFees[messageID];
        fee.amount += additionalFeeAmount;

        emit AddFeeAmount(messageID, fee);
    }

    /// @notice Admin-only stand-in for Warp-based message receiving.
    function receiveCrossChainMessage(
        uint32,
        address relayerRewardAddress
    ) external override {
        if (msg.sender != admin) revert NotAdmin();
        bytes32 fakeMessageID = _computeMessageID(blockchainID, _nonce + 1);
        _receivedMessages[fakeMessageID] = true;
        _relayerRewardAddresses[fakeMessageID] = relayerRewardAddress;
    }

    function retryMessageExecution(
        bytes32 sourceBlockchainID,
        TeleporterMessage calldata message
    ) external view override {
        bytes32 messageID = _computeMessageID(
            sourceBlockchainID, message.messageNonce
        );
        if (!_receivedMessages[messageID]) {
            revert MessageNotFound(messageID);
        }
    }

    function sendSpecifiedReceipts(
        bytes32,
        bytes32[] calldata,
        TeleporterFeeInfo calldata,
        address[] calldata
    ) external override returns (bytes32) {
        _nonce++;
        return _computeMessageID(blockchainID, _nonce);
    }

    function redeemRelayerRewards(
        address feeTokenAddress
    ) external override {
        uint256 balance = IERC20(feeTokenAddress).balanceOf(address(this));
        if (balance > 0) {
            IERC20(feeTokenAddress).safeTransfer(msg.sender, balance);
            emit RelayerRewardsRedeemed(
                msg.sender, feeTokenAddress, balance
            );
        }
    }

    function getMessageHash(
        bytes32 messageID
    ) external view override returns (bytes32) {
        return _sentMessageHashes[messageID];
    }

    function messageReceived(
        bytes32 messageID
    ) external view override returns (bool) {
        return _receivedMessages[messageID];
    }

    function getRelayerRewardAddress(
        bytes32 messageID
    ) external view override returns (address) {
        return _relayerRewardAddresses[messageID];
    }

    function checkRelayerRewardAmount(
        address,
        address feeTokenAddress
    ) external view override returns (uint256) {
        return IERC20(feeTokenAddress).balanceOf(address(this));
    }

    function getFeeInfo(
        bytes32 messageID
    ) external view override returns (address, uint256) {
        TeleporterFeeInfo storage fee = _messageFees[messageID];
        return (fee.feeTokenAddress, fee.amount);
    }

    function getNextMessageID(
        bytes32 destinationBlockchainID
    ) external view override returns (bytes32) {
        return _computeMessageID(destinationBlockchainID, _nonce + 1);
    }

    function getReceiptQueueSize(
        bytes32
    ) external pure override returns (uint256) {
        return 0;
    }

    function getReceiptAtIndex(
        bytes32,
        uint256
    ) external pure override returns (TeleporterMessageReceipt memory) {
        return TeleporterMessageReceipt({
            receivedMessageNonce: 0,
            relayerRewardAddress: address(0)
        });
    }

    function _computeMessageID(
        bytes32 destinationBlockchainID,
        uint256 nonce
    ) private view returns (bytes32) {
        return keccak256(
            abi.encodePacked(blockchainID, destinationBlockchainID, nonce)
        );
    }
}
