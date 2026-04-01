// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVToken} from "src/venus/IVenus.sol";

/// @notice Compound-style cToken mock for Venus protocol.
/// Exchange rate starts at 1:50 (0.02 underlying per vToken)
/// and accrues linearly for testing.
contract MockVToken is ERC20, IVToken {
    using SafeERC20 for IERC20;

    bool public constant isVToken = true;
    address public override underlying;

    // Exchange rate scaled by 1e18. Initial: 0.02 underlying per vToken
    uint256 public exchangeRateStored = 0.02e18;

    // Track borrows per account
    mapping(address => uint256) public borrowBalance;

    address public admin;

    error ZeroAmount();
    error InsufficientBalance();
    error NotAdmin();

    constructor(
        string memory name_,
        string memory symbol_,
        address underlying_,
        address admin_
    ) ERC20(name_, symbol_) {
        underlying = underlying_;
        admin = admin_;
    }

    /// @notice Supply underlying tokens and receive vTokens.
    /// Returns 0 on success (Compound convention).
    function mint(uint256 mintAmount) external override returns (uint256) {
        if (mintAmount == 0) revert ZeroAmount();
        IERC20(underlying).safeTransferFrom(
            msg.sender, address(this), mintAmount
        );
        uint256 vTokens = (mintAmount * 1e18) / exchangeRateStored;
        _mint(msg.sender, vTokens);
        return 0;
    }

    /// @notice Redeem vTokens for underlying.
    function redeem(
        uint256 redeemTokens
    ) external override returns (uint256) {
        if (redeemTokens == 0) revert ZeroAmount();
        uint256 underlyingAmount =
            (redeemTokens * exchangeRateStored) / 1e18;
        _burn(msg.sender, redeemTokens);
        IERC20(underlying).safeTransfer(msg.sender, underlyingAmount);
        return 0;
    }

    /// @notice Redeem a specific amount of underlying.
    function redeemUnderlying(
        uint256 redeemAmount
    ) external override returns (uint256) {
        if (redeemAmount == 0) revert ZeroAmount();
        uint256 vTokens = (redeemAmount * 1e18) / exchangeRateStored;
        _burn(msg.sender, vTokens);
        IERC20(underlying).safeTransfer(msg.sender, redeemAmount);
        return 0;
    }

    /// @notice Borrow underlying tokens.
    function borrow(
        uint256 borrowAmount
    ) external override returns (uint256) {
        if (borrowAmount == 0) revert ZeroAmount();
        borrowBalance[msg.sender] += borrowAmount;
        IERC20(underlying).safeTransfer(msg.sender, borrowAmount);
        return 0;
    }

    /// @notice Repay borrowed tokens.
    function repayBorrow(
        uint256 repayAmount
    ) external override returns (uint256) {
        if (repayAmount == 0) revert ZeroAmount();
        uint256 actual = repayAmount > borrowBalance[msg.sender]
            ? borrowBalance[msg.sender]
            : repayAmount;
        borrowBalance[msg.sender] -= actual;
        IERC20(underlying).safeTransferFrom(
            msg.sender, address(this), actual
        );
        return 0;
    }

    function balanceOfUnderlying(
        address owner
    ) external view override returns (uint256) {
        return (balanceOf(owner) * exchangeRateStored) / 1e18;
    }

    function exchangeRateCurrent()
        external
        view
        override
        returns (uint256)
    {
        return exchangeRateStored;
    }

    /// @notice Admin function to simulate interest accrual.
    function setExchangeRate(uint256 newRate) external {
        if (msg.sender != admin) revert NotAdmin();
        exchangeRateStored = newRate;
    }
}
