// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IComptroller {
    function enterMarkets(
        address[] calldata vTokens
    ) external returns (uint256[] memory);

    function exitMarket(address vToken) external returns (uint256);

    function getAccountLiquidity(
        address account
    ) external view returns (uint256 err, uint256 liquidity, uint256 shortfall);

    function markets(
        address vToken
    )
        external
        view
        returns (bool isListed, uint256 collateralFactorMantissa);

    function getAllMarkets() external view returns (address[] memory);
}

interface IVToken {
    function isVToken() external view returns (bool);
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    function balanceOfUnderlying(
        address owner
    ) external view returns (uint256);
    function exchangeRateCurrent() external view returns (uint256);
    function underlying() external view returns (address);
}

interface IVBnb {
    function mint() external payable;
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    function repayBorrow() external payable;
}
