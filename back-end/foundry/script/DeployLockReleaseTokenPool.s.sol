// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol"; // Utility functions for JSON parsing and chain info
import {HelperConfig} from "./HelperConfig.s.sol"; // Network configuration helper
import {LockReleaseTokenPool} from "@chainlink/contracts-ccip/src/v0.8/ccip/pools/LockReleaseTokenPool.sol";
import {BurnMintERC677} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";
import {IBurnMintERC20} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";

contract DeployLockReleaseTokenPool is Script {
    function run() external {
        // Get the chain name based on the current chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);

        // Construct the path to the deployed token JSON file
        string memory root = vm.projectRoot();
        string memory deployedTokenPath = string.concat(root, "/script/output/deployedToken_", chainName, ".json");

        // Extract the deployed token address from the JSON file
        address tokenAddress = 0x6c1B0Edb80Fd56b598634d0Fd3bdd49b7420BBe2; //sepolia
            // HelperUtils.getAddressFromJson(vm, deployedTokenPath, string.concat(".deployedToken_", chainName));

        // Fetch network configuration (router and RMN proxy addresses)
        HelperConfig helperConfig = new HelperConfig();
        (, address router, address rmnProxy,,,,,) = helperConfig.activeNetworkConfig();

        // Ensure that the token address, router, and RMN proxy are valid
        require(tokenAddress != address(0), "Invalid token address");
        require(router != address(0) && rmnProxy != address(0), "Router or RMN Proxy not defined for this network");

        // Cast the token address to the IBurnMintERC20 interface
        IBurnMintERC20 token = IBurnMintERC20(tokenAddress);
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the LockReleaseTokenPool contract associated with the token
        LockReleaseTokenPool tokenPool = new LockReleaseTokenPool(
            token,
            new address[](0), // Empty array for initial operators
            rmnProxy,
            false, // Set acceptLiquidity to false
            router
        );

        console.log("Lock & Release token pool deployed to:", address(tokenPool));

        // Grant mint and burn roles to the token pool on the token contract
        BurnMintERC677(tokenAddress).grantMintAndBurnRoles(address(tokenPool));
        console.log("Granted mint and burn roles to token pool:", address(tokenPool));

        vm.stopBroadcast();

        // Serialize and write the token pool address to a new JSON file
        string memory jsonObj = "internal_key";
        string memory key = string(abi.encodePacked("deployedTokenPool_", chainName));
        string memory finalJson = vm.serializeAddress(jsonObj, key, address(tokenPool));

        string memory poolFileName = string(abi.encodePacked("./script/output/deployedTokenPool_", chainName, ".json"));
        console.log("Writing deployed token pool address to file:", poolFileName);
        vm.writeJson(finalJson, poolFileName);
    }
}
