// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;

    uint256 public amount;
    bool public isAmountDeposited;
    bool public isAgreementMade;

    // Events
    event Deposited(address indexed buyer, uint256 amount);
    event AgreementMade();
    event Released(address indexed receiver, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);

    constructor(address _buyer, address _seller, address _arbiter) {
        buyer = _buyer;
        seller = _seller;
        arbiter = _arbiter;
        isAmountDeposited = false;
        isAgreementMade = false;
    }

    // Deposit function, used by the buyer to deposit funds into escrow
    function deposit() external payable {
        require(msg.sender == buyer, "Only the buyer can deposit");
        require(msg.value > 0, "Amount must be greater than 0");
        require(!isAmountDeposited, "Funds already deposited");

        amount = msg.value;
        isAmountDeposited = true;

        emit Deposited(buyer, amount);
    }

    // Function for the buyer and seller to agree on the transaction
    function makeAgreement() external {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can agree");
        require(isAmountDeposited, "Funds must be deposited first");

        isAgreementMade = true;

        emit AgreementMade();
    }

    // Function to release the funds to the seller, called by buyer or arbiter
    function releaseFunds() external {
        require(isAgreementMade, "Agreement must be made first");
        require(msg.sender == buyer || msg.sender == arbiter, "Only buyer or arbiter can release funds");
        require(address(this).balance >= amount, "Insufficient balance in escrow");

        payable(seller).transfer(amount);

        emit Released(seller, amount);
    }

    // Refund function, called by the buyer or arbiter if agreement is not reached
    function refund() external {
        require(!isAgreementMade, "Agreement has already been made");
        require(msg.sender == buyer || msg.sender == arbiter, "Only buyer or arbiter can refund");
        require(address(this).balance >= amount, "Insufficient balance in escrow");

        payable(buyer).transfer(amount);

        emit Refunded(buyer, amount);
    }
}
