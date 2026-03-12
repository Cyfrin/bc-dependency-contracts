// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IEVC} from "src/euler-v2/IEVC.sol";

/// @notice Mock Ethereum Vault Connector for Euler v2 testing.
/// Simplified: no sub-accounts, no operator authentication.
contract MockEVC is IEVC {
    // account => vault => enabled
    mapping(address => mapping(address => bool)) private _controllers;
    mapping(address => mapping(address => bool)) private _collaterals;

    // account => operator => bitfield
    mapping(address => mapping(address => uint256)) private _operators;

    // Track enabled controllers/collaterals per account
    mapping(address => address[]) private _controllerList;
    mapping(address => address[]) private _collateralList;

    function call(
        address targetContract,
        address,
        uint256 value,
        bytes calldata data
    ) external payable override returns (bytes memory) {
        (bool ok, bytes memory result) =
            targetContract.call{value: value}(data);
        if (!ok) {
            assembly { revert(add(result, 32), mload(result)) }
        }
        return result;
    }

    function controlCollateral(
        address targetCollateral,
        address,
        uint256 value,
        bytes calldata data
    ) external payable override returns (bytes memory) {
        (bool ok, bytes memory result) =
            targetCollateral.call{value: value}(data);
        if (!ok) {
            assembly { revert(add(result, 32), mload(result)) }
        }
        return result;
    }

    function enableController(
        address account,
        address vault
    ) external override {
        if (!_controllers[account][vault]) {
            _controllers[account][vault] = true;
            _controllerList[account].push(vault);
        }
    }

    function disableController(address account) external override {
        address[] storage list = _controllerList[account];
        for (uint256 i; i < list.length; i++) {
            _controllers[account][list[i]] = false;
        }
        delete _controllerList[account];
    }

    function enableCollateral(
        address account,
        address vault
    ) external override {
        if (!_collaterals[account][vault]) {
            _collaterals[account][vault] = true;
            _collateralList[account].push(vault);
        }
    }

    function disableCollateral(
        address account,
        address vault
    ) external override {
        _collaterals[account][vault] = false;
        // Remove from list
        address[] storage list = _collateralList[account];
        for (uint256 i; i < list.length; i++) {
            if (list[i] == vault) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
    }

    function isControllerEnabled(
        address account,
        address vault
    ) external view override returns (bool) {
        return _controllers[account][vault];
    }

    function isCollateralEnabled(
        address account,
        address vault
    ) external view override returns (bool) {
        return _collaterals[account][vault];
    }

    function getControllers(
        address account
    ) external view override returns (address[] memory) {
        return _controllerList[account];
    }

    function getCollaterals(
        address account
    ) external view override returns (address[] memory) {
        return _collateralList[account];
    }

    function isOperatorAuthenticated()
        external
        pure
        override
        returns (bool)
    {
        return false;
    }

    function setOperator(
        address addressPrefix,
        address operator,
        uint256 operatorBitField
    ) external override {
        _operators[addressPrefix][operator] = operatorBitField;
    }

    function getAccountOwner(
        address account
    ) external pure override returns (address) {
        // Mock: account owns itself
        return account;
    }
}
