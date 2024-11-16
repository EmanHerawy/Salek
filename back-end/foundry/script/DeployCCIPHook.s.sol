// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol"; // Utility functions for JSON parsing and chain info
import {HelperConfig} from "./HelperConfig.s.sol"; // Network configuration helper
import {BurnMintERC677WithCCIPAdmin} from "../src/BurnMintERC677WithCCIPAdmin.sol";
import {BurnMintERC677} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";
import {CrossChainHook} from "../src/CrossChainHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "v4-core/PoolManager.sol";

contract DeployCCIPHook is Script {
    function run() external {
        string memory chainName = HelperUtils.getChainName(block.chainid);
        // Fetch the network configuration for the current chain
        HelperConfig helperConfig = new HelperConfig();
        (, address router,,,, address linkToken,,) = helperConfig.activeNetworkConfig();
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address poolManagerAddress = vm.envAddress("POOL_MANAGER");
        if (poolManagerAddress == address(0)) {
            poolManagerAddress = address(new PoolManager(address(this)));
        }
        address salekToken;
        vm.startBroadcast(deployerPrivateKey);
        /**
         * IPoolManager _manager,
         *     address _salekAddress,
         *     address _router,
         *     address _linkToken
         */
        CrossChainHook ccipHook = new CrossChainHook(IPoolManager(poolManagerAddress), salekToken, router, linkToken);
        vm.stopBroadcast();

        // Prepare to write the deployed token address to a JSON file
        string memory jsonObj = "internal_key";
        string memory key = string(abi.encodePacked("deployCCIPHook_", chainName));
        string memory finalJson = vm.serializeAddress(jsonObj, key, address(ccipHook));

        // Define the output file path for the deployed token address
        string memory fileName = string(abi.encodePacked("./script/output/deployCCIPHook_", chainName, ".json"));
        console.log("Writing deployed token address to file:", fileName);

        // Write the JSON file containing the deployed token address
        vm.writeJson(finalJson, fileName);
    }
}
