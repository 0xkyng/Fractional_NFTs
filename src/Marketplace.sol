// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "solmate/tokens/ERC721.sol";

import "openzeppelin/interfaces/IERC721.sol";
// "solmate/tokens/ERC721/IERC721.sol";
import {SignUtils} from "./libraries/SignUtils.sol";

import {FractionalNFT} from "src/ERC20Mock.sol";

contract Marketplace {
    struct Catalogue {
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        bytes signature;
        uint88 deadline;
        address creator;
        bool active;
        uint256 fractionCount;
        uint256 fractionPrice;
        address frn;
    }

    mapping(uint256 => Catalogue) public catalogues;
    address public owner;
    uint256 public catalogueId;


    /* EVENTS */
    event CreatedCatalogue(uint256 indexed catalogueId, Catalogue);
    event ExecutedCatalogue(uint256 indexed catalogueId, Catalogue);
    event EditedCatalogue(uint256 indexed catalogueId, Catalogue);

    constructor() {
        owner = msg.sender;
    }

    function createCatalogue(Catalogue calldata c) public returns (uint256) {
        require(ERC721(c.nftAddress).ownerOf(c.tokenId) == msg.sender, "NOt the owner");
        require(ERC721(c.nftAddress).isApprovedForAll(msg.sender, address(this)), "You don't have approval to sell this nft");
        
        require(c.price > (0.01 * 100), "Low price");
        require(c.deadline > block.timestamp, 'Deadline too short');

        // Assert signature
        require(SignUtils.isValid(
                SignUtils.constructMessageHash(
                    c.nftAddress,
                    c.tokenId,
                    c.price,
                    c.deadline,
                    c.creator
                ),
                c.signature,
                msg.sender
            ), "Invalid signsture");

        // append to Storage
        Catalogue storage newCatalogue = catalogues[catalogueId];
        newCatalogue.nftAddress = c.nftAddress;
        newCatalogue.tokenId = c.tokenId;
        newCatalogue.price = c.price;
        newCatalogue.signature = c.signature;
        newCatalogue.deadline = uint88(c.deadline);
        newCatalogue.creator = msg.sender;
        newCatalogue.active = true;
        newCatalogue.fractionCount = c.fractionCount;
        newCatalogue.fractionPrice = c.fractionPrice;

        
        //Mint the equivalent of the amount of the token in ERC20 tokens
        FractionalNFT(newCatalogue.frn).mint(
            address(this),
            c.fractionPrice * c.fractionCount
        );
        
        // Emit event
        emit CreatedCatalogue(catalogueId, newCatalogue);
        uint256 _catalogue = catalogueId;
        catalogueId++;
        return _catalogue;
    }


    function executeCatalogue(uint256 _catalogueId) public payable {
        require(_catalogueId <= catalogueId, "Catalogue does not exist");

        Catalogue storage newCatalogue = catalogues[_catalogueId];

        require(newCatalogue.deadline > block.timestamp, "Expired catalogue");
        require(newCatalogue.active, "Inactive catalogue");
        require(newCatalogue.price == msg.value, "Inappriopriate price");

        // Update state
        newCatalogue.active = false;

        // Mint an ERC20 token to the user of the amount the NFT is for.
        FractionalNFT(newCatalogue.frn).mint(msg.sender, msg.value);
        // Burn the equivalent of the ERC20 token minted to the caller
        FractionalNFT(newCatalogue.frn).burn(address(this), msg.value);

        // calculate 0.1% of the purchased amount
        uint platformAmount = (newCatalogue.fractionPrice * 1) / 1000;

        // transfer eth
        payable(owner).transfer(newCatalogue.fractionPrice - platformAmount);

        // transfer eth to platform
        payable(owner).transfer(platformAmount);

        // Update storage
        emit ExecutedCatalogue(_catalogueId, newCatalogue);
    }

    function fractionTransfer(uint256 _catalogueId, address _to) public {
        Catalogue storage newCat = catalogues[_catalogueId];
        payable(_to).transfer(newCat.fractionPrice);
    }

    function editCatalogue(
        uint256 _catalogueId,
        uint256 _newPrice,
        bool _active
    ) public {
        require(_catalogueId <= catalogueId, "Catalogue does not exist");

        Catalogue storage newCatalogue = catalogues[_catalogueId];
    
        require(newCatalogue.creator == msg.sender, "You are not the owner");
        newCatalogue.price = _newPrice;
        newCatalogue.active = _active;
        emit EditedCatalogue(_catalogueId, newCatalogue);
    }

    
    function getCatalogue(
        uint256 _catalogueId
    ) public view returns (Catalogue memory) {
        return catalogues[_catalogueId];
    }
}
