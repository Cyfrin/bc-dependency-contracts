// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BCDeploy} from "battlechain-lib/src/BCDeploy.sol";
import {MockMorpho} from "src/morpho/MockMorpho.sol";
import {Id, MarketParams, MarketParamsLib} from "src/morpho/IMorpho.sol";
import {console} from "forge-std/console.sol";

/// @notice Deploys MockMorpho with 3 lending markets.
/// Limitations:
/// - No interest accrual
/// - No oracle price checks
/// - 1:1 share-to-asset ratio
contract DeployScript is BCDeploy {
    using MarketParamsLib for MarketParams;

    // Mock oracle/IRM — not validated by the mock
    address constant MOCK_ORACLE = address(1);
    address constant MOCK_IRM = address(2);
    uint256 constant DEFAULT_LLTV = 0.8e18; // 80%

    function run(
        address usdc,
        address weth,
        address wbtc
    ) public {
        vm.startBroadcast();

        address morpho = bcDeployCreate(
            abi.encodePacked(
                type(MockMorpho).creationCode,
                abi.encode(msg.sender)
            )
        );

        MockMorpho m = MockMorpho(morpho);
        m.enableIrm(MOCK_IRM);
        m.enableLltv(DEFAULT_LLTV);

        // Market 1: USDC/WETH (borrow USDC, collateral WETH)
        MarketParams memory usdcWeth = MarketParams({
            loanToken: usdc,
            collateralToken: weth,
            oracle: MOCK_ORACLE,
            irm: MOCK_IRM,
            lltv: DEFAULT_LLTV
        });
        m.createMarket(usdcWeth);

        // Market 2: USDC/WBTC (borrow USDC, collateral WBTC)
        MarketParams memory usdcWbtc = MarketParams({
            loanToken: usdc,
            collateralToken: wbtc,
            oracle: MOCK_ORACLE,
            irm: MOCK_IRM,
            lltv: DEFAULT_LLTV
        });
        m.createMarket(usdcWbtc);

        // Market 3: WETH/WBTC (borrow WETH, collateral WBTC)
        MarketParams memory wethWbtc = MarketParams({
            loanToken: weth,
            collateralToken: wbtc,
            oracle: MOCK_ORACLE,
            irm: MOCK_IRM,
            lltv: DEFAULT_LLTV
        });
        m.createMarket(wethWbtc);

        vm.stopBroadcast();

        console.log("MockMorpho:", morpho);
        console.log("Market USDC/WETH id:");
        console.logBytes32(Id.unwrap(usdcWeth.id()));
        console.log("Market USDC/WBTC id:");
        console.logBytes32(Id.unwrap(usdcWbtc.id()));
        console.log("Market WETH/WBTC id:");
        console.logBytes32(Id.unwrap(wethWbtc.id()));
    }
}
