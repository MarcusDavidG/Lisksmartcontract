// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SimpleToken.sol";

contract SimpleTokenTest is Test {
    SimpleToken public token;
    address public alice = address(0x123);
    address public bob = address(0x456);

    function setUp() public {
        token = new SimpleToken();
    }

    function testInitialBalance() public {
        uint256 initialBalance = token.balanceOf(address(this));
        assertEq(initialBalance, 0); // The owner should start with 0 tokens
    }

    function testMint() public {
        token.mint(alice, 1000);
        uint256 balance = token.balanceOf(alice);
        assertEq(balance, 1000); // Alice should have 1000 tokens after mint
    }

    function testTransfer() public {
        token.mint(alice, 1000);
        token.transfer(bob, 500);
        uint256 aliceBalance = token.balanceOf(alice);
        uint256 bobBalance = token.balanceOf(bob);

        assertEq(aliceBalance, 500); // Alice should have 500 tokens after transfer
        assertEq(bobBalance, 500);   // Bob should have received 500 tokens
    }

    function testBurn() public {
        token.mint(alice, 1000);
        token.burn(500);
        uint256 balance = token.balanceOf(alice);
        assertEq(balance, 500); // Alice should have 500 tokens after burning
    }
}
