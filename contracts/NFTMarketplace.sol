// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

/**
 * @title NFTCollection
 * @author @Oscarprdev
 * @dev A simple NFT collection contract
 */
contract NFTCollection is ERC721URIStorage {
    /// @notice nft counter
    uint256 public NFTCount;

    /// @notice nft offers counter
    uint256 public offersCount;

    /// @notice owner address
    address immutable owner;

    /**
     * @notice NFT struct 
     * @param tokenId Unique token ID
     * @param creator Creator of the NFT
     * @param owner Current owner of the NFT
     * @param uri Metadata URI
     * @param price Price if listed for sale
     * @param isListed Is it listed for sale
     * @param timestamp Minting timestamp
     */
    struct NFT {
        uint256 tokenId;      
        address creator;      
        address owner;        
        string uri;           
        uint256 price;        
        bool isListed;        
        uint256 timestamp;    
    }

    /**
     * @notice NFT Offer struct 
     * @param offerId Offer ID
     * @param tokenId Token ID
     * @param buyer Buyer address
     * @param price Price
     * @param expirationDate Expiration date
     */
    struct NFTOffer {
        uint256 offerId;
        uint256 tokenId;
        address buyer;
        uint256 price;
        uint256 expirationDate;
    }

    /// @notice nft list
    NFT[] public nftList;

    /// @notice nft offers list
    NFTOffer[] public offersList;

    /**
     * @notice event emitted when a new NFT is minted
     * @param owner Owner address
     * @param tokenId Token ID
     */
    event NFTMinted(address indexed owner, uint256 indexed tokenId);

    /**
     * @notice event emitted when an NFT is sold     
     * @param from Seller address
     * @param to Buyer address
     * @param price Price
     */
    event NFTSelled(address indexed from, address indexed to, uint price);

    /** 
     * @notice modifier to check if the caller is the owner 
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /** 
     * @notice constructor
     * @dev sets the owner address
     */
    constructor() ERC721("NFT Collection", "NFTC") {
        owner = msg.sender;
    }

    /** 
     * @notice mints a new NFT
     * @dev mints a new NFT with the given URI and price
     * @param _uri URI of the NFT
     * @param _price Price of the NFT     
     */
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

        emit NFTMinted(msg.sender, NFTCount);
    }

    /** 
     * @notice creates an offer for a NFT
     * @dev creates an offer for a NFT with the given token ID and expiration date
     * @param _tokenId Token ID
     * @param _expirationDate Expiration date
     */
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

        /// @notice check if the offer is higher than the current highest offer
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

    /** 
     * @notice finalizes an auction for a NFT
     * @dev finalizes an auction for a NFT with the given token ID
     * @param _tokenId Token ID     
     */
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

        /// @notice find the highest offer by token id and expiration date
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

        /// @notice transfer the NFT to the highest bidder
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

        /// @notice update NFT offers array deleting all the offers for the NFT already sold
        deleteOffersForNFT(_tokenId);

        emit NFTSelled(nftToSell.owner, highestBidder, highestOfferPrice);
    }

    /** 
     * @notice returns all NFTs
     * @dev returns all NFTs
     * @return nftList NFT list     
     */
    function getNFTs() external view returns (NFT[] memory) {
        return nftList;
    }

    /** 
     * @notice returns all NFTs by owner
     * @dev returns all NFTs by owner
     * @param _address Owner address
     * @return nftsByOwner NFT list by owner     
     */
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

    /** 
     * @notice returns an NFT by token ID
     * @dev returns an NFT by token ID
     * @param _tokenId Token ID
     * @return nft NFT     
     */
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

    /** 
     * @notice returns all offers by token ID
     * @dev returns all offers by token ID
     * @param _tokenId Token ID
     * @return offersByTokenId Offers list by token ID     
     */
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

    /** 
     * @notice deletes all offers for a NFT
     * @dev deletes all offers for a NFT with the given token ID
     * @param _tokenId Token ID     
     */
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