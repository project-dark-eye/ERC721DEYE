// SPDX-License-Identifier: MIT
// Author: Mas C. (Project Dark Eye)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721DEYE.sol";

contract Machines is Ownable, ERC721DEYE, ReentrancyGuard {
    enum ContractStatus {
        Paused,
        PresaleOne,
        PresaleTwo,
        Public
    }
    ContractStatus public contractStatus = ContractStatus.Paused;

    string  public baseURI;
    uint256 public price = 0.03 ether;
    uint256 public totalMintSupply = 4000;
    uint256 public publicMintTransactionLimit = 5;
    uint256 public presaleOneAllowedCount = 1;
    uint256 public presaleTwoAllowedCount = 3;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(string memory contractBaseURI)
    ERC721DEYE ("Time Machines by Project Dark Eye", "DEYEMACHINE") {
        baseURI = contractBaseURI;
    }

    function _baseURI() internal view override(ERC721DEYE) returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override(ERC721DEYE) returns (uint256) {
        return 1;
    }

    function mintPublic(uint64 quantity) public payable callerIsUser {
        require(contractStatus == ContractStatus.Public, "Public minting not available"); 
        require(msg.value >= price * quantity, "Not enough ETH sent");
        require(_totalMinted() + quantity <= totalMintSupply, "Not enough supply");
        require(quantity <= publicMintTransactionLimit, "Exceeds allowed transaction limit");

        _safeMint(msg.sender, quantity);
    }

    function mintPresaleOne(uint64 quantity) public payable callerIsUser {
        require(contractStatus == ContractStatus.PresaleOne, "Presale #1 not available");
        require(msg.value >= price * quantity, "Not enough ETH sent");
        require(_numberMinted(msg.sender) + quantity <= mintAllowedQuantityForAddress(msg.sender, ContractStatus.PresaleOne), "Exceeds allowed wallet quantity");

        _safeMint(msg.sender, quantity);
    }

    function mintPresaleTwo(uint64 quantity) public payable callerIsUser {
        require(contractStatus == ContractStatus.PresaleTwo, "Presale #2 not available");
        require(msg.value >= price * quantity, "Not enough ETH sent");
        require(_numberMinted(msg.sender) + quantity <= mintAllowedQuantityForAddress(msg.sender, ContractStatus.PresaleTwo), "Exceeds allowed wallet quantity");

        _safeMint(msg.sender, quantity);
    }

    function mintAllowedQuantityForAddress(address account, ContractStatus stage) public view returns (uint256) {
        if (stage == ContractStatus.Public) {
            return publicMintTransactionLimit;
        }
        (bool presaleOneAllowed, bool presaleTwoAllowed) = _getMintAllowance(account);
        uint256 presaleOneAllowedNum = 0;
        uint256 presaleTwoAllowedNum = 0;
        if (presaleOneAllowed) {
            presaleOneAllowedNum += presaleOneAllowedCount;
            presaleTwoAllowedNum += presaleOneAllowedCount;
        }
        if (presaleTwoAllowed) {
            presaleTwoAllowedNum += presaleTwoAllowedCount;
        }
        if (stage == ContractStatus.PresaleOne) {
            return presaleOneAllowedNum;
        }
        if (stage == ContractStatus.PresaleTwo) {
            return presaleTwoAllowedNum;
        }
        return 0;
    }
    

    // Owner Only

    function setContractStatus(ContractStatus status) public onlyOwner {
        contractStatus = status;
    }

    function setTotalMintSupply(uint256 supply) public onlyOwner {
        totalMintSupply = supply;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setAllowlist(address[] memory addresses, bool[] memory presaleOneAllowed, bool[] memory presaleTwoAllowed) external onlyOwner {
        require(addresses.length == presaleOneAllowed.length && addresses.length == presaleTwoAllowed.length, "addresses does not match allowance length");
        for (uint256 i = 0; i < addresses.length; i++) {
            _setMintAllowance(addresses[i], presaleOneAllowed[i], presaleTwoAllowed[i]);
        }
    }

    function teamMint(address[] memory addresses, uint64[] memory quantities) external onlyOwner {
        require(addresses.length == quantities.length, "addresses does not match quatities length");
        uint64 totalQuantity = 0;
        for (uint i = 0; i < quantities.length; i++) {
            totalQuantity += quantities[i];
        }
        require(_totalMinted() + totalQuantity <= totalMintSupply, "Not enough supply");
        for (uint i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], quantities[i]);
        }
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transaction Unsuccessful");
    }
}