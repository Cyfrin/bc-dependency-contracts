// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IKyberSwapRouter} from "src/kyberswap/IKyberSwapRouter.sol";
import {IERC20} from
    "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Mock KyberSwap Router with configurable exchange rates.
/// Limitations:
/// - No actual DEX aggregation or routing
/// - Exchange rates are admin-set, not market-driven
/// - No multi-hop routing (single pair swaps only)
contract MockKyberSwapRouter is IKyberSwapRouter {
    using SafeERC20 for IERC20;

    // tokenIn => tokenOut => rate (output per 1e18 input, scaled 1e18)
    mapping(address => mapping(address => uint256)) public exchangeRates;

    address public admin;

    error NotAdmin();
    error NoExchangeRate();
    error InsufficientOutput();

    constructor(address _admin) {
        admin = _admin;
    }

    function setExchangeRate(
        address tokenIn,
        address tokenOut,
        uint256 rate
    ) external {
        if (msg.sender != admin) revert NotAdmin();
        exchangeRates[tokenIn][tokenOut] = rate;
    }

    function swap(
        SwapExecutionParams calldata execution
    ) external payable override returns (uint256 returnAmount, uint256) {
        SwapDescription calldata desc = execution.desc;
        returnAmount = _executeSwap(
            desc.srcToken,
            desc.dstToken,
            desc.amount,
            desc.minReturnAmount,
            desc.dstReceiver
        );
    }

    function swapSimpleMode(
        address,
        SwapDescription calldata desc,
        bytes calldata,
        bytes calldata
    ) external override returns (uint256 returnAmount) {
        returnAmount = _executeSwap(
            desc.srcToken,
            desc.dstToken,
            desc.amount,
            desc.minReturnAmount,
            desc.dstReceiver
        );
    }

    /// @notice Seed the router with tokens for swap output.
    function seedLiquidity(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function _executeSwap(
        address srcToken,
        address dstToken,
        uint256 amount,
        uint256 minReturnAmount,
        address dstReceiver
    ) private returns (uint256 returnAmount) {
        uint256 rate = exchangeRates[srcToken][dstToken];
        if (rate == 0) revert NoExchangeRate();

        returnAmount = (amount * rate) / 1e18;
        if (returnAmount < minReturnAmount) revert InsufficientOutput();

        IERC20(srcToken).safeTransferFrom(
            msg.sender, address(this), amount
        );
        IERC20(dstToken).safeTransfer(dstReceiver, returnAmount);
    }
}
