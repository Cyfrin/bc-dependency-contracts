// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @notice Minimal Ethereum Vault Connector interface for Euler v2.
interface IEVC {
    function call(
        address targetContract,
        address onBehalfOfAccount,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);

    function controlCollateral(
        address targetCollateral,
        address onBehalfOfAccount,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);

    function enableController(
        address account,
        address vault
    ) external;

    function disableController(address account) external;

    function enableCollateral(
        address account,
        address vault
    ) external;

    function disableCollateral(
        address account,
        address vault
    ) external;

    function isControllerEnabled(
        address account,
        address vault
    ) external view returns (bool);

    function isCollateralEnabled(
        address account,
        address vault
    ) external view returns (bool);

    function getControllers(
        address account
    ) external view returns (address[] memory);

    function getCollaterals(
        address account
    ) external view returns (address[] memory);

    function isOperatorAuthenticated()
        external
        view
        returns (bool);

    function setOperator(
        address addressPrefix,
        address operator,
        uint256 operatorBitField
    ) external;

    function getAccountOwner(
        address account
    ) external view returns (address);
}
