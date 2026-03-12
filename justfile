set dotenv-load

bc-rpc := "https://testnet.battlechain.com:3051"
bc-explorer-api := "https://block-explorer-api.testnet.battlechain.com/api"
bc-chain-id := "627"
verify-flags := "--verify --verifier-url " + bc-explorer-api + " --verifier custom --etherscan-api-key 1234"

# Token addresses (from DeployFakeTokens broadcast)
usdc := "0xb9bEab76Db81BdF8c863f2cA648dA8d3bB5CB1EE"
weth := "0x4CAc28Fc96bb8fa0e6F94ef0E579384902142f42"
wbtc := "0xB90cb0F537F2E7D11b165a8C5C79B7a593aBE4f0"
dai  := "0x393cBd865554a543D992218d190EA9dcE47d9bC2"

deploy-tokens:
    forge script script/DeployFakeTokens.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation -g 300 --sender $SENDER {{ verify-flags }}

deploy-chainlink:
    forge script script/DeployChainlink.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER {{ verify-flags }}

deploy-venus _usdc=usdc _weth=weth _wbtc=wbtc _dai=dai:
    forge script script/DeployVenus.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address,address,address,address)" {{ _usdc }} {{ _weth }} {{ _wbtc }} {{ _dai }} {{ verify-flags }}

deploy-uniswap-v3 _weth=weth:
    forge script script/DeployUniswapV3.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT -vvvvv --skip-simulation -g 300 --gas-limit 30000000 --sender $SENDER --sig "run(address)" {{ _weth }} {{ verify-flags }}

deploy-uniswap-v4:
    forge script script/DeployUniswapV4.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER {{ verify-flags }}

deploy-euler-v2 _usdc=usdc _weth=weth:
    forge script script/DeployEulerV2.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address,address)" {{ _usdc }} {{ _weth }} {{ verify-flags }}

deploy-ccip:
    forge script script/DeployCCIP.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER {{ verify-flags }}

deploy-all:
    just deploy-tokens
    just deploy-chainlink
    just deploy-venus
    just deploy-uniswap-v3
    just deploy-uniswap-v4
    just deploy-euler-v2
    just deploy-ccip

deploy-safe-harbor *contracts="":
    forge script script/DeploySafeHarbor.s.sol --rpc-url {{ bc-rpc }} --broadcast --account $ACCOUNT --skip-simulation --sender $SENDER --sig "run(address[])" {{ contracts }}

verify contract_address path_and_name:
    forge verify-contract {{ contract_address }} {{ path_and_name }} \
        --chain-id {{ bc-chain-id }} \
        --verifier-url {{ bc-explorer-api }} \
        --verifier custom \
        --etherscan-api-key "1234" \
        --rpc-url {{ bc-rpc }}

# Verify all contracts from a broadcast JSON file.
# Handles both direct creates (additionalContracts) and factory creates
# (CreateX/BCDeploy) by parsing ContractCreation events from receipts.
# Usage: just verify-broadcast script/DeployFakeTokens.s.sol
verify-broadcast script:
    #!/usr/bin/env bash
    set -euo pipefail
    BROADCAST="broadcast/$(basename {{ script }})/{{ bc-chain-id }}/run-latest.json"
    if [ ! -f "$BROADCAST" ]; then
        echo "No broadcast found at $BROADCAST"
        exit 1
    fi
    echo "Parsing $BROADCAST..."

    # ContractCreation(address indexed) event topic (CreateX)
    CREATEX_TOPIC="0x4db17dd5e4732fb6da34a148104a592783ca119a1e7bb8829eba6cbadef0b511"

    # Match initCode prefix against compiled artifacts.
    # Prints "src/path:ContractName" on match, empty otherwise.
    match_initcode() {
        local initcode="${1#0x}"
        for artifact in out/*.sol/*.json; do
            local bytecode
            bytecode=$(jq -r '.bytecode.object // empty' "$artifact" 2>/dev/null)
            [ -z "$bytecode" ] && continue
            bytecode="${bytecode#0x}"
            if [ "${#bytecode}" -gt 4 ] && \
               [ "${#initcode}" -ge "${#bytecode}" ] && \
               [ "${initcode:0:${#bytecode}}" = "$bytecode" ]; then
                # Derive source path and contract name from compilationTarget
                local match
                match=$(jq -r '
                    .metadata.settings.compilationTarget // {} |
                    to_entries[0] // empty |
                    "\(.key):\(.value)"
                ' "$artifact" 2>/dev/null)
                [ -n "$match" ] && echo "$match" && return
            fi
        done
    }

    verify_contract() {
        local addr="$1" initcode="$2"
        local match
        match=$(match_initcode "$initcode")
        if [ -n "$match" ]; then
            echo "Verifying $match at $addr"
            just verify "$addr" "$match" || echo "  FAILED (may need manual verification)"
        else
            echo "Could not match artifact for $addr — verify manually"
        fi
    }

    # 1. Direct creates (additionalContracts in broadcast)
    jq -r '
        [.transactions[].additionalContracts[]? |
         select(.transactionType == "CREATE" or .transactionType == "CREATE2")] |
        .[] | "\(.address) \(.initCode)"
    ' "$BROADCAST" | while IFS=' ' read -r addr initcode; do
        [ -n "$addr" ] && verify_contract "$addr" "$initcode"
    done

    # 2. Factory creates (ContractCreation events from CreateX/BCDeploy)
    jq -r --arg topic "$CREATEX_TOPIC" '
        ([.transactions[] | {key: .hash, value: .transaction.input}] | from_entries) as $inputs |
        .receipts[] |
        .transactionHash as $txhash |
        .logs[] |
        select(.topics[0] == $topic) |
        ("0x" + .topics[1][-40:]) + " " + ($inputs[$txhash] // "")
    ' "$BROADCAST" | while IFS=' ' read -r addr callinput; do
        [ -z "$addr" ] || [ -z "$callinput" ] && continue
        # Try known BCDeploy/CreateX factory signatures
        initcode=""
        for sig in \
            "deployCreate(bytes)" \
            "deployCreate2(bytes32,bytes)" \
            "deployCreate3(bytes32,bytes)"; do
            initcode=$(cast calldata-decode "$sig" "$callinput" 2>/dev/null | tail -1) && break
            initcode=""
        done
        if [ -n "$initcode" ]; then
            verify_contract "$addr" "$initcode"
        else
            echo "Could not decode factory calldata for $addr — verify manually"
        fi
    done

# deploy-zksync:
#     forge script script/DeployCounter.s.sol --rpc-url $ZKSYNC_SEPOLIA_RPC_URL --broadcast --account $ACCOUNT --sender $SENDER -vvvv