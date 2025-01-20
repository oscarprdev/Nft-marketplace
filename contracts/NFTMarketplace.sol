// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract NFTCollection is ERC721URIStorage {
    uint256 public NFTCount;
    uint256 public offersCount;
    address immutable owner;
    uint256 constant FEE = 0.0015 ether;

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
    }

    NFT[] public nftList;
    NFTOffer[] public offersList;

    event NFTMinted(address indexed owner, uint256 indexed tokenId);
    event NFTSelled(address indexed from, address indexed to, uint price);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() ERC721("NFT Marketplace", "NFTM") {
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
            isListed: false,
            timestamp: block.timestamp
        });

        nftList.push(newNFT);

        _safeMint(msg.sender, NFTCount);
        _setTokenURI(NFTCount, _uri);

        (bool success, ) = payable(address(this)).call{value: FEE}("");
        require(success, "Mint payment fee failed");

        emit NFTMinted(msg.sender, NFTCount);
    }

    function acceptOffer(uint256 _offerId) external payable onlyOwner {
        NFTOffer memory offer;
        for (uint i = 0; i < offersList.length; i++) {
            if (offersList[i].offerId == _offerId) {
                offer = offersList[i];
                break;
            }
        }

        NFT memory nftToSell;
        for (uint i = 0; i < nftList.length; i++) {
            if (nftList[i].tokenId == offer.tokenId) {
                nftToSell = nftList[i];
                break;
            }
        }

        require(nftToSell.price == offer.price, "Price must match the sent value");
        require(nftToSell.isListed, "NFT must be listed for sale");

        (bool success, ) = payable(msg.sender).call{value: offer.price}("");
        require(success, "Payment transfer failed");

        nftToSell.owner = offer.buyer;
        nftToSell.isListed = false;

        emit NFTSelled(msg.sender, offer.buyer, offer.price);
    }

    function createOffer(uint256 _tokenId) external payable {
        offersCount++;
        NFT memory nftToOffer;

         for (uint i = 0; i < nftList.length; i++) {
            if (nftList[i].tokenId == _tokenId) {
                nftToOffer = nftList[i];
                break;
            }
        }

        require(msg.value >= nftToOffer.price, "Price must be equal or greater than the current price");

        offersList.push(NFTOffer(offersCount, nftToOffer.tokenId, msg.sender, msg.value));

        (bool success, ) = payable(address(this)).call{value: msg.value}("");
        require(success, "Offer failed");
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
}