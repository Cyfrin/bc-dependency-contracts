set dotenv-load

import "lib/battlechain-lib/battlechain.just"

# Token addresses (from DeployFakeTokens broadcast)
usdc := "0xb9bEab76Db81BdF8c863f2cA648dA8d3bB5CB1EE"
weth := "0x4CAc28Fc96bb8fa0e6F94ef0E579384902142f42"
wbtc := "0xB90cb0F537F2E7D11b165a8C5C79B7a593aBE4f0"
dai  := "0x393cBd865554a543D992218d190EA9dcE47d9bC2"

deploy-tokens:
    just bc-deploy-verify script/DeployFakeTokens.s.sol $ACCOUNT $SENDER

deploy-chainlink:
    just bc-deploy-verify script/DeployChainlink.s.sol $ACCOUNT $SENDER

deploy-venus _usdc=usdc _weth=weth _wbtc=wbtc _dai=dai:
    forge script script/DeployVenus.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address,address,address,address)" {{ _usdc }} {{ _weth }} {{ _wbtc }} {{ _dai }} -g 300 --verify {{ bc-verify-flags }}

deploy-uniswap-v3 _weth=weth:
    forge script script/DeployUniswapV3.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation -g 300 --gas-limit 30000000 --sender $SENDER --sig "run(address)" {{ _weth }} --verify {{ bc-verify-flags }}

deploy-uniswap-v4:
    just bc-deploy-verify script/DeployUniswapV4.s.sol $ACCOUNT $SENDER

deploy-euler-v2 _usdc=usdc _weth=weth:
    forge script script/DeployEulerV2.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address,address)" {{ _usdc }} {{ _weth }} -g 300 --verify {{ bc-verify-flags }}

deploy-ccip:
    just bc-deploy-verify script/DeployCCIP.s.sol $ACCOUNT $SENDER

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
    just deploy-safe

deploy-safe-harbor *contracts="":
    forge script script/DeploySafeHarbor.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address[])" {{ contracts }}
