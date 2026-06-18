# bc-dependency-contracts

Mock and real protocol deployments for BattleChain testnet and mainnet. Deploys tokens, price feeds, and DeFi protocol contracts via the BattleChain deployer (CreateX-based), with optional Safe Harbor registration.

## Protocols

| Script | What it deploys |
|--------|----------------|
| `DeployFakeTokens` | MintableERC20 (MTK), WETH, and MintableERC20V2 tokens (USDC, USDT, DAI, WBTC, LINK) |
| `DeployChainlink` | MockV3Aggregator price feeds (ETH/USD, BTC/USD, LINK/USD, USDC/USD) |
| `DeployVenus` | Mock Comptroller + VToken markets (vUSDC, vWETH, vWBTC, vDAI, vBNB) |
| `DeployUniswapV3` | Mock SwapRouter with configurable exchange rates |
| `DeployUniswapV3Periphery` | Uniswap V3 periphery contracts against an existing factory |
| `DeployUniswapV4` | Uniswap V4 PoolManager singleton |
| `DeployEulerV2` | Mock EVC + Euler vaults (eUSDC, eWETH) |
| `DeployCCIP` | Mock CCIP Router for cross-chain message testing |
| `DeployTeleporter` | Mock Teleporter Messenger for Avalanche ICM cross-chain testing |
| `DeployMorpho` | Mock Morpho with 3 lending markets |
| `DeployKyberSwap` | Mock KyberSwap Router for swap testing |
| `DeploySafe` | Full Safe smart account suite (singletons, proxy factory, libraries, fallback handlers) |
| `DeploySafeHarbor` | Registers deployed contracts under a BattleChain Safe Harbor agreement |
| `Multicall3` | Canonical [Multicall3](https://github.com/mds1/multicall3) at `0xcA11…CA11` via pre-signed tx (`just deploy-multicall3`, **mainnet only**) |

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

### Network selection

Recipes target the testnet (chain 627) by default. Prefix any recipe with `mainnet` to target mainnet (chain 626) instead, or set the `NETWORK` environment variable:

```shell
just deploy-safe                  # testnet
just mainnet deploy-safe          # mainnet
NETWORK=mainnet just deploy-safe  # mainnet
```

Deploys verify contracts on the selected network's block explorer ([testnet](https://explorer.testnet.battlechain.com/), [mainnet](https://explorer.mainnet.battlechain.com/)). The default token addresses in the justfile are testnet deployments — on mainnet, deploy tokens first and pass the new addresses explicitly to recipes that take them (`deploy-venus`, `deploy-euler-v2`, `deploy-morpho`, `deploy-uniswap-v3`).

### Recipes

Deploy a single protocol:

```shell
just deploy-tokens
just deploy-chainlink
just deploy-venus
just deploy-uniswap-v3
just deploy-uniswap-v4
just deploy-euler-v2
just deploy-ccip
just deploy-teleporter <blockchain_id_bytes32>
just deploy-morpho
just deploy-kyberswap
just deploy-safe
```

Deploy everything in order:

```shell
just deploy-all
```

Register contracts with Safe Harbor (pass deployed contract addresses):

```shell
just deploy-safe-harbor "[0xAddr1,0xAddr2,...]"
```

### Multicall3 (canonical)

[Multicall3](https://github.com/mds1/multicall3) is deployed at `0xcA11bde05977b3631167028862bE2a173976CA11` — the address foundry, viem, wagmi, and ethers expect — using mds1's pre-signed "Nick's method" transaction (vendored as the `lib/multicall3` submodule and `script/multicall3-presigned-tx.txt`):

```shell
just mainnet deploy-multicall3   # deploy (chain 626)
just mainnet verify-multicall3   # verify on the mainnet explorer
```

`deploy-multicall3` is idempotent: it skips if Multicall3 already exists, estimates the deploy gas, funds the canonical deployer (`0x05f32b3cc3888453ff71b01135b34ff8e41263f2`) with exactly 0.1 ETH (the pre-signed tx's fixed 1,000,000 gas × 100 gwei), then broadcasts the pre-signed transaction. Verification reuses the submodule's exact upstream build config (solc 0.8.12, optimizer enabled with 10,000,000 runs).

**Mainnet only.** The pre-signed transaction caps gas at 1,000,000. Mainnet deploys Multicall3 in ~881k gas, but testnet (chain 627) needs ~3.76M (its gas metering is not EVM-equivalent), so the recipe refuses to run there rather than burn the deployer's nonce and 0.1 ETH. On testnet the canonical address is only reachable as a genesis predeploy.

## Mainnet deployments (chain 626)

The Safe suite is deployed on BattleChain mainnet (from the `DeploySafe` broadcast):

| Contract | Address |
|----------|---------|
| Safe | `0xFF716747B4D28EAE844Dc069387C9bFC00e51737` |
| SafeL2 | `0xb6524C4fBcEd314EAad98Bc750B6AD76B64d7f8A` |
| SafeProxyFactory | `0x8d0D56f72E266a4BfA05340f68409dEBbdbdc9e2` |
| CreateCall | `0x5A499D08755a9dC90208Ef5b031a3118789EBF5A` |
| MultiSend | `0x28E369665036bFe0041c1E5838A608b1a818296f` |
| MultiSendCallOnly | `0xed4c81c91602CDD5c1e396a1AF28735E03EdA9e2` |
| SignMessageLib | `0x95cb704BFF25b8943BcE3fAE5D1b4665f7b08115` |
| SafeToL2Setup | `0xa8fB860254764C68360596f64BA841b077bebBA4` |
| TokenCallbackHandler | `0x63b920c6D0B5EC07345d9810169376192654d38F` |
| CompatibilityFallbackHandler | `0x2744C4f8336B6e2A8a182495FbB327Db493F303f` |
| ExtensibleFallbackHandler | `0x115b290ecDe805FD846E0C347f3419A4234Fd673` |

CreateX is deployed on mainnet at `0xa397f06F07251A3AEd53f6d3019A2a6cbd83E53e` (not at the canonical CreateX address used on other chains). The core BattleChain contracts (Safe Harbor registry, agreement factory, attack registry, deployer) are also live on mainnet; see [battlechain-lib](https://github.com/cyfrin/battlechain-lib) for their addresses.

Create a 1-of-1 Safe. The factory, singleton, and fallback handler default to the selected network's SafeProxyFactory, SafeL2, and CompatibilityFallbackHandler (for mainnet, the addresses above):

```shell
just create-safe <owner> [salt]          # testnet
just mainnet create-safe <owner> [salt]  # mainnet
```

The Safe address is deterministic (CREATE2); bump the salt to create another Safe for the same owner. The mock protocol deployments (tokens, Chainlink, Venus, Euler, Morpho, KyberSwap, CCIP, Teleporter) remain testnet-only.

## Verify

Verification targets the selected network's block explorer (testnet by default; prefix with `mainnet` to verify on the mainnet explorer).

Verify a single contract:

```shell
just bc-verify <contract_address> <src/Path.sol:ContractName>
```

Verify all contracts from a deployment broadcast:

```shell
just bc-verify-broadcast script/DeployFakeTokens.s.sol
```

This parses the broadcast JSON for both direct creates and factory creates (via CreateX/BCDeploy), matches each deployed address against compiled artifacts, and submits verification to the block explorer.
