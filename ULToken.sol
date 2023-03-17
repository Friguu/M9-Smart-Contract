// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//the idea of the custom token for our lending/borrowing smart contract is to provide
//multiple security layers:
//1. we assume that only trusted persons get the token, because in most countries a KYC is needed to buy token
        // -> so we probably would require a KYC on our website to give out the token, by that we can identify our lenders
//2. when a token gets minted the receipient is added to a whitelist. Only people on the whitelist can lend money
        // -> when someone shows bad behavior we can block him, even though the person has the token

//we use ERC1155 standard to be flexible in token design. We e.g. could start with a ERC20-like token and later switch to
//ERC721-like token. The only necessary thing for that to do is mint token with either the same ID or with different IDs, to
//switch between fungible and non-fungible token design.

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ULToken is ERC1155 {

    //safe the "owner" address of this smart contract
    address owner;

    //mapping for a white list of the lender
    //if the lender owns the token, but shows a bad behavior he gets blocked in the whitelist
    mapping(address => bool) whitelistLender;

    //a modifier for functions that only the owner of this smart contract can call
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() ERC1155("") {
        owner = msg.sender;
    }

    function mint(address account, uint256 id, uint256 amount)
        public onlyOwner
    {   
        require(whitelistLender[account] == true, "Error: borrower already exists");
        //data not needed in our use case, so we just pass a dummy value
        bytes memory data = '0x';
        _mint(account, id, amount, data);
        whitelistLender[account] = true;
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
        public onlyOwner
    {   
        //data not needed in our use case, so we just pass a dummy value
        bytes memory data = '0x';
        _mintBatch(to, ids, amounts, data);
    }

    function isWhitelistedLender(address _lender) public view returns (bool) {
        return whitelistLender[_lender];
    }

    function blockFromWhitelist(address _addr) public returns (bool) {
        return whitelistLender[_addr] = false;
    }

}
