// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {
    ITeleporterMessenger,
    TeleporterMessageInput,
    TeleporterMessage,
    TeleporterMessageReceipt,
    TeleporterFeeInfo
} from "src/teleporter/ITeleporterMessenger.sol";
import {ITeleporterReceiver} from "src/teleporter/ITeleporterReceiver.sol";
import {IERC20} from
    "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Mock TeleporterMessenger for BattleChain cross-chain dispatch and
/// explicit delivery flows.
/// @dev This is a BattleChain mock implementation. It does not recreate
/// Avalanche's canonical Teleporter messenger address or Warp precompile
/// behavior. Protocols running on BattleChain should be configured to use the
/// deployed mock teleporter address directly.
contract MockTeleporterMessenger is ITeleporterMessenger {
    using SafeERC20 for IERC20;

    struct PendingMessage {
        bytes32 destinationBlockchainID;
        address destinationAddress;
        TeleporterFeeInfo feeInfo;
        uint256 requiredGasLimit;
        address[] allowedRelayerAddresses;
        bytes message;
        address sender;
        uint256 messageNonce;
    }

    bytes32 public immutable blockchainID;
    uint256 private _nonce;

    mapping(bytes32 => bytes32) private _sentMessageHashes;
    mapping(bytes32 => bytes32) private _receivedMessageHashes;
    mapping(bytes32 => bool) private _receivedMessages;
    mapping(bytes32 => bool) private _failedMessageExecution;
    mapping(bytes32 => address) private _relayerRewardAddresses;
    mapping(bytes32 => TeleporterFeeInfo) private _messageFees;
    mapping(bytes32 => PendingMessage) private _pendingMessages;
    bytes32[] private _pendingQueue;

    address public immutable admin;

    error NotAdmin();
    error MessageNotFound(bytes32 messageID);

    constructor(address _admin, bytes32 _blockchainID) {
        admin = _admin;
        blockchainID = _blockchainID;
        emit BlockchainIDInitialized(_blockchainID);
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

        TeleporterMessage memory message = TeleporterMessage({
            messageNonce: _nonce,
            originSenderAddress: msg.sender,
            destinationBlockchainID: messageInput.destinationBlockchainID,
            destinationAddress: messageInput.destinationAddress,
            requiredGasLimit: messageInput.requiredGasLimit,
            allowedRelayerAddresses: messageInput.allowedRelayerAddresses,
            receipts: emptyReceipts,
            message: messageInput.message
        });

        _sentMessageHashes[messageID] = keccak256(abi.encode(message));
        _messageFees[messageID] = messageInput.feeInfo;
        _pendingMessages[messageID] = PendingMessage({
            destinationBlockchainID: messageInput.destinationBlockchainID,
            destinationAddress: messageInput.destinationAddress,
            feeInfo: messageInput.feeInfo,
            requiredGasLimit: messageInput.requiredGasLimit,
            allowedRelayerAddresses: messageInput.allowedRelayerAddresses,
            message: messageInput.message,
            sender: msg.sender,
            messageNonce: _nonce
        });
        _pendingQueue.push(messageID);

        emit SendCrossChainMessage(
            messageID,
            messageInput.destinationBlockchainID,
            message,
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
        if (storedHash == bytes32(0) || storedHash != keccak256(abi.encode(message))) {
            revert MessageNotFound(messageID);
        }
    }

    function addFeeAmount(
        bytes32 messageID,
        address feeTokenAddress,
        uint256 additionalFeeAmount
    ) external override {
        if (_sentMessageHashes[messageID] == bytes32(0)) {
            revert MessageNotFound(messageID);
        }

        TeleporterFeeInfo storage fee = _messageFees[messageID];
        if (fee.feeTokenAddress != feeTokenAddress) {
            revert MessageNotFound(messageID);
        }

        IERC20(feeTokenAddress).safeTransferFrom(
            msg.sender, address(this), additionalFeeAmount
        );

        fee.amount += additionalFeeAmount;
        _pendingMessages[messageID].feeInfo.amount = fee.amount;

        emit AddFeeAmount(messageID, fee);
    }

    /// @notice Admin-only stand-in for Warp-based message receiving.
    function receiveCrossChainMessage(
        uint32,
        address relayerRewardAddress
    ) external override {
        if (msg.sender != admin) revert NotAdmin();
        _nonce++;
        bytes32 fakeMessageID = _computeMessageID(blockchainID, _nonce);
        _receivedMessages[fakeMessageID] = true;
        _relayerRewardAddresses[fakeMessageID] = relayerRewardAddress;
    }

    function retryMessageExecution(
        bytes32 sourceBlockchainID,
        TeleporterMessage calldata message
    ) external override {
        bytes32 messageID = _computeMessageID(
            sourceBlockchainID, message.messageNonce
        );
        bytes32 storedHash = _receivedMessageHashes[messageID];
        if (
            storedHash == bytes32(0)
                || storedHash != keccak256(abi.encode(message))
                || !_failedMessageExecution[messageID]
        ) {
            revert MessageNotFound(messageID);
        }

        _executeMessage(messageID, sourceBlockchainID, message);
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

    function deliverMessage(
        bytes32 messageID,
        bytes32 sourceBlockchainID
    ) external {
        _deliverMessage(messageID, sourceBlockchainID, address(0));
    }

    function deliverMessage(
        bytes32 messageID,
        bytes32 sourceBlockchainID,
        address rewardRedeemer
    ) external {
        _deliverMessage(messageID, sourceBlockchainID, rewardRedeemer);
    }

    function _deliverMessage(
        bytes32 messageID,
        bytes32 sourceBlockchainID,
        address rewardRedeemer
    ) private {
        PendingMessage memory pending = _pendingMessages[messageID];
        if (pending.sender == address(0)) {
            revert MessageNotFound(messageID);
        }

        bytes32 deliveredMessageID = _computeMessageID(
            sourceBlockchainID, pending.messageNonce
        );
        TeleporterMessage memory message = _pendingToTeleporterMessage(pending);

        delete _pendingMessages[messageID];
        _removePendingMessage(messageID);

        bytes32 messageHash = keccak256(abi.encode(message));
        _receivedMessages[messageID] = true;
        _receivedMessageHashes[messageID] = messageHash;
        _relayerRewardAddresses[messageID] = rewardRedeemer;
        if (deliveredMessageID != messageID) {
            _receivedMessages[deliveredMessageID] = true;
            _receivedMessageHashes[deliveredMessageID] = messageHash;
            _relayerRewardAddresses[deliveredMessageID] = rewardRedeemer;
        }

        emit ReceiveCrossChainMessage(
            messageID,
            sourceBlockchainID,
            msg.sender,
            rewardRedeemer,
            message
        );

        _executeMessage(messageID, sourceBlockchainID, message);
    }

    function pendingMessage(
        bytes32 messageID
    ) external view returns (PendingMessage memory) {
        return _pendingMessages[messageID];
    }

    function pendingQueue() external view returns (bytes32[] memory queue) {
        queue = new bytes32[](_pendingQueue.length);
        for (uint256 i; i < _pendingQueue.length; ++i) {
            queue[i] = _pendingQueue[i];
        }
    }

    function pendingQueueForChain(
        bytes32 destinationChainID
    ) external view returns (bytes32[] memory queue) {
        uint256 count;
        for (uint256 i; i < _pendingQueue.length; ++i) {
            if (
                _pendingMessages[_pendingQueue[i]].destinationBlockchainID
                    == destinationChainID
            ) {
                ++count;
            }
        }

        queue = new bytes32[](count);
        uint256 index;
        for (uint256 i; i < _pendingQueue.length; ++i) {
            bytes32 messageID = _pendingQueue[i];
            if (
                _pendingMessages[messageID].destinationBlockchainID
                    == destinationChainID
            ) {
                queue[index] = messageID;
                ++index;
            }
        }
    }

    function _computeMessageID(
        bytes32 destinationBlockchainID,
        uint256 nonce
    ) private view returns (bytes32) {
        return keccak256(
            abi.encodePacked(blockchainID, destinationBlockchainID, nonce)
        );
    }

    function _executeMessage(
        bytes32 messageID,
        bytes32 sourceBlockchainID,
        TeleporterMessage memory message
    ) private {
        bytes32 deliveredMessageID = _computeMessageID(
            sourceBlockchainID, message.messageNonce
        );

        try ITeleporterReceiver(message.destinationAddress)
            .receiveTeleporterMessage(
                sourceBlockchainID, message.originSenderAddress, message.message
            )
        {
            _setExecutionFailureState(messageID, deliveredMessageID, false);
            emit MessageExecuted(messageID, sourceBlockchainID);
        } catch {
            _setExecutionFailureState(messageID, deliveredMessageID, true);
            emit MessageExecutionFailed(messageID, sourceBlockchainID, message);
        }
    }

    function _removePendingMessage(bytes32 messageID) private {
        for (uint256 i; i < _pendingQueue.length; ++i) {
            if (_pendingQueue[i] == messageID) {
                _pendingQueue[i] = _pendingQueue[_pendingQueue.length - 1];
                _pendingQueue.pop();
                return;
            }
        }
    }

    function _pendingToTeleporterMessage(
        PendingMessage memory pending
    ) private pure returns (TeleporterMessage memory) {
        TeleporterMessageReceipt[] memory emptyReceipts =
            new TeleporterMessageReceipt[](0);

        return TeleporterMessage({
            messageNonce: pending.messageNonce,
            originSenderAddress: pending.sender,
            destinationBlockchainID: pending.destinationBlockchainID,
            destinationAddress: pending.destinationAddress,
            requiredGasLimit: pending.requiredGasLimit,
            allowedRelayerAddresses: pending.allowedRelayerAddresses,
            receipts: emptyReceipts,
            message: pending.message
        });
    }

    function _setExecutionFailureState(
        bytes32 messageID,
        bytes32 deliveredMessageID,
        bool failed
    ) private {
        _failedMessageExecution[messageID] = failed;
        if (deliveredMessageID != messageID) {
            _failedMessageExecution[deliveredMessageID] = failed;
        }
    }
}
