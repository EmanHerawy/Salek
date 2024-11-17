# Salek

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




    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address poolManagerAddress =0x5C038EE8AB7bD7699037E277874F1c611aD0C28F; // arbitrum

        address salekToken=0x65c13B01BC11Aa746Cae8397E3fF3D9fa33117c1;
        vm.startBroadcast(deployerPrivateKey);
       uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG);
           deployCodeTo(
            "CrossChainHook.sol",
            abi.encode(address(poolManagerAddress), address(salekToken), address(router), address(linkToken)),
            address(flags)
        );