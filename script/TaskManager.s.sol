// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TaskManager.sol";

contract TaskManagerScript is Script {
    function run() external {
        // Retrieve private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        new TaskManager();

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
