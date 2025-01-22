// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";


/// @title NFTCollection
/// @author @Oscarprdev
/// @dev A simple NFT collection contrac
contract NFTCollection is ERC721URIStorage {
    /// @notice nft counter
    uint256 public NFTTokenIdCounter;

    /// @notice nft offers counter
    uint256 public offersCount;

    /// @notice owner address
    address immutable owner;

    /// @notice NFT struct 
    /// @param tokenId Unique token ID
    /// @param creator Creator of the NFT
    /// @param owner Current owner of the NFT
    /// @param uri Metadata URI
    /// @param price Price if listed for sale
    /// @param isListed Is it listed for sale
    /// @param timestamp Minting timestamp
    struct NFT {
        uint256 tokenId;      
        address creator;      
        address owner;        
        string uri;           
        uint256 price;        
        bool isListed;        
        uint256 timestamp;    
    }

    /// @notice NFT Offer struct 
    /// @param offerId Offer ID
    /// @param tokenId Unique token ID
    /// @param buyer Buyer address
    /// @param price Price
    /// @param expirationDate Expiration date
    struct NFTOffer {
        uint256 offerId;
        uint256 tokenId;
        address buyer;
        uint256 price;
        uint256 expirationDate;
    }

    /// @notice nft list
    mapping(uint256 => NFT) private nftList;

    /// @notice nft offers mapping
    mapping(uint256 => NFTOffer) private offers;

    /// @notice nft list by owner mapping
    mapping(address => mapping(uint256 => NFT)) private nftListByOwner;

    /// @notice nft ids list by owner mapping
    mapping(address => uint256[]) private ownedTokenIds;

    /// @notice nft offers by owner mapping
    mapping(address => mapping(uint256 => NFTOffer)) private nftOffersByUser;

    /// @notice offers ids list by owner mapping
    mapping(address => uint256[]) private ownedOffersIds;

    /// @notice nft offers by nft item
    mapping(uint256 => mapping(uint256 => NFTOffer)) private nftOffersByNft;

    /// @notice event emitted when a new NFT is minted
    /// @param owner Owner address
    /// @param tokenId Token ID
    event NFTMinted(address indexed owner, uint256 indexed tokenId);

    /// @notice event emitted when an NFT is sold     
    /// @param from Seller address
    /// @param to Buyer address
    /// @param price Price
    event NFTSelled(address indexed from, address indexed to, uint price);

    /// @notice event emitted when an NFT offer is created
    /// @param from Seller address
    /// @param tokenId Token ID
    /// @param offerId Offer ID
    /// @param price Price
    event NFTOfferCreated(address indexed from, uint256 indexed tokenId, uint256 indexed offerId, uint256 price);

    /// @notice event emitted when an NFT offer is accepted
    /// @param from Buyer address
    /// @param tokenId Token ID
    /// @param offerId Offer ID
    event NFTOfferAccepted(address indexed from, uint256 indexed tokenId, uint256 indexed offerId);

    /// @notice event emitted when an NFT offer is canceled
    /// @param offerId Offer ID 
    event NFTOfferCanceled(uint256 indexed offerId);

     
    /// @notice event emitted when an NFT is set as listed
    /// @param tokenId Token ID 
    event NFTSetAsListed(uint256 indexed tokenId);

    /// @notice error thrown when an offer does not exist
    /// @param offerId Offer ID
    error OfferDoesNotExist(uint256 offerId);

    /// @notice error thrown when an NFT does not exist
    /// @param tokenId Token ID
    error NFTDoesNotExist(uint256 tokenId);

    /// @notice error thrown when a user does not exist
    /// @param user User address
    error UserDoesNotExist(address user);

    /// @notice modifier to check if the caller is the owner 
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert UserDoesNotExist(owner);
        }
        _;
    }

    /// @notice modifier to check if the NFT exists
    /// @param _tokenId Token ID
    modifier NFTExists(uint256 _tokenId) {
        if (nftList[_tokenId].tokenId == 0) {
            revert NFTDoesNotExist(_tokenId);
        }
        _;
    }

    /// @notice modifier to check if the NFT offer exists    
    /// @param _offerId Offer ID
    modifier NFTOfferExists(uint256 _offerId) {
        if (offers[_offerId].offerId == 0) {
            revert OfferDoesNotExist(_offerId);
        }
        _;
    }

    /// @notice constructor
    /// @dev sets the owner address
    constructor() ERC721("NFT Collection", "NFTC") {
        owner = msg.sender;
    }

    /// @notice mints a new NFT
    /// @dev mints a new NFT with the given URI and price
    /// @param _uri URI of the NFT
    /// @param _price Price of the NFT     
    function mintNFT(string memory _uri, uint256 _price) external onlyOwner {
         require(bytes(_uri).length > 0, "URI cannot be empty");     
         require(_price > 0, "Price must be greater than zero");

         NFTTokenIdCounter++;
         NFT memory newNFT = NFT({
            tokenId: NFTTokenIdCounter,
            creator: msg.sender,
            owner: msg.sender,
            uri: _uri,
            price: _price,
            isListed: false, /// @notice default to not listed
            timestamp: block.timestamp
        });

        nftList[NFTTokenIdCounter] = newNFT;
        nftListByOwner[msg.sender][NFTTokenIdCounter] = newNFT;
        ownedTokenIds[msg.sender].push(NFTTokenIdCounter);

        _safeMint(msg.sender, NFTTokenIdCounter);
        _setTokenURI(NFTTokenIdCounter, _uri);

        emit NFTMinted(msg.sender, NFTTokenIdCounter);
    }

    /// @notice removes an NFT
    /// @dev removes an NFT with the given token ID
    /// @param _owner Owner address
    /// @param _tokenId Token ID
    function removeNFT(address _owner, uint256 _tokenId) private NFTExists(_tokenId) {
        for (uint256 i =0; i < offersCount; i++) {
            if (offers[i].tokenId == _tokenId) {
                uint256 _offerId = offers[i].offerId;

                delete nftOffersByNft[_tokenId][_offerId];
                delete offers[_offerId];
            }
        }
        
        delete nftListByOwner[_owner][_tokenId];
        delete nftOffersByUser[msg.sender][_tokenId];
        removeNFTFromOwner(_owner, _tokenId);
        
        uint256[] storage tokenIds = ownedTokenIds[_owner];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == _tokenId) {
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                break;
            }
        }
    }

    /// @notice creates an NFT offer
    /// @dev creates an NFT offer with the given token ID
    /// @param _tokenId Token ID     
    function createOffer(uint256 _tokenId) external payable NFTExists(_tokenId) {
        require(msg.value > 0, "Price must be greater than zero");
        require(nftList[_tokenId].isListed, "NFT is not listed for sale");

        offersCount++;
        NFTOffer memory newOffer = NFTOffer({
            offerId: offersCount,
            tokenId: _tokenId,
            buyer: msg.sender,
            price: msg.value,
            expirationDate: block.timestamp + 1 days
        });

        offers[offersCount] = newOffer;
        nftOffersByUser[msg.sender][_tokenId] = newOffer;
        nftOffersByNft[_tokenId][offersCount] = newOffer;
        ownedOffersIds[msg.sender].push(offersCount);

        emit NFTOfferCreated(
            msg.sender, 
            _tokenId, 
            offersCount, 
            msg.value
        );
    }

    /// @notice cancels an NFT offer
    /// @dev cancels an NFT offer with the given offer ID     
    /// @param _offerId Offer ID
    function cancelOffer(uint256 _offerId) external NFTOfferExists(_offerId) {
        NFTOffer memory nftOffer = offers[_offerId];
        NFT memory nft = nftList[nftOffer.tokenId];

        require(msg.sender == nftOffer.buyer, "Only buyer can cancel offer");

        delete nftOffersByNft[nft.tokenId][_offerId];
        delete nftOffersByUser[msg.sender][nftOffer.tokenId];
        delete offers[_offerId];
        removeOfferFromOwner(msg.sender, _offerId);
        
        emit NFTOfferCanceled(_offerId);
    }

    /// @notice accepts an NFT offer
    /// @dev accepts an NFT offer with the given offer ID
    /// @param _offerId Offer ID
    function acceptOffer(uint256 _offerId) external payable NFTOfferExists(_offerId) {
        NFTOffer memory nftOffer = offers[_offerId];
        NFT memory nft = nftList[nftOffer.tokenId];

        require(msg.sender == nftOffer.buyer, "Only buyer can accept offer");
        require(nftOffer.expirationDate > block.timestamp, "Offer has expired");

        delete nftOffersByNft[nftOffer.tokenId][_offerId];
        delete nftOffersByUser[nftOffer.buyer][nftOffer.tokenId];
        delete offers[_offerId];
        removeNFTFromOwner(msg.sender, nftOffer.tokenId);
        removeOfferFromOwner(nftOffer.buyer, nftOffer.offerId);

        nft.owner = msg.sender;
        nftList[nftOffer.tokenId] = nft;
        ownedTokenIds[nftOffer.buyer].push(nftOffer.tokenId);

        (bool success,) = payable(msg.sender).call{value: nftOffer.price}("");
        require(success, "Failed to send Ether to NFT owner");

        emit NFTOfferAccepted(        
            nftOffer.buyer,
            nftOffer.tokenId,
            _offerId
        );
    }

    /// @notice sets an NFT as listed for sale
    /// @dev sets an NFT as listed for sale
    /// @param _tokenId Token ID
    function setNFTAsListed(uint256 _tokenId) external NFTExists(_tokenId) {
         NFT storage nft = nftList[_tokenId];
        require(msg.sender == nft.owner, "Only NFT owner can set as listed");
       
        nft.isListed = true;

        emit NFTSetAsListed(_tokenId);
    }

    /// @notice gets all NFTs
    /// @dev gets all NFTs
    /// @param _offset Offset
    /// @param _limit Limit
    /// @return nfts NFTs
    function getNfts(uint256 _offset, uint256 _limit) external view returns (NFT[] memory) {
        require(_offset > 0, "Offset must be greater than zero");
        require(_limit > 0, "Limit must be greater than zero");
        require(_limit > _offset, "Limit must be greater than offset");
        require(_limit <= NFTTokenIdCounter, "Limit must be less than total NFTs");

        uint256 itemsToReturn = _limit - _offset + 1;
        NFT[] memory nfts = new NFT[](itemsToReturn);

        for (uint256 i = _offset; i < _limit; i++) {
            nfts[i - 1] = nftList[i];
        }

        return nfts;
    }

    /// @notice gets an NFT by ID
    /// @dev gets an NFT by ID
    /// @param _tokenId Token ID
    /// @return nft NFT
    function getNFTById(uint256 _tokenId) external view NFTExists(_tokenId) returns (NFT memory) {
        return nftList[_tokenId];
    }

    /// @notice gets an NFT by owner
    /// @dev gets an NFT by owner
    /// @param _owner Owner address
    /// @param _tokenId Token ID
    /// @return nft NFT
    function getNFTByOwner(address _owner, uint256 _tokenId) external view returns (NFT memory) {
        return nftListByOwner[_owner][_tokenId];
    }

    /// @notice gets all NFTs by owner
    /// @dev gets all NFTs by owner
    /// @param _owner Owner address
    /// @return items NFTs by owner
    function getNFTsByOwner(address _owner) external view returns (NFT[] memory) {
        require(false, "Not implemented");
    }

    /// @notice gets all NFT offers
    /// @dev gets all NFT offers
    /// @param _offset Offset
    /// @param _limit Limit
    /// @return offers Offers
    function getOffers(uint256 _offset, uint256 _limit) external view returns (NFTOffer[] memory) {
        require(_offset > 0, "Offset must be greater than zero");
        require(_limit > 0, "Limit must be greater than zero");
        require(_limit > _offset, "Limit must be greater than offset");
        require(_limit <= offersCount, "Limit must be less than total NFTs");

        uint256 itemsToReturn = _limit - _offset + 1;
        NFTOffer[] memory offersToReturn = new NFTOffer[](itemsToReturn);

        for (uint256 i = _offset; i < _limit; i++) {
            offersToReturn[i - 1] = offers[i];
        }

        return offersToReturn;
    }

    /// @notice gets an NFT offer by ID
    /// @dev gets an NFT offer by ID
    /// @param _offerId Offer ID     
    /// @return offer Offer
    function getOfferById(uint256 _offerId) external view NFTOfferExists(_offerId) returns (NFTOffer memory) {
        return offers[_offerId];
    }

    /// @notice gets an NFT offer by owner
    /// @dev gets an NFT offer by owner
    /// @param _owner Owner address
    /// @param _offerId Offer ID
    /// @return offer Offer
    function getOfferByOwner(address _owner, uint256 _offerId) external view returns (NFTOffer memory) {
        return nftOffersByUser[_owner][_offerId];
    }

    function getOffersByOwner(address _owner) external view returns (NFTOffer[] memory) {
        require(false, "Not implemented");
    }

    function getOffersByNft(uint256 _tokenId) external view returns (NFTOffer[] memory) {
        require(false, "Not implemented");
    }

    /// @notice removes an NFT from owner
    /// @dev removes an NFT from owner
    /// @param _owner Owner address to remove NFT from
    /// @param _tokenId Token ID to remove
    function removeNFTFromOwner(address _owner, uint256 _tokenId) private NFTExists(_tokenId) {
        uint256[] storage tokenIds = ownedTokenIds[_owner];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == _tokenId) {
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                break;
            }
        }
    }

    /// @notice removes an Offer from owner
    /// @dev removes an Offer from owner
    /// @param _owner Owner address to remove Offer from
    /// @param _offerId Offer ID to remove
    function removeOfferFromOwner(address _owner, uint256 _offerId) private NFTOfferExists(_offerId) {
        uint256[] storage offersIds = ownedOffersIds[_owner];
        for (uint256 i = 0; i < offersIds.length; i++) {
            if (offersIds[i] == _offerId) {
                offersIds[i] = offersIds[offersIds.length - 1];
                offersIds.pop();
                break;
            }
        }
    }
}