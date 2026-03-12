# bc-dependency-contracts

Mock and real protocol deployments for the BattleChain testnet. Deploys tokens, price feeds, and DeFi protocol contracts via the BattleChain deployer (CreateX-based), with optional Safe Harbor registration.

## Protocols

| Script | What it deploys |
|--------|----------------|
| `DeployFakeTokens` | MintableERC20 (MTK), WETH, and MintableERC20V2 tokens (USDC, USDT, DAI, WBTC, LINK) |
| `DeployChainlink` | MockV3Aggregator price feeds (ETH/USD, BTC/USD, LINK/USD, USDC/USD) |
| `DeployVenus` | Mock Comptroller + VToken markets (vUSDC, vWETH, vWBTC, vDAI, vBNB) |
| `DeployUniswapV3` | Mock SwapRouter with configurable exchange rates |
| `DeployUniswapV4` | Uniswap V4 PoolManager singleton |
| `DeployEulerV2` | Mock EVC + Euler vaults (eUSDC, eWETH) |
| `DeployCCIP` | Mock CCIP Router for cross-chain message testing |
| `DeploySafeHarbor` | Registers deployed contracts under a BattleChain Safe Harbor agreement |

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [just](https://github.com/casey/just)
- A keystore account for broadcasting (see `cast wallet` docs)

## Setup

```shell
git clone --recurse-submodules <repo-url>
cd bc-dependency-contracts
forge build
```

Create a `.env` file:

```shell
SENDER=0xYourDeployerAddress
ACCOUNT=your-keystore-account-name
```

## Deploy

Deploy a single protocol:

```shell
just deploy-tokens
just deploy-chainlink
just deploy-venus
just deploy-uniswap-v3
just deploy-uniswap-v4
just deploy-euler-v2
just deploy-ccip
```

Deploy everything in order:

```shell
just deploy-all
```

Register contracts with Safe Harbor (pass deployed contract addresses):

```shell
just deploy-safe-harbor "[0xAddr1,0xAddr2,...]"
```

## Verify

Verify a single contract:

```shell
just verify <contract_address> <src/Path.sol:ContractName>
```

Verify all contracts from a deployment broadcast:

```shell
just verify-broadcast script/DeployFakeTokens.s.sol
```

This parses the broadcast JSON for both direct creates and factory creates (via CreateX/BCDeploy), matches each deployed address against compiled artifacts, and submits verification to the block explorer.
