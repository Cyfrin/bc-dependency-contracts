// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC4626} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Mock Euler v2 vault: ERC-4626 + borrow/repay + curator role.
/// Simplified for testnet use — no oracle integration, no liquidation incentives.
contract MockEulerVault is ERC4626 {
    using SafeERC20 for IERC20;

    address public evc;
    address public curator;
    uint256 public collateralFactor = 0.8e18; // 80%

    mapping(address => uint256) public borrowBalance;
    uint256 public totalBorrows;

    error NotCurator();
    error InsufficientLiquidity();
    error ZeroAmount();

    modifier onlyCurator() {
        _onlyCurator();
        _;
    }

    constructor(
        IERC20 asset_,
        string memory name_,
        string memory symbol_,
        address evc_,
        address curator_
    ) ERC4626(asset_) ERC20(name_, symbol_) {
        evc = evc_;
        curator = curator_;
    }

    function borrow(uint256 amount) external returns (uint256) {
        if (amount == 0) revert ZeroAmount();
        uint256 available = IERC20(asset()).balanceOf(address(this));
        if (amount > available) revert InsufficientLiquidity();

        borrowBalance[msg.sender] += amount;
        totalBorrows += amount;
        IERC20(asset()).safeTransfer(msg.sender, amount);
        return 0;
    }

    function repay(uint256 amount) external returns (uint256) {
        if (amount == 0) revert ZeroAmount();
        uint256 owed = borrowBalance[msg.sender];
        uint256 actual = amount > owed ? owed : amount;

        borrowBalance[msg.sender] -= actual;
        totalBorrows -= actual;
        IERC20(asset()).safeTransferFrom(
            msg.sender, address(this), actual
        );
        return actual;
    }

    /// @notice Simplified liquidation: seize collateral shares from borrower.
    function liquidate(
        address borrower,
        uint256 repayAmount
    ) external {
        if (repayAmount == 0) revert ZeroAmount();
        uint256 owed = borrowBalance[borrower];
        uint256 actual = repayAmount > owed ? owed : repayAmount;

        borrowBalance[borrower] -= actual;
        totalBorrows -= actual;

        IERC20(asset()).safeTransferFrom(
            msg.sender, address(this), actual
        );

        // Transfer proportional vault shares to liquidator
        uint256 shares = convertToShares(actual);
        _transfer(borrower, msg.sender, shares);
    }

    function setCollateralFactor(
        uint256 newFactor
    ) external onlyCurator {
        collateralFactor = newFactor;
    }

    function setCurator(address newCurator) external onlyCurator {
        curator = newCurator;
    }

    function totalAssets()
        public
        view
        override
        returns (uint256)
    {
        return IERC20(asset()).balanceOf(address(this)) + totalBorrows;
    }

    function _onlyCurator() private view {
        if (msg.sender != curator) revert NotCurator();
    }
}
