// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public onlyOwner
    {
        _mint(account, id, amount, data);
        whitelistLender[account] = true;
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function isWhitelistedLender(address _lender) public view returns (bool) {
        return whitelistLender[_lender];
    }

    function blockFromWhitelist(address _addr) public returns (bool) {
        return whitelistLender[_addr] = false;
    }

}
