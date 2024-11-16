// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.24;

// import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
// import {ERC20} from "solmate/src/tokens/ERC20.sol";

// import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
// import {PoolKey} from "v4-core/types/PoolKey.sol";
// import {BalanceDeltaLibrary, BalanceDelta} from "v4-core/types/BalanceDelta.sol";
// import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
// import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
// import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
// import {Hooks} from "v4-core/libraries/Hooks.sol";
// import {BeforeSwapDelta, toBeforeSwapDelta} from "v4-core/src/types/BeforeSwapDelta.sol";

// contract CrossChainHook is BaseHook {
//     // Use CurrencyLibrary and BalanceDeltaLibrary
//     // to add some helper functions over the Currency and BalanceDelta
//     // data types
//     using CurrencyLibrary for Currency;
//     using BalanceDeltaLibrary for BalanceDelta;

//     ERC20 public salekToken;
//     address public router;
//     address public linkToken;
//     // Initialize BaseHook and ERC20

//     constructor(IPoolManager _manager, address _salekAddress, address _router, address _linkToken) BaseHook(_manager) {
//         salekToken = ERC20(_salekAddress);
//         router = _router;
//         linkToken = _linkToken;
//         ERC20(feeTokenAddress).approve(router, types(uint256).max);
//     }

//     // Set up hook permissions to return `true`
//     // for the two hook functions we are using
//     function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
//         return Hooks.Permissions({
//             beforeInitialize: false,
//             afterInitialize: false,
//             beforeAddLiquidity: false,
//             beforeRemoveLiquidity: false,
//             afterAddLiquidity: false,
//             afterRemoveLiquidity: false,
//             beforeSwap: true,
//             afterSwap: true,
//             beforeDonate: false,
//             afterDonate: false,
//             beforeSwapReturnDelta: false,
//             afterSwapReturnDelta: false,
//             afterAddLiquidityReturnDelta: false,
//             afterRemoveLiquidityReturnDelta: false
//         });
//     }

//     function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata params, bytes calldata hookData)
//         external
//         override
//         returns (bytes4, BeforeSwapDelta, uint24)
//     {
//         // Implementation details will be explained in the following sub-steps
//         if (hookData.length == 0) return (this.beforeSwap.selector, BeforeSwapDelta(0, 0), 0);

//         // Extract user address from hookData
//         (address receiver, uint64 chainSelector) = abi.decode(hookData, (address, uint64));
//         address tokenToSwap = params.zeroForOne ? Currency.unwrap(key.currency0) : Currency.unwrap(key.currency1);
//         uint256 amountToSwap = params.zeroForOne ? uint256(int256(-delta.amount0())) : uint256(int256(-delta.amount1()));
//         // Custom Accounting
//         uint256 swapAmount =
//             params.amountSpecified < 0 ? uint256(-params.amountSpecified) : uint256(params.amountSpecified);

//         uint256 feeAmount = _swapCrossChainBefore(tokenToSwap, receiver, amountToSwap, chainSelector);

//         // Price feeds to calculate it to link
//         poolManager.take(Currency.wrap(tokenToSwap), address(this), feeAmount);

//         return (this.beforeSwap.selector, BeforeSwapDelta(0, 0), 0);
//     }

//     // Stub implementation of `afterSwap`
//     function afterSwap(
//         address,
//         PoolKey calldata key,
//         IPoolManager.SwapParams calldata swapParams,
//         BalanceDelta delta,
//         bytes calldata hookData
//     ) external override onlyPoolManager returns (bytes4, int128) {
//         // If this is not an ETH-TOKEN pool with this hook attached, ignore
//         // TODO: if (check if network supported ) return (this.afterSwap.selector, 0);
//         if (hookData.length == 0) return (this.afterSwap.selector, 0);

//         // Extract user address from hookData
//         (address receiver, uint64 chainSelector) = abi.decode(hookData, (address, uint64));
//         address tokenToSwap = swapParams.zeroForOne ? Currency.unwrap(key.currency0) : Currency.unwrap(key.currency1);
//         uint256 amountToSwap =
//             swapParams.zeroForOne ? uint256(int256(-delta.amount0())) : uint256(int256(-delta.amount1()));
//         // Custom Accounting
//         poolManager.take(Currency.wrap(tokenToSwap), address(this), amountToSwap);

//         _swapCrossChain(
//             tokenToSwap, receiver, swapParams.zeroForOne ? address(0) : linkToken, amountToSwap, chainSelector
//         );
//         return (this.afterSwap.selector, 0);
//     }

//     function _swapCrossChainBefore(
//         address tokenAddress,
//         address receiver,
//         uint256 amount,
//         uint64 destinationChainSelector
//     ) internal view returns (uint256 fees) {
//         // Connect to the CCIP router contract
//         IRouterClient routerContract = IRouterClient(router);

//         // Check if the destination chain is supported by the router
//         //  require(routerContract.isChainSupported(destinationChainSelector), "Destination chain not supported");

//         // Prepare the CCIP message
//         Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
//             receiver: abi.encode(receiver), // Receiver address on the destination chain
//             data: abi.encode(), // No additional data
//             tokenAmounts: new Client.EVMTokenAmount[](1), // Array of tokens to transfer
//             feeToken: linkToken, // Fee token (native or LINK)
//             extraArgs: abi.encodePacked(
//                 bytes4(keccak256("CCIP EVMExtraArgsV1")), // Extra arguments for CCIP (versioned)
//                 abi.encode(uint256(0)) // Placeholder for future use
//             )
//         });

//         // Set the token and amount to transfer
//         message.tokenAmounts[0] = Client.EVMTokenAmount({token: tokenAddress, amount: amount});

//         // Approve the router to transfer tokens on behalf of the sender
//         // ERC20(tokenAddress).approve(router, amount);

//         // Estimate the fees required for the transfer
//         fees = routerContract.getFee(destinationChainSelector, message);
//     }

//     function _swapCrossChainAfter(
//         address tokenAddress,
//         address receiver,
//         uint256 amount,
//         uint64 destinationChainSelector
//     ) internal {
//         // Connect to the CCIP router contract
//         IRouterClient routerContract = IRouterClient(router);

//         // Check if the destination chain is supported by the router
//         //  require(routerContract.isChainSupported(destinationChainSelector), "Destination chain not supported");

//         // Prepare the CCIP message
//         Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
//             receiver: abi.encode(receiver), // Receiver address on the destination chain
//             data: abi.encode(), // No additional data
//             tokenAmounts: new Client.EVMTokenAmount[](1), // Array of tokens to transfer
//             feeToken: linkToken, // Fee token (native or LINK)
//             extraArgs: abi.encodePacked(
//                 bytes4(keccak256("CCIP EVMExtraArgsV1")), // Extra arguments for CCIP (versioned)
//                 abi.encode(uint256(0)) // Placeholder for future use
//             )
//         });

//         // Set the token and amount to transfer
//         message.tokenAmounts[0] = Client.EVMTokenAmount({token: tokenAddress, amount: amount});

//         // Approve the router to transfer tokens on behalf of the sender
//         ERC20(tokenAddress).approve(router, amount);

//         // Estimate the fees required for the transfer
//         uint256 fees = routerContract.getFee(destinationChainSelector, message);

//         // Send the CCIP message and handle fee payment
//         bytes32 messageId = routerContract.ccipSend(destinationChainSelector, message);
//     }
// }
