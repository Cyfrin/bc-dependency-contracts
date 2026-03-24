// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {
    IMorpho,
    Id,
    MarketParams,
    Position,
    Market,
    MarketParamsLib
} from "src/morpho/IMorpho.sol";
import {IERC20} from
    "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Mock Morpho Blue for testing lending/borrowing on BattleChain.
/// Limitations:
/// - No interest accrual (rates are always zero)
/// - No oracle price checks (liquidation is admin-gated)
/// - 1:1 share-to-asset ratio (no share price divergence)
/// - No flash loan callback verification
contract MockMorpho is IMorpho {
    using SafeERC20 for IERC20;
    using MarketParamsLib for MarketParams;

    address public override owner;
    address public override feeRecipient;

    mapping(address => bool) public override isIrmEnabled;
    mapping(uint256 => bool) public override isLltvEnabled;

    mapping(Id => Market) private _markets;
    mapping(Id => MarketParams) private _idToMarketParams;
    mapping(Id => mapping(address => Position)) private _positions;

    error NotOwner();
    error MarketNotCreated();
    error MarketAlreadyCreated();
    error InsufficientBalance();

    constructor(address _owner) {
        owner = _owner;
    }

    function setOwner(address newOwner) external override {
        if (msg.sender != owner) revert NotOwner();
        owner = newOwner;
    }

    function enableIrm(address irm) external override {
        if (msg.sender != owner) revert NotOwner();
        isIrmEnabled[irm] = true;
    }

    function enableLltv(uint256 lltv) external override {
        if (msg.sender != owner) revert NotOwner();
        isLltvEnabled[lltv] = true;
    }

    function setFee(
        MarketParams memory marketParams,
        uint256 newFee
    ) external override {
        if (msg.sender != owner) revert NotOwner();
        Id marketId = marketParams.id();
        if (_markets[marketId].lastUpdate == 0) {
            revert MarketNotCreated();
        }
        _markets[marketId].fee = uint128(newFee);
    }

    function setFeeRecipient(
        address newFeeRecipient
    ) external override {
        if (msg.sender != owner) revert NotOwner();
        feeRecipient = newFeeRecipient;
    }

    function createMarket(
        MarketParams memory marketParams
    ) external override {
        Id marketId = marketParams.id();
        if (_markets[marketId].lastUpdate != 0) {
            revert MarketAlreadyCreated();
        }
        _markets[marketId].lastUpdate = uint128(block.timestamp);
        _idToMarketParams[marketId] = marketParams;
    }

    function supply(
        MarketParams memory marketParams,
        uint256 assets,
        uint256,
        address onBehalf,
        bytes memory
    )
        external
        override
        returns (uint256 assetsSupplied, uint256 sharesSupplied)
    {
        Id marketId = marketParams.id();
        if (_markets[marketId].lastUpdate == 0) {
            revert MarketNotCreated();
        }

        assetsSupplied = assets;
        sharesSupplied = assets;

        _positions[marketId][onBehalf].supplyShares += assets;
        _markets[marketId].totalSupplyAssets += uint128(assets);
        _markets[marketId].totalSupplyShares += uint128(assets);

        IERC20(marketParams.loanToken).safeTransferFrom(
            msg.sender, address(this), assets
        );
    }

    function withdraw(
        MarketParams memory marketParams,
        uint256 assets,
        uint256,
        address onBehalf,
        address receiver
    )
        external
        override
        returns (uint256 assetsWithdrawn, uint256 sharesWithdrawn)
    {
        Id marketId = marketParams.id();
        if (_markets[marketId].lastUpdate == 0) {
            revert MarketNotCreated();
        }
        if (_positions[marketId][onBehalf].supplyShares < assets) {
            revert InsufficientBalance();
        }

        assetsWithdrawn = assets;
        sharesWithdrawn = assets;

        _positions[marketId][onBehalf].supplyShares -= assets;
        _markets[marketId].totalSupplyAssets -= uint128(assets);
        _markets[marketId].totalSupplyShares -= uint128(assets);

        IERC20(marketParams.loanToken).safeTransfer(receiver, assets);
    }

    function borrow(
        MarketParams memory marketParams,
        uint256 assets,
        uint256,
        address onBehalf,
        address receiver
    )
        external
        override
        returns (uint256 assetsBorrowed, uint256 sharesBorrowed)
    {
        Id marketId = marketParams.id();
        if (_markets[marketId].lastUpdate == 0) {
            revert MarketNotCreated();
        }

        assetsBorrowed = assets;
        sharesBorrowed = assets;

        _positions[marketId][onBehalf].borrowShares += uint128(assets);
        _markets[marketId].totalBorrowAssets += uint128(assets);
        _markets[marketId].totalBorrowShares += uint128(assets);

        IERC20(marketParams.loanToken).safeTransfer(receiver, assets);
    }

    function repay(
        MarketParams memory marketParams,
        uint256 assets,
        uint256,
        address onBehalf,
        bytes memory
    )
        external
        override
        returns (uint256 assetsRepaid, uint256 sharesRepaid)
    {
        Id marketId = marketParams.id();
        if (_markets[marketId].lastUpdate == 0) {
            revert MarketNotCreated();
        }

        assetsRepaid = assets;
        sharesRepaid = assets;

        _positions[marketId][onBehalf].borrowShares -= uint128(assets);
        _markets[marketId].totalBorrowAssets -= uint128(assets);
        _markets[marketId].totalBorrowShares -= uint128(assets);

        IERC20(marketParams.loanToken).safeTransferFrom(
            msg.sender, address(this), assets
        );
    }

    function supplyCollateral(
        MarketParams memory marketParams,
        uint256 assets,
        address onBehalf,
        bytes memory
    ) external override {
        Id marketId = marketParams.id();
        if (_markets[marketId].lastUpdate == 0) {
            revert MarketNotCreated();
        }

        _positions[marketId][onBehalf].collateral += uint128(assets);

        IERC20(marketParams.collateralToken).safeTransferFrom(
            msg.sender, address(this), assets
        );
    }

    function withdrawCollateral(
        MarketParams memory marketParams,
        uint256 assets,
        address onBehalf,
        address receiver
    ) external override {
        Id marketId = marketParams.id();
        if (_markets[marketId].lastUpdate == 0) {
            revert MarketNotCreated();
        }
        if (_positions[marketId][onBehalf].collateral < assets) {
            revert InsufficientBalance();
        }

        _positions[marketId][onBehalf].collateral -= uint128(assets);

        IERC20(marketParams.collateralToken).safeTransfer(
            receiver, assets
        );
    }

    function liquidate(
        MarketParams memory marketParams,
        address borrower,
        uint256 seizedAssets,
        uint256,
        bytes memory
    ) external override returns (uint256, uint256) {
        Id marketId = marketParams.id();
        if (_markets[marketId].lastUpdate == 0) {
            revert MarketNotCreated();
        }

        uint256 repaidAssets = seizedAssets;

        _positions[marketId][borrower].collateral -=
            uint128(seizedAssets);
        _positions[marketId][borrower].borrowShares -=
            uint128(repaidAssets);
        _markets[marketId].totalBorrowAssets -= uint128(repaidAssets);
        _markets[marketId].totalBorrowShares -= uint128(repaidAssets);

        IERC20(marketParams.loanToken).safeTransferFrom(
            msg.sender, address(this), repaidAssets
        );
        IERC20(marketParams.collateralToken).safeTransfer(
            msg.sender, seizedAssets
        );

        return (seizedAssets, repaidAssets);
    }

    function flashLoan(
        address token,
        uint256 assets,
        bytes calldata
    ) external override {
        IERC20(token).safeTransfer(msg.sender, assets);
        IERC20(token).safeTransferFrom(
            msg.sender, address(this), assets
        );
    }

    function accrueInterest(
        MarketParams memory marketParams
    ) external override {
        Id marketId = marketParams.id();
        if (_markets[marketId].lastUpdate == 0) {
            revert MarketNotCreated();
        }
        _markets[marketId].lastUpdate = uint128(block.timestamp);
    }

    function position(
        Id id_,
        address user
    ) external view override returns (Position memory) {
        return _positions[id_][user];
    }

    function market(
        Id id_
    ) external view override returns (Market memory) {
        return _markets[id_];
    }

    function idToMarketParams(
        Id id_
    ) external view override returns (MarketParams memory) {
        return _idToMarketParams[id_];
    }
}
