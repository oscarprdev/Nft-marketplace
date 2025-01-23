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
    mapping(uint256 => NFT) private nfts;

    /// @notice nft offers
    mapping(uint256 => NFTOffer) private offers;

    /// @notice nft list by owner
    mapping(address => mapping(uint256 => NFT)) private nftsByOwnerID;

    /// @notice nft IDs by owner id
    mapping(address => uint256[]) private nftIDsByOwnerID;

    /// @notice nft offers by owner
    mapping(address => mapping(uint256 => NFTOffer)) private offersByOwnerID;

    /// @notice offers ids list by owner IDs
    mapping(address => uint256[]) private offersIDsByOwnerID;

    /// @notice nft offers by nft item
    mapping(uint256 => mapping(uint256 => NFTOffer)) private offersByNftID;

    /// @notice Offers IDs by NFT ID
    mapping(uint256 => uint256[]) private offersIdsByNFTID;

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
        if (nfts[_tokenId].tokenId == 0) {
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
    /// @param _uri URI of the NFT
    /// @param _price Price of the NFT     
    function mintNFT(string memory _uri, uint256 _price) external onlyOwner {
         require(bytes(_uri).length > 0, "URI cannot be empty");     
         require(_price > 0, "Price must be greater than zero");

         NFTTokenIdCounter++;
         NFT memory _nft = NFT({
            tokenId: NFTTokenIdCounter,
            creator: msg.sender,
            owner: msg.sender,
            uri: _uri,
            price: _price,
            isListed: false, /// @dev default to not listed
            timestamp: block.timestamp
        });

        nfts[NFTTokenIdCounter] = _nft;

        nftsByOwnerID[msg.sender][NFTTokenIdCounter] = _nft;
        nftIDsByOwnerID[msg.sender].push(NFTTokenIdCounter);

        _safeMint(msg.sender, NFTTokenIdCounter);
        _setTokenURI(NFTTokenIdCounter, _uri);

        emit NFTMinted(msg.sender, NFTTokenIdCounter);
    }

    /// @notice removes an NFT
    /// @param _owner Owner address
    /// @param _tokenId Token ID
    function removeNFT(address _owner, uint256 _tokenId) private NFTExists(_tokenId) {
        require(msg.sender == nfts[_tokenId].owner, "Only NFT owner can remove NFT");

        /// @dev delete offers related with the nft
        uint256[] memory _offersIds = offersIdsByNFTID[_tokenId];
        for (uint256 i = 0; i < _offersIds.length; i++) {
            uint256 _offerId = _offersIds[i];

            delete offersByNftID[_tokenId][_offerId];
            delete offersByOwnerID[msg.sender][_offerId];
            delete offers[_offerId];
            removeOfferFromNFT(_tokenId, _offerId);
            removeOfferFromOwner(msg.sender, _offerId);
        }
        
        /// @dev delete nft from mappings
        delete nfts[_tokenId];
        delete nftsByOwnerID[_owner][_tokenId];
        removeNFTFromOwner(_owner, _tokenId);
    }

    /// @notice creates an NFT offer
    /// @param _tokenId Token ID     
    function createOffer(uint256 _tokenId) external payable NFTExists(_tokenId) {
        require(msg.value > 0, "Price must be greater than zero");
        require(nfts[_tokenId].isListed, "NFT is not listed for sale");

        offersCount++;
        NFTOffer memory newOffer = NFTOffer({
            offerId: offersCount,
            tokenId: _tokenId,
            buyer: msg.sender,
            price: msg.value,
            expirationDate: block.timestamp + 1 days
        });

        /// @dev add offer to mappings
        offers[offersCount] = newOffer;
        offersByOwnerID[msg.sender][offersCount] = newOffer;
        offersByNftID[_tokenId][offersCount] = newOffer;
        offersIDsByOwnerID[msg.sender].push(offersCount);

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
        NFTOffer memory _nftOffer = offers[_offerId];
        NFT memory _nft = nfts[_nftOffer.tokenId];

        require(msg.sender == _nftOffer.buyer, "Only buyer can cancel offer");
        require(_nft.isListed, "Only listed NFT can be canceled");

        /// @dev delete offers related with the nft
        delete offersByNftID[_nft.tokenId][_offerId];
        delete offersByOwnerID[msg.sender][_nftOffer.tokenId];
        delete offers[_offerId];
        removeOfferFromOwner(msg.sender, _offerId);
        removeOfferFromNFT(_nft.tokenId, _offerId);
        
        emit NFTOfferCanceled(_offerId);
    }

    /// @notice accepts an NFT offer
    /// @param _offerId Offer ID
    function acceptOffer(uint256 _offerId) external payable NFTOfferExists(_offerId) {
        NFTOffer memory _offer = offers[_offerId];
        NFT memory _nft = nfts[_offer.tokenId];

        require(msg.sender == _offer.buyer, "Only buyer can accept offer");
        require(_offer.expirationDate > block.timestamp, "Offer has expired");

        /// @dev delete offers related with the nft
        delete offersByNftID[_offer.tokenId][_offerId];
        delete offersByOwnerID[_offer.buyer][_offer.tokenId];
        delete offers[_offerId];
        removeOfferFromOwner(_offer.buyer, _offer.offerId);

        /// @dev remove nft from the old owner
        removeNFTFromOwner(msg.sender, _offer.tokenId);

        /// @dev update nft owner with buyer
        _nft.owner = _offer.buyer;
        nfts[_offer.tokenId] = _nft;
        nftIDsByOwnerID[_offer.buyer].push(_nft.tokenId);

        /// @dev send Ether to NFT owner
        (bool success,) = payable(msg.sender).call{value: _offer.price}("");
        require(success, "Failed to send Ether to NFT owner");

        emit NFTOfferAccepted(        
            _offer.buyer,
            _offer.tokenId,
            _offerId
        );
    }

    /// @notice sets an NFT as listed for sale
    /// @param _tokenId Token ID
    function setNFTAsListed(uint256 _tokenId) external NFTExists(_tokenId) {
        NFT storage _nft = nfts[_tokenId];
        require(!_nft.isListed, "NFT is already listed");
        require(msg.sender == _nft.owner, "Only NFT owner can set as listed");
       
        _nft.isListed = true;
        nfts[_tokenId] = _nft;

        emit NFTSetAsListed(_tokenId);
    }

    /// @notice gets all NFTs
    /// @param _offset Offset
    /// @param _limit Limit
    /// @return nfts NFTs
    function getNfts(uint256 _offset, uint256 _limit) external view returns (NFT[] memory) {
        require(_offset > 0, "Offset must be greater than zero");
        require(_limit > 0, "Limit must be greater than zero");
        require(_limit > _offset, "Limit must be greater than offset");
        require(_limit <= NFTTokenIdCounter, "Limit must be less than total NFTs");

        uint256 _length = _limit - _offset + 1;
        NFT[] memory _nfts = new NFT[](_length);

        for (uint256 i = _offset; i < _length; i++) {
            _nfts[i - 1] = nfts[i];
        }

        return _nfts;
    }

    /// @notice gets an NFT by ID
    /// @param _tokenId Token ID
    /// @return nft NFT
    function getNFTById(uint256 _tokenId) external view NFTExists(_tokenId) returns (NFT memory) {
        return nfts[_tokenId];
    }

    /// @notice gets an NFT by owner
    /// @param _owner Owner address
    /// @param _tokenId Token ID
    /// @return nft NFT
    function getNFTByOwner(address _owner, uint256 _tokenId) external view returns (NFT memory) {
        return nftsByOwnerID[_owner][_tokenId];
    }

    /// @notice gets all NFTs by owner
    /// @param _owner Owner address
    /// @return items NFTs by owner
    function getAllNFTByOwner(address _owner) external view returns (NFT[] memory) {
        uint256[] memory _tokenIDs = nftIDsByOwnerID[_owner];
        uint256 _length = _tokenIDs.length;
        NFT[] memory _nfts = new NFT[](_length);

        for (uint256 i = 0; i < _length; i++) {
            _nfts[i] = nftsByOwnerID[_owner][_tokenIDs[i]];
        }

        return _nfts;
    }

    /// @notice gets all NFT offers
    /// @param _offset Offset
    /// @param _limit Limit
    /// @return offers Offers
    function getOffers(uint256 _offset, uint256 _limit) external view returns (NFTOffer[] memory) {
        require(_offset > 0, "Offset must be greater than zero");
        require(_limit > 0, "Limit must be greater than zero");
        require(_limit > _offset, "Limit must be greater than offset");
        require(_limit <= offersCount, "Limit must be less than total NFTs");

        uint256 _length = _limit - _offset + 1;
        NFTOffer[] memory _offers = new NFTOffer[](_length);

        for (uint256 i = _offset; i < _length; i++) {
            _offers[i - 1] = offers[i];
        }

        return _offers;
    }

    /// @notice gets an NFT offer by ID
    /// @param _offerId Offer ID     
    /// @return offer Offer
    function getOfferById(uint256 _offerId) external view NFTOfferExists(_offerId) returns (NFTOffer memory) {
        return offers[_offerId];
    }

    /// @notice gets an NFT offer by owner
    /// @param _owner Owner address
    /// @param _offerId Offer ID
    /// @return offer Offer
    function getOfferByOwner(address _owner, uint256 _offerId) external view returns (NFTOffer memory) {
        return offersByOwnerID[_owner][_offerId];
    }

    /// @notice gets all offers by owner
    /// @param _owner Owner address
    /// @return offers Offers
    function getAllOffersByOwnerID(address _owner) external view returns (NFTOffer[] memory) {
        uint256[] memory _offerIDs = offersIDsByOwnerID[_owner];
        uint256 _length = _offerIDs.length;
        NFTOffer[] memory _offers = new NFTOffer[](_length);

        for (uint256 i = 0; i < _length; i++) {
            _offers[i] = offersByOwnerID[_owner][_offerIDs[i]];
        }

        return _offers;
    }

    /// @notice gets all offers by NFT
    /// @param _tokenId Token ID
    /// @return offers Offers   
    function getAllOffersByNft(uint256 _tokenId) external view returns (NFTOffer[] memory) {
        uint256[] memory _offerIDs = offersIdsByNFTID[_tokenId];
        uint256 _length = _offerIDs.length;
        NFTOffer[] memory _offers = new NFTOffer[](_length);

        for (uint256 i = 0; i < _length; i++) {
            _offers[i] = offers[_offerIDs[i]];
        }

        return _offers;
    }

    /// @notice removes an NFT from owner
    /// @param _owner Owner address to remove NFT from
    /// @param _tokenId Token ID to remove
    function removeNFTFromOwner(address _owner, uint256 _tokenId) private NFTExists(_tokenId) {
        uint256[] storage _tokenIDs = nftIDsByOwnerID[_owner];
        uint256 _length = _tokenIDs.length;

        for (uint256 i = 0; i < _length; i++) {
            if (_tokenIDs[i] == _tokenId) {
                _tokenIDs[i] = _tokenIDs[_length - 1];
                _tokenIDs.pop();
                break;
            }
        }
    }

    /// @notice removes an Offer from owner
    /// @param _owner Owner address to remove Offer from
    /// @param _offerId Offer ID to remove
    function removeOfferFromOwner(address _owner, uint256 _offerId) private NFTOfferExists(_offerId) {
        uint256[] storage _offerIDs = offersIDsByOwnerID[_owner];
        uint256 _length = _offerIDs.length;

        for (uint256 i = 0; i < _length; i++) {
            if (_offerIDs[i] == _offerId) {
                _offerIDs[i] = _offerIDs[_length - 1];
                _offerIDs.pop();
                break;
            }
        }
    }

    /// @notice removes an Offer from NFT
    /// @param _tokenId Token ID to remove Offer from    
    /// @param _offerId Offer ID to remove
    function removeOfferFromNFT(uint256 _tokenId, uint256 _offerId) private NFTExists(_tokenId) {
        uint256[] storage _offerIDs = offersIdsByNFTID[_tokenId];
        uint256 _length = _offerIDs.length;

        for (uint256 i = 0; i < _length; i++) {
            if (_offerIDs[i] == _offerId) {
                _offerIDs[i] = _offerIDs[_length - 1];
                _offerIDs.pop();
                break;
            }
        }
    }
}