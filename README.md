# Salek
Our cross-chain DeFi solution enables seamless token swaps through two key components. The front-end mini app provides a user-friendly interface for specifying source and destination tokens and swap amounts (TO BE ADDED). It integrates with the 1inch Fusion API for optimal routing, MEV protection, real-time price impact, and gas fee estimates across chains.

The system's backbone is a robust smart contract infrastructure utilizing Uniswap v4 and Chainlink's CCIP. When a swap is initiated, source tokens are locked, and a secure cross-chain message with swap details is sent via CCIP to the destination chain. There, smart contracts execute the swap using Uniswap v4’s advanced routing and liquidity features.

How it's Made
Backend: Engineered smart contracts utilizing Uniswap v4's hooks for custom swap logic and Chainlink's CCIP for secure cross-chain messaging. The contracts handle token locking on source chains, cross-chain message transmission, and swap execution on destination chains. Key technical integrations



## Test 
```bash
forge test --fork-url  https://eth-sepolia.g.alchemy.com/v2/your-api-key
```
## Deployed contract 

```Json
  "deployCCIPHook_ethereumSepolia": "0x2c3548Be128338a13274896B4F7c03C7d3D24040"

```