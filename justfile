set dotenv-load

import "lib/battlechain-lib/battlechain.just"

# Token addresses (from DeployFakeTokens broadcast)
usdc := "0xb9bEab76Db81BdF8c863f2cA648dA8d3bB5CB1EE"
usdt := "0x0d414B0CCef51a25cd32c93b869A9fF2e883a27E"
weth := "0x4CAc28Fc96bb8fa0e6F94ef0E579384902142f42"
wbtc := "0xB90cb0F537F2E7D11b165a8C5C79B7a593aBE4f0"
dai  := "0x393cBd865554a543D992218d190EA9dcE47d9bC2"

deploy-tokens:
    just bc-deploy-verify script/DeployFakeTokens.s.sol $ACCOUNT $SENDER

deploy-chainlink:
    just bc-deploy-verify script/DeployChainlink.s.sol $ACCOUNT $SENDER

deploy-venus _usdc=usdc _weth=weth _wbtc=wbtc _dai=dai _usdt=usdt:
    forge script script/DeployVenus.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address,address,address,address,address)" {{ _usdc }} {{ _weth }} {{ _wbtc }} {{ _dai }} {{ _usdt }} -g 300 --verify {{ bc-verify-flags }}

deploy-uniswap-v3 _weth=weth:
    forge script script/DeployUniswapV3.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation -g 300 --gas-limit 30000000 --sender $SENDER --sig "run(address)" {{ _weth }} --verify {{ bc-verify-flags }}

deploy-uniswap-v3-periphery _factory _weth=weth:
    forge script script/DeployUniswapV3Periphery.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation -g 300 --gas-limit 30000000 --sender $SENDER --sig "run(address,address)" {{ _factory }} {{ _weth }} --verify {{ bc-verify-flags }}

deploy-uniswap-v4:
    just bc-deploy-verify script/DeployUniswapV4.s.sol $ACCOUNT $SENDER

deploy-euler-v2 _usdc=usdc _weth=weth:
    forge script script/DeployEulerV2.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address,address)" {{ _usdc }} {{ _weth }} -g 300 --verify {{ bc-verify-flags }}

deploy-ccip:
    just bc-deploy-verify script/DeployCCIP.s.sol $ACCOUNT $SENDER

deploy-teleporter _blockchain_id:
    forge script script/DeployTeleporter.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(bytes32)" {{ _blockchain_id }} -g 300 --verify {{ bc-verify-flags }}

deploy-morpho _usdc=usdc _weth=weth _wbtc=wbtc:
    forge script script/DeployMorpho.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address,address,address)" {{ _usdc }} {{ _weth }} {{ _wbtc }} -g 300 --verify {{ bc-verify-flags }}

deploy-kyberswap:
    just bc-deploy-verify script/DeployKyberSwap.s.sol $ACCOUNT $SENDER

deploy-safe:
    just bc-deploy-verify script/DeploySafe.s.sol $ACCOUNT $SENDER

deploy-all:
    just deploy-tokens
    just deploy-chainlink
    just deploy-venus
    just deploy-uniswap-v3
    just deploy-uniswap-v4
    just deploy-euler-v2
    just deploy-ccip
    just deploy-teleporter $BLOCKCHAIN_ID
    just deploy-morpho
    just deploy-kyberswap
    just deploy-safe

deploy-safe-harbor *contracts="":
    forge script script/DeploySafeHarbor.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address[])" {{ contracts }}
