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
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {HookMiner} from "../test/HookMiner.sol";

contract DeployCCIPHook is Script {
    function run() external {
        string memory chainName = HelperUtils.getChainName(block.chainid);
        // Fetch the network configuration for the current chain
        HelperConfig helperConfig = new HelperConfig();
        (, address router,,,, address linkToken,,) = helperConfig.activeNetworkConfig();
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address poolManagerAddress =0x5C038EE8AB7bD7699037E277874F1c611aD0C28F; // arbitrum

               address salekToken=0x6c1B0Edb80Fd56b598634d0Fd3bdd49b7420BBe2;//0x65c13B01BC11Aa746Cae8397E3fF3D9fa33117c1;
        vm.startBroadcast(deployerPrivateKey);
       uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG);
    //        deployCodeTo(
    //         "CrossChainHook.sol",
    //         abi.encode(poolManagerAddress, salekToken, router, linkToken),
    //         address(flags)
    //     );

    address  CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);
    address SEPOLIA_POOLMANAGER = address(0xFf34e285F8ED393E366046153e3C16484A4dD674);


        // Mine a salt that will produce a hook address with the correct flags
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, type(CrossChainHook).creationCode, abi.encode(address(SEPOLIA_POOLMANAGER),address(salekToken), address(router), address(linkToken)));


//         // Mine a salt that will produce a hook address with the correct flags
//         (address hookAddress, bytes32 salt) =
//             HookMiner.find(CREATE2_DEPLOYER, flags, type(GasPriceFeesHook).creationCode, abi.encode(address(SEPOLIA_POOLMANAGER)));

        /**
         * IPoolManager _manager,
         *     address _salekAddress,
         *     address _router,
         *     address _linkToken
         */
        // CrossChainHook ccipHook = new CrossChainHook(IPoolManager(poolManagerAddress), salekToken, router, linkToken);
        vm.stopBroadcast();

        // Prepare to write the deployed token address to a JSON file
        string memory jsonObj = "internal_key";
        string memory key = string(abi.encodePacked("deployCCIPHook_", chainName));
        string memory finalJson = vm.serializeAddress(jsonObj, key, hookAddress);

        // Define the output file path for the deployed token address
        string memory fileName = string(abi.encodePacked("./script/output/deployCCIPHook_", chainName, ".json"));
        console.log("Writing deployed token address to file:", fileName);

        // Write the JSON file containing the deployed token address
        vm.writeJson(finalJson, fileName);
    }


    function deployCodeTo(string memory what, address where) internal virtual {
        deployCodeTo(what, "", 0, where);
    }

    function deployCodeTo(string memory what, bytes memory args, address where) internal virtual {
        deployCodeTo(what, args, 0, where);
    }

    function deployCodeTo(string memory what, bytes memory args, uint256 value, address where) internal virtual {
        bytes memory creationCode = vm.getCode(what);
        vm.etch(where, abi.encodePacked(creationCode, args));
        (bool success, bytes memory runtimeBytecode) = where.call{value: value}("");
        require(success, "StdCheats deployCodeTo(string,bytes,uint256,address): Failed to create runtime bytecode.");
        vm.etch(where, runtimeBytecode);
    }
}
