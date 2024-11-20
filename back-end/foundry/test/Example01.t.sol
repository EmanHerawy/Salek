// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {
    CCIPLocalSimulator,
    IRouterClient,
    LinkToken,
    BurnMintERC677Helper
} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";

import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {LockReleaseTokenPool} from "@chainlink/contracts-ccip/src/v0.8/ccip/pools/LockReleaseTokenPool.sol";

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CrossChainHook} from "../src/CrossChainHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {BurnMintERC677WithCCIPAdmin} from "../src/BurnMintERC677WithCCIPAdmin.sol";

contract Example01Test is Test, Deployers {
    CCIPLocalSimulator public ccipLocalSimulator;
    CrossChainHook public hook;
    address alice;
    address bob;
    IRouterClient router;
    uint64 destinationChainSelector;
    BurnMintERC677Helper ccipBnMToken;
    LinkToken linkToken;
    Currency tokenCurrency;
    Currency ethCurrency;

    function setUp() public {
        ccipLocalSimulator = new CCIPLocalSimulator();
          deployFreshManagerAndRouters();
        (uint64 chainSelector, IRouterClient sourceRouter,,, LinkToken link, BurnMintERC677Helper ccipBnM,) =
            ccipLocalSimulator.configuration();
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        router = sourceRouter;
        destinationChainSelector = chainSelector;
        ccipBnMToken = ccipBnM;
        tokenCurrency = Currency.wrap(address(ccipBnMToken));
        ethCurrency = Currency.wrap(address(0));

        // Deploy hook to an address that has the proper flags set
        uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG);
        deployCodeTo(
            "CrossChainHook.sol",
            abi.encode(manager, address(ccipBnMToken), address(router), address(linkToken)),
            address(flags)
        );




        // Deploy our hook
        hook = CrossChainHook(address(flags));
        // hook = new CrossChainHook(IPoolManager(poolManagerAddress), address(ccipBnMToken), address(router), address(linkToken));

        // Approve our TOKEN for spending on the swap router and modify liquidity router
        // These variables are coming from the `Deployers` contract
 
    }

    function prepareScenario()
        public
        returns (Client.EVMTokenAmount[] memory tokensToSendDetails, uint256 amountToSend)
    {
        vm.startPrank(alice);

        ccipBnMToken.drip(alice);
        vm.deal(alice, 1 ether);
        amountToSend = 10 ether;
       ccipBnMToken.approve(address(swapRouter), type(uint256).max);
       ccipBnMToken.approve(address(modifyLiquidityRouter), type(uint256).max);
        ccipBnMToken.approve(address(router), amountToSend);

        // Initialize a pool
        (key,) = initPool(
            ethCurrency, // Currency 0 = ETH
            tokenCurrency, // Currency 1 = TOKEN
            hook, // Hook Contract
            3000, // Swap Fees
            SQRT_PRICE_1_1 // Initial Sqrt(P) value = 1
        );

        // tokensToSendDetails = new Client.EVMTokenAmount[](1);
        // Client.EVMTokenAmount memory tokenToSendDetails =
        //     Client.EVMTokenAmount({token: address(ccipBnMToken), amount: amountToSend});
        // tokensToSendDetails[0] = tokenToSendDetails;
        // Now we swap
        // We will swap 0.001 ether for tokens
        // We should get 20% of 0.001 * 10**18 points
        // = 2 * 10**14
        bytes memory hookData = abi.encode(address(this), destinationChainSelector);

        swapRouter.swap{value: 0.001 ether}(
            key,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: -0.001 ether, // Exact input for output swap
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            hookData
        );
        vm.stopPrank();
    }

    function test_transferTokensFromEoaToEoaPayFeesInLink() external {
        (Client.EVMTokenAmount[] memory tokensToSendDetails, uint256 amountToSend) = prepareScenario();

        uint256 balanceOfAliceBefore = ccipBnMToken.balanceOf(alice);
        uint256 balanceOfBobBefore = ccipBnMToken.balanceOf(bob);

        vm.startPrank(alice);
        
        vm.stopPrank();

        uint256 balanceOfAliceAfter = ccipBnMToken.balanceOf(alice);
        uint256 balanceOfBobAfter = ccipBnMToken.balanceOf(bob);

        // TODO , read balance in destination chain
        
       
    }

 
}
