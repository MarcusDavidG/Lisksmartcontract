// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/StakingRewards.sol";
import "../src/MockLiskToken.sol";

contract StakingRewardsScript is Script {
    function run() external {
        // Retrieve private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // First deploy the Mock Lisk Token
        MockLiskToken mockToken = new MockLiskToken();
        
        // Deploy the StakingRewards contract with the mock token address
        StakingRewards stakingRewards = new StakingRewards(address(mockToken));

        console.log("MockLiskToken deployed to:", address(mockToken));
        console.log("StakingRewards deployed to:", address(stakingRewards));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
