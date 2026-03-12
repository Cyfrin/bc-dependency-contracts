// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ISwapRouter} from "src/uniswap-v3/ISwapRouter.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Mock SwapRouter with configurable exchange rates.
/// Fallback for Uniswap V3 if bytecode deploy hits EVM incompatibility.
contract MockSwapRouter is ISwapRouter {
    using SafeERC20 for IERC20;

    // tokenIn => tokenOut => rate (output per 1e18 input, scaled by 1e18)
    mapping(address => mapping(address => uint256)) public exchangeRates;

    address public admin;

    error NotAdmin();
    error DeadlineExpired();
    error NoExchangeRate();
    error InsufficientOutput();
    error ExcessiveInput();

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setExchangeRate(
        address tokenIn,
        address tokenOut,
        uint256 rate
    ) external onlyAdmin {
        exchangeRates[tokenIn][tokenOut] = rate;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable override returns (uint256 amountOut) {
        if (block.timestamp > params.deadline) {
            revert DeadlineExpired();
        }
        uint256 rate = exchangeRates[params.tokenIn][params.tokenOut];
        if (rate == 0) revert NoExchangeRate();

        amountOut = (params.amountIn * rate) / 1e18;
        if (amountOut < params.amountOutMinimum) {
            revert InsufficientOutput();
        }

        IERC20(params.tokenIn).safeTransferFrom(
            msg.sender, address(this), params.amountIn
        );
        IERC20(params.tokenOut).safeTransfer(
            params.recipient, amountOut
        );
    }

    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable override returns (uint256 amountIn) {
        if (block.timestamp > params.deadline) {
            revert DeadlineExpired();
        }
        uint256 rate = exchangeRates[params.tokenIn][params.tokenOut];
        if (rate == 0) revert NoExchangeRate();

        amountIn = (params.amountOut * 1e18 + rate - 1) / rate;
        if (amountIn > params.amountInMaximum) {
            revert ExcessiveInput();
        }

        IERC20(params.tokenIn).safeTransferFrom(
            msg.sender, address(this), amountIn
        );
        IERC20(params.tokenOut).safeTransfer(
            params.recipient, params.amountOut
        );
    }

    function exactInput(
        ExactInputParams calldata
    ) external payable override returns (uint256) {
        revert("MockSwapRouter: multi-hop not supported");
    }

    function exactOutput(
        ExactOutputParams calldata
    ) external payable override returns (uint256) {
        revert("MockSwapRouter: multi-hop not supported");
    }

    /// @notice Seed the router with tokens for swap output.
    function seedLiquidity(
        address token,
        uint256 amount
    ) external {
        IERC20(token).safeTransferFrom(
            msg.sender, address(this), amount
        );
    }

    function _onlyAdmin() private view {
        if (msg.sender != admin) revert NotAdmin();
    }
}
