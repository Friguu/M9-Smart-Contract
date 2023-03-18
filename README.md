#UltimateLend Smart Contract
The UltimateLend smart contract is a decentralized lending platform built on the Ethereum blockchain. It allows users to lend and borrow cryptocurrency in a peer-to-peer manner, without the need for a traditional financial intermediary. The smart contract is implemented in Solidity and has been audited for security.

##Features

Lending: Users can lend cryptocurrency and earn interest on their funds.
Borrowing: Users can borrow cryptocurrency by pledging collateral in the form of ULTokens.
Interest rates: Interest rates are set by the market and are based on supply and demand.
Fees: The platform charges a small fee on all loans to cover the cost of operation.
Tokenization: ULToken is an ERC-20 token that represents a user's share of the collateral pool.
Usage
To use the UltimateLend platform, users must first connect their Ethereum wallet to the platform. They can then deposit cryptocurrency into the platform to start earning interest. To borrow cryptocurrency, users must pledge collateral in the form of ULTokens.

##Smart Contract Functions

calcFees(uint256 _amount) pure public returns(uint256): Calculates the overall amount of fees for lenders.
calcServiceFee(uint256 _overallFees) pure public returns(uint256): Calculates the service fee for the platform.
calcID() public returns(uint256): Counts up the request ID and returns the new value.
changeTokenSmartContract(address _smartContractAddress) public onlyOwner: Allows the owner/deployer of the smart contract to change the smart contract for the custom token.
changeTokenId(uint256 _tokenId) public onlyOwner: Allows the owner/deployer of the smart contract to change the token ID of the custom token.
ULToken Smart Contract
The ULToken smart contract is an ERC-20 token that represents a user's share of the collateral pool on the UltimateLend platform. It is implemented in Solidity and has been audited for security.

##Features

ERC-20: ULToken is an ERC-20 token that can be traded on decentralized exchanges and stored in any Ethereum wallet.
Collateral: ULTokens are used as collateral on the UltimateLend platform.
Tokenization: Each ULToken represents a user's share of the collateral pool.

##Usage
To use ULToken, users can trade it on decentralized exchanges or use it as collateral on the UltimateLend platform.

##Smart Contract Functions
The ULToken smart contract includes standard ERC-20 functions, such as balanceOf, transfer, and approve. It also includes the following custom functions:

changeTokenSmartContract(address _smartContractAddress) public onlyOwner: Allows the owner/deployer of the smart contract to change the smart contract for the custom token.
changeTokenId(uint256 _tokenId) public onlyOwner: Allows the owner/deployer of the smart contract to change the token ID of the custom token.
##License
The UltimateLend and ULToken smart contracts belongs to group2 of Blokchain master degree Zigurat: @BENEDICT CONRADY and @ABDERRAHMANE CHOUKRI and KITTIPOOM AKSORNSUA.
