set dotenv-load
set allow-duplicate-variables

import "lib/battlechain-lib/battlechain.just"

# Deploy target: "testnet" (default, chain 627) or "mainnet" (chain 626).
# Select with `just mainnet <recipe>` or `NETWORK=mainnet just <recipe>`.
export NETWORK := env("NETWORK", "testnet")

bc-rpc := if NETWORK == "mainnet" { "https://mainnet.battlechain.com" } else { "https://testnet.battlechain.com" }

# Mainnet has no block explorer yet, so skip contract verification there.
bc-explorer-api := "https://block-explorer-api.testnet.battlechain.com/api"
bc-verify-flags := "--verifier-url " + bc-explorer-api + " --verifier custom --etherscan-api-key 1234"
deploy-cmd := if NETWORK == "mainnet" { "bc-deploy" } else { "bc-deploy-verify" }
verify-args := if NETWORK == "mainnet" { "" } else { "--verify " + bc-verify-flags }

# Run any recipe against mainnet: just mainnet deploy-safe
mainnet *args:
    just NETWORK=mainnet {{ args }}

# Token addresses (testnet only, from DeployFakeTokens broadcast).
# On mainnet, deploy tokens first and pass the new addresses explicitly.
usdc := "0xb9bEab76Db81BdF8c863f2cA648dA8d3bB5CB1EE"
usdt := "0x0d414B0CCef51a25cd32c93b869A9fF2e883a27E"
weth := "0x4CAc28Fc96bb8fa0e6F94ef0E579384902142f42"
wbtc := "0xB90cb0F537F2E7D11b165a8C5C79B7a593aBE4f0"
dai  := "0x393cBd865554a543D992218d190EA9dcE47d9bC2"

deploy-tokens:
    just {{ deploy-cmd }} script/DeployFakeTokens.s.sol $ACCOUNT $SENDER

deploy-chainlink:
    just {{ deploy-cmd }} script/DeployChainlink.s.sol $ACCOUNT $SENDER

deploy-venus _usdc=usdc _weth=weth _wbtc=wbtc _dai=dai _usdt=usdt:
    forge script script/DeployVenus.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address,address,address,address,address)" {{ _usdc }} {{ _weth }} {{ _wbtc }} {{ _dai }} {{ _usdt }} -g 300 {{ verify-args }}

deploy-uniswap-v3 _weth=weth:
    forge script script/DeployUniswapV3.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation -g 300 --gas-limit 30000000 --sender $SENDER --sig "run(address)" {{ _weth }} {{ verify-args }}

deploy-uniswap-v3-periphery _factory _weth=weth:
    forge script script/DeployUniswapV3Periphery.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation -g 300 --gas-limit 30000000 --sender $SENDER --sig "run(address,address)" {{ _factory }} {{ _weth }} {{ verify-args }}

deploy-uniswap-v4:
    just {{ deploy-cmd }} script/DeployUniswapV4.s.sol $ACCOUNT $SENDER

deploy-euler-v2 _usdc=usdc _weth=weth:
    forge script script/DeployEulerV2.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address,address)" {{ _usdc }} {{ _weth }} -g 300 {{ verify-args }}

deploy-ccip:
    just {{ deploy-cmd }} script/DeployCCIP.s.sol $ACCOUNT $SENDER

deploy-teleporter _blockchain_id:
    forge script script/DeployTeleporter.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(bytes32)" {{ _blockchain_id }} -g 300 {{ verify-args }}

deploy-morpho _usdc=usdc _weth=weth _wbtc=wbtc:
    forge script script/DeployMorpho.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address,address,address)" {{ _usdc }} {{ _weth }} {{ _wbtc }} -g 300 {{ verify-args }}

deploy-kyberswap:
    just {{ deploy-cmd }} script/DeployKyberSwap.s.sol $ACCOUNT $SENDER

deploy-safe:
    just {{ deploy-cmd }} script/DeploySafe.s.sol $ACCOUNT $SENDER

# Safe suite addresses (mainnet only, from DeploySafe broadcast on chain 626)
safe-proxy-factory := "0x8d0D56f72E266a4BfA05340f68409dEBbdbdc9e2"
safe-l2-singleton := "0xb6524C4fBcEd314EAad98Bc750B6AD76B64d7f8A"
safe-fallback-handler := "0x2744C4f8336B6e2A8a182495FbB327Db493F303f"

# Create a 1-of-1 Safe. Address is deterministic (CREATE2); bump _salt to create another for the same owner.
create-safe _owner _salt="0" _factory=safe-proxy-factory _singleton=safe-l2-singleton _handler=safe-fallback-handler:
    forge script script/CreateSafe.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address,address,address,address,uint256)" {{ _owner }} {{ _factory }} {{ _singleton }} {{ _handler }} {{ _salt }} -g 300

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
