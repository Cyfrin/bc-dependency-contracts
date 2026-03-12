// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Client, IRouterClient} from "src/ccip/CCIPTypes.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Mock CCIP Router for testing message encoding/dispatch.
/// Limitations:
/// - No actual cross-chain message delivery
/// - No DON validation
/// - Fee collection accepts LINK/native but doesn't route
contract MockCCIPRouter is IRouterClient {
    using SafeERC20 for IERC20;

    uint64 public constant MOCK_FEE = 0.1e18; // 0.1 LINK or native
    uint256 private _nonce;

    mapping(uint64 => bool) public supportedChains;

    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address sender,
        bytes receiver,
        bytes data,
        uint256 fee
    );

    address public admin;

    error NotAdmin();

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function addSupportedChain(uint64 chainSelector) external onlyAdmin {
        supportedChains[chainSelector] = true;
    }

    function removeSupportedChain(
        uint64 chainSelector
    ) external onlyAdmin {
        supportedChains[chainSelector] = false;
    }

    function isChainSupported(
        uint64 chainSelector
    ) external view override returns (bool) {
        return supportedChains[chainSelector];
    }

    function getFee(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage memory
    ) external view override returns (uint256) {
        if (!supportedChains[destinationChainSelector]) {
            revert UnsupportedDestinationChain(
                destinationChainSelector
            );
        }
        return MOCK_FEE;
    }

    function ccipSend(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage calldata message
    ) external payable override returns (bytes32) {
        if (!supportedChains[destinationChainSelector]) {
            revert UnsupportedDestinationChain(
                destinationChainSelector
            );
        }

        // Collect fee
        if (message.feeToken == address(0)) {
            if (msg.value < MOCK_FEE) {
                revert InsufficientFeeTokenAmount();
            }
        } else {
            IERC20(message.feeToken).safeTransferFrom(
                msg.sender, address(this), MOCK_FEE
            );
        }

        _nonce++;
        bytes32 messageId;
        // forge-lint: disable-next-line(asm-keccak256)
        assembly {
            let fmp := mload(0x40)
            mstore(fmp, chainid())
            mstore(add(fmp, 0x20), destinationChainSelector)
            mstore(add(fmp, 0x40), caller())
            mstore(add(fmp, 0x60), sload(_nonce.slot))
            messageId := keccak256(fmp, 0x80)
        }

        emit MessageSent(
            messageId,
            destinationChainSelector,
            msg.sender,
            message.receiver,
            message.data,
            MOCK_FEE
        );

        return messageId;
    }

    receive() external payable {}

    function _onlyAdmin() private view {
        if (msg.sender != admin) revert NotAdmin();
    }
}
