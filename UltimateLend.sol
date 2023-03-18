// SPDX-License-Identifier: MIT

//This is a Smart Contract that has a borrow/lend money function

//The idea is as follows:
//Person A wants to borrow 10 Ether. For that Person A creates a "Request". When the
//Request is created, it is available for everyone. If Person B wants to lend Person A
//the 10 Ether, Person B accepts the "Request" and sends the 10 Ether to the Smart Contract.
//Person A then has to pay back the borrowed amount (10 Ether), a fee as reward for the lender
//to incentivize people to lend money and a service fee for us maintaining the platform.
//If all debts are paid back, the "Request" becomes fulfilled and is inactive. 
//
//To outsorce the problem of trust for lenders we created our own token as ERC1155 Token.
//We assume, that only trusted people own this token (e.g. people have to be registered with their full name). 
//By that, the Smart Contract for this task becomes cleaner and has an integrated safety function to only lend money
//to trustet people.
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./ULToken.sol";

contract UltimateLend {

    //using the OpenZeppelin SmartContract to count the amount of Requests
    using Counters for Counters.Counter;
    Counters.Counter internal requestID;

    //safe the "owner" address of this smart contract
    address owner;

    //store the address that receives the service fee
    address payable receipientServiceFee;

    //enum for the states that a Request has
    enum requestState{created, accepted, fulfilled}

    //mapping that contains the amount of debts open
    //extra mapping to check amount for a specific address (can't efficiently search for an address in a struct
    //thats why we the mapping)
    mapping(address => uint256) debtAmount;

    //mapping that maps the address of the borrower to a request ID => by that a borrower can only have one active request
    mapping(address => uint256) requestOfBorrower;

    //smart contract for our own Ultimate Lend Troken
    ULToken public token;
    
    //since we are using ERC1155 on which you can mint multiple token, we have to specify the token ID
    uint256 currentTokenId;

    //structure contains all data of a Request to borrow money
    struct stc_moneyRequest {
        address payable lender;     //the address that gets the money
        address payable borrower;   //the address that gives the money
        uint256 rewardFee;          //the amount of fees to be paid by the lender
        uint256 serviceFee;         //the amount of fees for the service provider
        uint256 borrowedAmount;     //the amount the borrower requests
        uint256 totalAmount;        //the requested amount + fees
        uint256 openAmount;         //the amount thats still open to be paid back by the borrower
        requestState state;         //the state of the current Request
        bool serviceFeePaid;        //bool flag to check, wether the service fee for the request is paid or not
    }

    //map a Request ID to the Request data
    mapping(uint256 => stc_moneyRequest) public moneyRequests;

    //a modifier for functions that only the owner of this smart contract can call
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    //modifier for functions that should only be executable by someone that owns the custom token
    modifier hasCustomToken() {
        require(token.balanceOf(msg.sender, currentTokenId) > 0, "Error: account has no ULToken");
        _;
    }

    //modifier to check if the borrower is also whitelisted
    modifier isWhitelisted() {
        require(token.isWhitelistedLender(msg.sender), "Error: account is not whitelisted");
        _;
    }

    //constructor only initializes the custom token smart contract and the ID of the token
    //both can be changed afterwards by the owner (owner = deployer of this contract)
    constructor(address _tokenSmartContract, uint256 _tokenId) {

        token = ULToken(_tokenSmartContract);
        currentTokenId = _tokenId;

        owner = msg.sender;
        receipientServiceFee = payable(owner);

    }

    //____________
    //Borrow functions

    //with this function a trusted person can open a Request to lend money.
    function createMoneyRequest(uint256 _amount) public hasCustomToken isWhitelisted {
        require(getOpenDebts() == 0, "Error: you already have open debts");

        uint256 amountWei = _amount * 1000000000000000000;

        //uint256 fees = calcFees(amountWei);
        //uint256 serviceFee = calcServiceFee(amountWei);

        uint256 totalAmount = amountWei + calcFees(amountWei) + calcServiceFee(amountWei);
        moneyRequests[calcID()] = stc_moneyRequest(payable(address(0x0)), payable(msg.sender), calcFees(amountWei), calcServiceFee(amountWei), 
                                                        amountWei, totalAmount, totalAmount, requestState.created, false);

        requestOfBorrower[msg.sender] = requestID.current();
    }
    
    //if a Request is accepted and money is borrowed, this function is used to pay back the
    //borrowed amount and fees included
    function payDebts() public payable {
        //the msg.value has to be greater than 0 to pay back at least anything
        require(msg.value > 0, "Error: you can't pay 0 Token back");
        //the amount of open debts has to greater than 0, otherwise nothing is left to paid back
        require(debtAmount[msg.sender] > 0, "Error: no debts left");
        //the debt amount has to be greater or equal to the msg value, otherwise maybe too much is paid back
        require(debtAmount[msg.sender] >= msg.value, "Error: more token sent that there are open debts");
        //a valid request ID has to be stored for the borrower; required because the request ID is necessary for further computing
        require(requestOfBorrower[msg.sender] != 0, "Error: no valid request ID for this account");
        //the state of the request has to be "accepted", otherwise it is only created or already fulfilled
        require(moneyRequests[requestOfBorrower[msg.sender]].state == requestState.accepted, "Error: the request is no accepted or already fulfilled");
        

        //store the msg value to evetually decrease it by the serice fee
        uint256 amount = msg.value;

        //if the service fee is not paid, pay it
        if(!moneyRequests[requestOfBorrower[msg.sender]].serviceFeePaid){
            receipientServiceFee.transfer(moneyRequests[requestOfBorrower[msg.sender]].serviceFee);
            amount -= moneyRequests[requestOfBorrower[msg.sender]].serviceFee;
            moneyRequests[requestOfBorrower[msg.sender]].serviceFeePaid = true;
        }

        //transfer the paid money to the lender
        moneyRequests[requestOfBorrower[msg.sender]].lender.transfer(amount);

        //reduce debts by the paid amount
        moneyRequests[requestOfBorrower[msg.sender]].openAmount -= msg.value;
        debtAmount[msg.sender] = moneyRequests[requestOfBorrower[msg.sender]].openAmount;


        //bring to an own internal function
        //if all debts are paid, note that in the variables
        if(moneyRequests[requestOfBorrower[msg.sender]].openAmount == 0) {
            moneyRequests[requestOfBorrower[msg.sender]].state = requestState.fulfilled;
        }
    }

    //if someone that borrowed money wants to check the open debts for his address
    //this function return the left amount
    function getOpenDebts() view public returns(uint256) {
        return debtAmount[msg.sender];
    }

    //____________
    //Lend functions

    //to accept an open Request this function is called. The function is
    //marked as payable to send token
    function acceptRequest(uint256 _requestID) public payable {
        //the message value the amount to be borrowed is required
        require(msg.value == moneyRequests[_requestID].borrowedAmount, "Error: sent amount is not equal to requested amount");
        //the state has to be created to be accepted, otherwise the request is already accepted or fulfilled
        require(moneyRequests[_requestID].state == requestState.created, "Error: the request is already accepted or fulfilled");
        
        //set the lender for this money request
        moneyRequests[_requestID].lender = payable(msg.sender);

        //transfer the lent money to the borrower
        moneyRequests[_requestID].borrower.transfer(msg.value);

        //change state of the money request
        moneyRequests[_requestID].state = requestState.accepted;

        //set debt counter for borrower
        debtAmount[moneyRequests[_requestID].borrower] = moneyRequests[_requestID].totalAmount;

    }

    //____________
    //Util functions 

    //calculates the overall amount fees for lender
    function calcFees(uint256 _amount) pure public returns(uint256) {
        //calculate 2%
        return _amount*2/100;
    }

    //this calculates the service fee
    function calcServiceFee(uint256 _overallFees) pure public returns(uint256) {
        //calculate 1%
        return _overallFees*1/100;
    }

    //counts up the requestID and returns the new value
    function calcID() public returns(uint256) {
        requestID.increment();
        return requestID.current();
    }

    //function for the owner/deployer of this SC to change the smart contract for the custom Token
    function changeTokenSmartContract(address _smartContractAddress) public onlyOwner {
        token = ULToken(_smartContractAddress);
    }

    //function for the owner/deployer of this SC to change the token ID of the custom token
    function changeTokenId(uint256 _tokenId) public onlyOwner {
        currentTokenId = _tokenId;
    }
}
