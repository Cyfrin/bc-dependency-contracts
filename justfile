set dotenv-load

import "lib/battlechain-lib/battlechain.just"

# Deploy target: "testnet" (default, chain 627) or "mainnet" (chain 626) — NETWORK,
# bc-rpc, bc-chain-id, bc-explorer-api, and bc-verify-flags come from the imported
# battlechain.just. Select with `just mainnet <recipe>` or `NETWORK=mainnet just <recipe>`.

deploy-cmd := "bc-deploy-verify"
verify-args := "--verify " + bc-verify-flags

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

# Safe suite addresses per network (from DeploySafe broadcasts on chains 626/627)
safe-proxy-factory := if NETWORK == "mainnet" { "0x8d0D56f72E266a4BfA05340f68409dEBbdbdc9e2" } else { "0x80DbD037C59521F393fDfE15504c6b6b7969F1a1" }
safe-l2-singleton := if NETWORK == "mainnet" { "0xb6524C4fBcEd314EAad98Bc750B6AD76B64d7f8A" } else { "0x71314F3E6B1D9386A1de784B644Cf5D0Dde3bB97" }
safe-fallback-handler := if NETWORK == "mainnet" { "0x2744C4f8336B6e2A8a182495FbB327Db493F303f" } else { "0xc6B2C6982A5643b7702894D4A0901b9371dd1283" }

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

# # Multicall3 (canonical) — deployed at the same address on every EVM chain
# multicall3 := "0xcA11bde05977b3631167028862bE2a173976CA11"
# multicall3-deployer := "0x05f32b3cc3888453ff71b01135b34ff8e41263f2"