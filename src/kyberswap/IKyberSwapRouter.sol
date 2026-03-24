// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IKyberSwapRouter {
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    struct SwapExecutionParams {
        address callTarget;
        address approveTarget;
        bytes targetData;
        SwapDescription desc;
        bytes clientData;
    }

    function swap(
        SwapExecutionParams calldata execution
    ) external payable returns (uint256 returnAmount, uint256 gasUsed);

    function swapSimpleMode(
        address caller,
        SwapDescription calldata desc,
        bytes calldata executorData,
        bytes calldata clientData
    ) external returns (uint256 returnAmount);
}
