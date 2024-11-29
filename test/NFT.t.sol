// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NFT} from "../src/NFT.sol";

contract NFTTest is Test {

    NFT public lsk;

    // Create dummy addresses for alice and bob
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    // Initialize the NFT contract's object
    function setUp() public{
        lsk = new NFT();
    }

    // Pass the address of alice and bob to see whether the mint function successfully passes
    function testMintPass() public {
        lsk.mint(alice);
        lsk.mint(bob);
    }

    // To intentionally create a failing test, let's compare the addresses of alice and bob
    function testMintFail() public {
        assertEq(alice, bob);
    }
}