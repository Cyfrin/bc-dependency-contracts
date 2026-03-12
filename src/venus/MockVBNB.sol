// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IVBnb} from "src/venus/IVenus.sol";

/// @notice Native ETH variant of VToken for Venus protocol.
contract MockVBNB is ERC20, IVBnb {
    uint256 public exchangeRateStored = 0.02e18;
    mapping(address => uint256) public borrowBalance;
    address public admin;

    error ZeroAmount();
    error EthTransferFailed();
    error NotAdmin();

    constructor(address admin_) ERC20("Venus BNB", "vBNB") {
        admin = admin_;
    }

    /// @notice Supply native ETH and receive vBNB.
    function mint() external payable override {
        if (msg.value == 0) revert ZeroAmount();
        uint256 vTokens = (msg.value * 1e18) / exchangeRateStored;
        _mint(msg.sender, vTokens);
    }

    function redeem(
        uint256 redeemTokens
    ) external override returns (uint256) {
        if (redeemTokens == 0) revert ZeroAmount();
        uint256 ethAmount =
            (redeemTokens * exchangeRateStored) / 1e18;
        _burn(msg.sender, redeemTokens);
        _sendEth(msg.sender, ethAmount);
        return 0;
    }

    function redeemUnderlying(
        uint256 redeemAmount
    ) external override returns (uint256) {
        if (redeemAmount == 0) revert ZeroAmount();
        uint256 vTokens = (redeemAmount * 1e18) / exchangeRateStored;
        _burn(msg.sender, vTokens);
        _sendEth(msg.sender, redeemAmount);
        return 0;
    }

    function borrow(
        uint256 borrowAmount
    ) external override returns (uint256) {
        if (borrowAmount == 0) revert ZeroAmount();
        borrowBalance[msg.sender] += borrowAmount;
        _sendEth(msg.sender, borrowAmount);
        return 0;
    }

    function repayBorrow() external payable override {
        uint256 actual = msg.value > borrowBalance[msg.sender]
            ? borrowBalance[msg.sender]
            : msg.value;
        borrowBalance[msg.sender] -= actual;
        // Refund excess
        uint256 excess = msg.value - actual;
        if (excess > 0) {
            _sendEth(msg.sender, excess);
        }
    }

    function setExchangeRate(uint256 newRate) external {
        if (msg.sender != admin) revert NotAdmin();
        exchangeRateStored = newRate;
    }

    receive() external payable {
        // Accept ETH for liquidity seeding
    }

    function _sendEth(address to, uint256 amount) private {
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert EthTransferFailed();
    }
}
