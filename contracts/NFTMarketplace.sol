// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract NFTCollection is ERC721URIStorage {
    uint256 public NFTCount;
    uint256 public offersCount;
    address immutable owner;
    // uint256 constant FEE = 0.0015 ether;

    struct NFT {
        uint256 tokenId;       // Unique token ID
        address creator;       // Creator of the NFT
        address owner;         // Current owner of the NFT
        string uri;            // Metadata URI
        uint256 price;         // Price if listed for sale
        bool isListed;         // Is it listed for sale
        uint256 timestamp;     // Minting timestamp
    }

    struct NFTOffer {
        uint256 offerId;
        uint256 tokenId;
        address buyer;
        uint256 price;
        uint256 expirationDate;
    }

    NFT[] public nftList;
    NFTOffer[] public offersList;

    event NFTMinted(address indexed owner, uint256 indexed tokenId);
    event NFTSelled(address indexed from, address indexed to, uint price);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() ERC721("NFT Collection", "NFTC") {
        owner = msg.sender;
    }

    function mintNFT(string memory _uri, uint _price) external {
         NFTCount++;
         NFT memory newNFT = NFT({
            tokenId: NFTCount,
            creator: msg.sender,
            owner: msg.sender,
            uri: _uri,
            price: _price,
            isListed: false, // Default to not listed
            timestamp: block.timestamp
        });

        nftList.push(newNFT);

        _safeMint(msg.sender, NFTCount);
        _setTokenURI(NFTCount, _uri);

        // (bool success, ) = payable(address(this)).call{value: FEE}("");
        // require(success, "Mint payment fee failed");

        emit NFTMinted(msg.sender, NFTCount);
    }

    function createOffer(uint256 _tokenId, uint256 _expirationDate) external payable {
        require(_expirationDate > block.timestamp, "Expiration date must be greater thant the block timestamp");

        // Find the NFT to offer by token id
        NFT memory nftToOffer;
        for (uint i = 0; i < nftList.length; i++) {
            if (nftList[i].tokenId == _tokenId) {
                nftToOffer = nftList[i];
                break;
            }
        }

        // Check if the offer is higher than the current highest offer
        uint256 highestOfferPrice = 0;
        for (uint i = 0; i < offersList.length; i++) {
            if (offersList[i].tokenId == _tokenId && offersList[i].price > highestOfferPrice) {
                highestOfferPrice = offersList[i].price;
            }
        }
        require(msg.value > highestOfferPrice, "Your offer must be higher than the current highest offer");

        offersCount++;
        offersList.push(NFTOffer({
            offerId: offersCount,
            tokenId: _tokenId,
            buyer: msg.sender,
            price: msg.value,
            expirationDate: _expirationDate
        }));
    }

    function finalizeAuction(uint256 _tokenId) external {
        // Find the NFT to sell by token id
        NFT memory nftToSell;
        for (uint i = 0; i < nftList.length; i++) {
            if (nftList[i].tokenId == _tokenId) {
                nftToSell = nftList[i];
                break;
            }
        }
        require(nftToSell.isListed, "NFT must be listed for auction");

        // Find the highest offer by token id and expiration date
        uint256 highestOfferPrice = 0;
        uint256 highestOfferId;
        address highestBidder;
        for (uint i = 0; i < offersList.length; i++) {
            if (offersList[i].tokenId == _tokenId && block.timestamp >= offersList[i].expirationDate) {
                if (offersList[i].price > highestOfferPrice) {
                    highestOfferPrice = offersList[i].price;
                    highestOfferId = offersList[i].offerId;
                    highestBidder = offersList[i].buyer;
                }
            }
        }
        require(highestOfferPrice > 0, "No valid offers found or auction has not expired");

        // Transfer the NFT to the highest bidder
        _transfer(nftToSell.owner, highestBidder, _tokenId);
        for (uint i = 0; i < nftList.length; i++) {
            if (nftList[i].tokenId == _tokenId) {
                nftList[i].owner = highestBidder;
                nftList[i].isListed = false;
                nftList[i].price = highestOfferPrice;
                break;
            }
        }

        (bool success, ) = payable(nftToSell.owner).call{value: highestOfferPrice}("");
        require(success, "Transfer to seller failed");

        // Update NFT offers array deletting all the offers for the NFT already sold
        deleteOffersForNFT(_tokenId);

        emit NFTSelled(nftToSell.owner, highestBidder, highestOfferPrice);
    }

    function getNFTsByOwner(address _address) external view returns (NFT[] memory) {
        uint itemCount;
        for (uint i = 0; i < nftList.length; i++) {
            if (nftList[i].owner == _address) {
                itemCount++;
            }
        }

        NFT[] memory nftsByOwner = new NFT[](itemCount);
        uint index = 0;
        for (uint i = 0; i < nftList.length; i++) {
            if (nftList[i].owner == _address) {
                nftsByOwner[index] = nftList[i];
                index++;
            }
        }

        return nftsByOwner;
    }

    function getNFTByTokenId(uint256 _tokenId) external view returns (NFT memory) {
         NFT memory nft;

        for (uint i = 0; i < nftList.length; i++) {
            if (nftList[i].tokenId == _tokenId) {
                nft = nftList[i];
                break;
            }
        }

        return nft;
    }

    function getOffersByTokenId(uint256 _tokenId) external view returns (NFTOffer[] memory) {
        uint itemCount;
        for (uint i = 0; i < offersList.length; i++) {
            if (offersList[i].tokenId == _tokenId) {
                itemCount++;
            }
        }

        NFTOffer[] memory offersByTokenId = new NFTOffer[](itemCount);
        uint index = 0;
        for (uint i = 0; i < offersList.length; i++) {
            if (offersList[i].tokenId == _tokenId) {
                offersByTokenId[index] = offersList[i];
                index++;
            }
        }

        return offersByTokenId;
    }

    function deleteOffersForNFT(uint256 _tokenId) internal {
        uint count;
        for (uint i = 0; i < offersList.length; i++) {
            if (offersList[i].tokenId == _tokenId) {
                count++;
            }
        }

        NFTOffer[] memory newOffersList = new NFTOffer[](offersList.length - count);
        uint index = 0;
        for (uint i = 0; i < offersList.length; i++) {
            if (offersList[i].tokenId != _tokenId) {
                newOffersList[index] = offersList[i];
                index++;
            }
        }

        delete offersList;
        for (uint i = 0; i < newOffersList.length; i++) {
            offersList.push(newOffersList[i]);
        }
    }
}