// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/StakingRewards.sol";

// Mock ERC20 Token for testing
contract MockToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        require(balanceOf[from] >= amount, "Insufficient balance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract StakingRewardsTest is Test {
    StakingRewards public stakingRewards;
    MockToken public mockToken;
    address public alice;
    address public bob;
    uint256 public constant INITIAL_BALANCE = 1000 ether;

    function setUp() public {
        // Deploy mock token
        mockToken = new MockToken();
        
        // Deploy staking contract
        stakingRewards = new StakingRewards(address(mockToken));
        
        // Set up test accounts
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        
        // Mint tokens to test accounts
        mockToken.mint(alice, INITIAL_BALANCE);
        mockToken.mint(bob, INITIAL_BALANCE);
        
        // Approve staking contract
        vm.prank(alice);
        mockToken.approve(address(stakingRewards), type(uint256).max);
        vm.prank(bob);
        mockToken.approve(address(stakingRewards), type(uint256).max);
    }

    function testStaking() public {
        uint256 stakeAmount = 100 ether;
        uint256 stakingPeriod = 7; // 7 days
        
        vm.prank(alice);
        stakingRewards.stake(stakeAmount, stakingPeriod);
        
        assertEq(stakingRewards.balanceOf(alice), stakeAmount);
        assertEq(mockToken.balanceOf(address(stakingRewards)), stakeAmount);
    }

    function testWithdraw() public {
        uint256 stakeAmount = 100 ether;
        uint256 stakingPeriod = 7; // 7 days
        
        // Stake tokens
        vm.prank(alice);
        stakingRewards.stake(stakeAmount, stakingPeriod);
        
        // Fast forward past staking period
        vm.warp(block.timestamp + 8 days);
        
        // Withdraw tokens
        vm.prank(alice);
        stakingRewards.withdraw(stakeAmount);
        
        assertEq(stakingRewards.balanceOf(alice), 0);
        assertEq(mockToken.balanceOf(alice), INITIAL_BALANCE);
    }

    function testEmergencyWithdraw() public {
        uint256 stakeAmount = 100 ether;
        uint256 stakingPeriod = 30; // 30 days
        
        // Stake tokens
        vm.prank(alice);
        stakingRewards.stake(stakeAmount, stakingPeriod);
        
        // Emergency withdraw before staking period ends
        vm.prank(alice);
        stakingRewards.emergencyWithdraw();
        
        // Check if penalty was applied (20%)
        uint256 expectedBalance = INITIAL_BALANCE - (stakeAmount * 20 / 100);
        assertEq(mockToken.balanceOf(alice), expectedBalance);
        assertEq(stakingRewards.balanceOf(alice), 0);
    }

    function testStakingPeriodMultipliers() public {
        // Test different staking periods and their multipliers
        assertEq(stakingRewards.getStakingMultiplier(7), 100);  // 1x
        assertEq(stakingRewards.getStakingMultiplier(30), 150); // 1.5x
        assertEq(stakingRewards.getStakingMultiplier(90), 200); // 2x
        assertEq(stakingRewards.getStakingMultiplier(180), 300); // 3x
    }

    function testFailInvalidStakingPeriod() public {
        uint256 stakeAmount = 100 ether;
        uint256 invalidStakingPeriod = 15; // 15 days is not a valid period
        
        vm.prank(alice);
        stakingRewards.stake(stakeAmount, invalidStakingPeriod);
    }

    function testFailEarlyWithdraw() public {
        uint256 stakeAmount = 100 ether;
        uint256 stakingPeriod = 30; // 30 days
        
        // Stake tokens
        vm.prank(alice);
        stakingRewards.stake(stakeAmount, stakingPeriod);
        
        // Try to withdraw before staking period ends
        vm.prank(alice);
        stakingRewards.withdraw(stakeAmount);
    }
}
