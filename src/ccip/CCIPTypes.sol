// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @notice CCIP message types matching Chainlink's interface.
/// Struct names intentionally match Chainlink's naming convention.
/// forge-lint: disable-start(pascal-case-struct)
library Client {
    struct EVMTokenAmount {
        address token;
        uint256 amount;
    }

    struct EVM2AnyMessage {
        bytes receiver;
        bytes data;
        EVMTokenAmount[] tokenAmounts;
        address feeToken; // address(0) for native
        bytes extraArgs;
    }

    struct Any2EVMMessage {
        bytes32 messageId;
        uint64 sourceChainSelector;
        bytes sender;
        bytes data;
        EVMTokenAmount[] destTokenAmounts;
    }
}
// forge-lint: disable-end(pascal-case-struct)

interface IRouterClient {
    error UnsupportedDestinationChain(uint64 destChainSelector);
    error InsufficientFeeTokenAmount();

    function isChainSupported(
        uint64 chainSelector
    ) external view returns (bool);

    function getFee(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage memory message
    ) external view returns (uint256 fee);

    function ccipSend(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage calldata message
    ) external payable returns (bytes32);
}

interface IAny2EVMMessageReceiver {
    function ccipReceive(
        Client.Any2EVMMessage calldata message
    ) external;
}
