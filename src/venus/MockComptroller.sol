// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IComptroller} from "src/venus/IVenus.sol";

contract MockComptroller is IComptroller {
    struct Market {
        bool isListed;
        uint256 collateralFactorMantissa;
    }

    mapping(address => Market) public override markets;
    address[] private _allMarkets;

    // account => vTokens entered
    mapping(address => mapping(address => bool)) public accountMembership;

    address public admin;

    error NotAdmin();

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    constructor(address _admin) {
        admin = _admin;
    }

    function listMarket(
        address vToken,
        uint256 collateralFactorMantissa
    ) external onlyAdmin {
        markets[vToken] = Market({
            isListed: true,
            collateralFactorMantissa: collateralFactorMantissa
        });
        _allMarkets.push(vToken);
    }

    function enterMarkets(
        address[] calldata vTokens
    ) external override returns (uint256[] memory errors) {
        errors = new uint256[](vTokens.length);
        for (uint256 i; i < vTokens.length; i++) {
            accountMembership[msg.sender][vTokens[i]] = true;
            errors[i] = 0; // success
        }
    }

    function exitMarket(
        address vToken
    ) external override returns (uint256) {
        accountMembership[msg.sender][vToken] = false;
        return 0;
    }

    function getAccountLiquidity(
        address
    )
        external
        pure
        override
        returns (uint256 err, uint256 liquidity, uint256 shortfall)
    {
        // Mock: always return healthy account with 1M liquidity
        return (0, 1_000_000e18, 0);
    }

    function getAllMarkets()
        external
        view
        override
        returns (address[] memory)
    {
        return _allMarkets;
    }

    function _onlyAdmin() private view {
        if (msg.sender != admin) revert NotAdmin();
    }
}
