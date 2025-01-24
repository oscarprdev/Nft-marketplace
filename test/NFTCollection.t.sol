// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Test} from "forge-std/Test.sol";
import {NFTCollection} from "../contracts/NFTCollection.sol";

contract NFTCollectionTest is Test, IERC721Receiver {
    NFTCollection public nftCollection;
    address public user;

    event NFTMinted(address indexed owner, uint256 indexed tokenId);
    event NFTRemoved(address indexed owner, uint256 indexed tokenId);
    event NFTSelled(address indexed from, address indexed to, uint price);
    event NFTOfferCreated(address indexed from, uint256 indexed tokenId, uint256 indexed offerId, uint256 price);
    event NFTOfferAccepted(address indexed from, uint256 indexed tokenId, uint256 indexed offerId);
    event NFTOfferCanceled(uint256 indexed offerId);
    event NFTSetAsListed(uint256 indexed tokenId);

    error NFTDoesNotExist(uint256 tokenId);
    error OfferDoesNotExist(uint256 offerId);
    error UserDoesNotExist(address user);

    function setUp() public {
        nftCollection = new NFTCollection();
        user = address(0x123);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @dev mintNFT should add a new NFT to the collection
    function testMintNFT() external {
        string memory _uri = "test-uri";
        uint256 _price = 0.01 ether;

        vm.expectEmit(true, true, false, false);
        emit NFTMinted(address(this), 1);
        nftCollection.mintNFT(_uri, _price);

        /// @dev check if the NFT was added to the collection
        NFTCollection.NFT memory _nft = nftCollection.getNFTById(1);
        assertEq(_nft.tokenId, 1);
        assertEq(_nft.price, _price);
        assertEq(_nft.uri, _uri);
        assertEq(_nft.owner, address(this));
        assertEq(_nft.creator, address(this));
        assertEq(_nft.isListed, false);
        assertEq(_nft.timestamp, block.timestamp);
        assertEq(nftCollection.NFTTokenIdCounter(), 1);
    }

    /// @dev mintNFT should revert if the URI is empty
    function testMintNFT_EmptyUri() external {
        vm.expectRevert("URI cannot be empty");
        nftCollection.mintNFT("", 0.01 ether);
    }

    /// @dev mintNFT should revert if the price is zero
    function testMintNFT_ZeroPrice() external {
        vm.expectRevert("Price must be greater than zero");
        nftCollection.mintNFT("test-uri", 0);
    }

    /// @dev removeNFT should remove the NFT from the collection
    function testRemoveNFT() external {
        string memory _uri = "test-uri";
        uint256 _price = 0.01 ether;

        nftCollection.mintNFT(_uri, _price);

        /// @dev check if the NFT was added to the collection
        NFTCollection.NFT memory _nft = nftCollection.getNFTById(1);
        assertEq(_nft.tokenId, 1);
        
        /// @dev remove the NFT from the owner
        vm.expectEmit(true, true, false, false);
        emit NFTRemoved(address(this), 1);
        nftCollection.removeNFT(address(this), 1);
    }

    /// @dev removeNFT should revert if the NFT does not exist
    function testRemoveNFT_notExists() external {
        vm.expectRevert(abi.encodeWithSelector(NFTDoesNotExist.selector, 1));
        nftCollection.removeNFT(address(this), 1);
    }

    /// @dev removeNFT should revert if the NFT is not owned by the owner
    function testRemoveNFT_notValidOwner() external {
        string memory _uri = "test-uri";
        uint256 _price = 0.01 ether;

        nftCollection.mintNFT(_uri, _price);

        /// @dev check if the NFT was added to the collection
        NFTCollection.NFT memory _nft = nftCollection.getNFTById(1);
        assertEq(_nft.tokenId, 1);

        /// @dev remove the NFT from the owner
        vm.prank(address(0x123));
        vm.expectRevert("Only NFT owner can remove NFT");
        nftCollection.removeNFT(address(this), 1);
    }

    /// @dev setNFTAsListed should set the NFT as listed
    function testSetNFTasListed() external {
        string memory _uri = "test-uri";
        uint256 _price = 0.01 ether;

        nftCollection.mintNFT(_uri, _price);

        /// @dev check if the NFT was added to the collection
        NFTCollection.NFT memory _nft = nftCollection.getNFTById(1);
        assertEq(_nft.tokenId, 1);
        assertEq(_nft.isListed, false);

        vm.expectEmit(true, false, false, false);
        emit NFTSetAsListed(1);
        nftCollection.setNFTAsListed(1);
      
        NFTCollection.NFT memory nft = nftCollection.getNFTById(1);
        assertEq(nft.tokenId, 1);
        assertEq(nft.isListed, true);
    }

    /// @dev setNFTAsListed should revert if the NFT does not exist
    function testSetNFTasListed_NFTDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(NFTDoesNotExist.selector, 1));
        nftCollection.setNFTAsListed(1);
    }

    /// @dev setNFTAsListed should revert if the NFT is already listed
    function testSetNFTasListed_NFTAlreadyListed() external {
        string memory _uri = "test-uri";
        uint256 _price = 0.01 ether;

        nftCollection.mintNFT(_uri, _price);

        /// @dev check if the NFT was added to the collection
        NFTCollection.NFT memory _nft = nftCollection.getNFTById(1);
        assertEq(_nft.tokenId, 1);
        assertEq(_nft.isListed, false);

        nftCollection.setNFTAsListed(1);
      
        NFTCollection.NFT memory nft = nftCollection.getNFTById(1);
        assertEq(nft.tokenId, 1);
        assertEq(nft.isListed, true);

        vm.expectRevert("NFT is already listed");
        nftCollection.setNFTAsListed(1);
    }

    /// @dev setNFTAsListed should revert if the caller is not the owner of the NFT
    function testSetNFTasListed_NotOwner() external {
        string memory _uri = "test-uri";
        uint256 _price = 0.01 ether;

        nftCollection.mintNFT(_uri, _price);

        /// @dev check if the NFT was added to the collection
        NFTCollection.NFT memory _nft = nftCollection.getNFTById(1);
        assertEq(_nft.tokenId, 1);
        assertEq(_nft.isListed, false);

        vm.prank(address(0xBEEF));
        vm.expectRevert("Only NFT owner can set as listed");
        nftCollection.setNFTAsListed(1);
    }

    /// @dev createOffer should add a offer to the offer's list
    function testCreateOffer() external {
        string memory _uri = "test-uri";
        uint256 _price = 0.01 ether;

        /// @dev create NFT first
        nftCollection.mintNFT(_uri, _price);

         uint256 _tokenId = 1;

        /// @dev set as listed before creating offer
        nftCollection.setNFTAsListed(_tokenId);

        /// @dev check if the NFT was added to the collection
        NFTCollection.NFT memory _nft = nftCollection.getNFTById(_tokenId);
        assertEq(_nft.tokenId, _tokenId);
        assertEq(_nft.isListed, true);

        vm.prank(address(0xBEEF));
        vm.deal(address(0xBEEF), 5 ether);
        vm.expectEmit(true, true, true, false);
        emit NFTOfferCreated(address(0xBEEF), _tokenId, 1, 2 ether);
        nftCollection.createOffer{ value: 2 ether }(_tokenId);

        /// @dev check if offer does exist
        NFTCollection.NFTOffer memory _offer = nftCollection.getOfferById(1);
        assertEq(_offer.tokenId, _tokenId);
        assertEq(_offer.buyer, address(0xBEEF));
    }

    /// @dev createOffer should rever if NFT does not exist
    function testCreateOffer_NFTDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(NFTDoesNotExist.selector, 1));
        nftCollection.createOffer(1);
    } 

    /// @dev createOffer should revert if NFT is not listed
    function testCreateOffer_PriceIsLow() external {
        string memory _uri = "test-uri";
        uint256 _price = 2 ether;
        uint256 _tokenId = 1;

        nftCollection.mintNFT(_uri, _price);
        nftCollection.setNFTAsListed(_tokenId);

        vm.prank(address(0xBEEF));
        vm.deal(address(0xBEEF), 5 ether);
        vm.expectRevert("Offer must be greater than NFT price");
        nftCollection.createOffer{ value: 1 ether }(_tokenId);
    }

    /// @dev createOffer should revert if NFT is not listed
    function testCreateOffer_NFTNotListed() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;
        uint256 _tokenId = 1;

        nftCollection.mintNFT(_uri, _price);
        vm.prank(address(0xBEEF));
        vm.deal(address(0xBEEF), 5 ether);
        vm.expectRevert("NFT is not listed for sale");
        nftCollection.createOffer{ value: 2 ether }(_tokenId);
    }

    /// @dev createOffer should revert if owner creates offer
    function testCreateOffer_OwnerCannotCreateOffer() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;
        uint256 _tokenId = 1;

        nftCollection.mintNFT(_uri, _price);
        nftCollection.setNFTAsListed(_tokenId);

        vm.deal(address(this), 5 ether);
        vm.expectRevert("Owner of NFT cannot create an offer");
        nftCollection.createOffer{ value: 2 ether }(_tokenId);
    }

    /// @dev cancelOffer should cancel an offer
    function testCancelOffer() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;
        uint256 _tokenId = 1;

        nftCollection.mintNFT(_uri, _price);
        nftCollection.setNFTAsListed(_tokenId);

        vm.prank(address(0xBEEF));
        vm.deal(address(0xBEEF), 5 ether);
        vm.expectEmit(true, true, true, false);
        emit NFTOfferCreated(address(0xBEEF), _tokenId, 1, 2 ether);
        nftCollection.createOffer{ value: 2 ether }(_tokenId);

        NFTCollection.NFTOffer memory _offer = nftCollection.getOfferById(1);
        assertEq(_offer.tokenId, _tokenId);
        assertEq(_offer.buyer, address(0xBEEF));

        vm.prank(address(0xBEEF));
        vm.expectEmit(true, false, false, false);
        emit NFTOfferCanceled(1);
        nftCollection.cancelOffer(1);
    }

    /// @dev cancelOffer should revert if offer does not exist
    function testCancelOffer_OfferDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(OfferDoesNotExist.selector, 1));
        nftCollection.cancelOffer(1);
    }

    /// @dev cancelOffer should revert if sender is not the owner of the offer
    function testCancelOffer_SenderIsNotOwner() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;
        uint256 _tokenId = 1;

        nftCollection.mintNFT(_uri, _price);
        nftCollection.setNFTAsListed(_tokenId);

        vm.prank(address(0xBEEF));
        vm.deal(address(0xBEEF), 5 ether);
        emit NFTOfferCreated(address(0xBEEF), _tokenId, 1, 2 ether);
        nftCollection.createOffer{ value: 2 ether }(_tokenId);

        vm.expectRevert("Only buyer can cancel offer");
        nftCollection.cancelOffer(1);
    }

    /// @dev acceptOffer should accept an offer
    function testAcceptOffer() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;
        uint256 _tokenId = 1;

        nftCollection.mintNFT(_uri, _price);
        nftCollection.setNFTAsListed(_tokenId);

        vm.prank(address(0xBEEF));
        vm.deal(address(0xBEEF), 5 ether);
        vm.expectEmit(true, true, true, false);
        emit NFTOfferCreated(address(0xBEEF), _tokenId, 1, 2 ether);
        nftCollection.createOffer{ value: 2 ether }(_tokenId);

        NFTCollection.NFTOffer memory _offer = nftCollection.getOfferById(1);
        assertEq(_offer.tokenId, _tokenId);
        assertEq(_offer.buyer, address(0xBEEF));

        vm.prank(address(0xBEEF));
        vm.expectEmit(true, false, false, false);
        emit NFTOfferAccepted(_offer.buyer, _offer.tokenId, _offer.offerId);
        nftCollection.acceptOffer(1);
    }

    /// @dev acceptOffer should revert if offer does not exist
    function testAcceptOffer_OfferDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(OfferDoesNotExist.selector, 1));
        nftCollection.acceptOffer(1);
    }

    /// @dev acceptOffer should revert if sender is not the owner of the offer
    function testAcceptOffer_SenderIsNotOwner() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;
        uint256 _tokenId = 1;

        nftCollection.mintNFT(_uri, _price);
        nftCollection.setNFTAsListed(_tokenId);

        vm.prank(address(0xBEEF));
        vm.deal(address(0xBEEF), 5 ether);
        emit NFTOfferCreated(address(0xBEEF), _tokenId, 1, 2 ether);
        nftCollection.createOffer{ value: 2 ether }(_tokenId);

        vm.expectRevert("Only buyer can accept offer");
        nftCollection.acceptOffer(1);
    }

    /// @dev acceptOffer should revert if offer has expired
    function testAcceptOffer_OfferHasExpired() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;
        uint256 _tokenId = 1;

        nftCollection.mintNFT(_uri, _price);
        nftCollection.setNFTAsListed(_tokenId);

        vm.prank(address(0xBEEF));
        vm.deal(address(0xBEEF), 5 ether);
        emit NFTOfferCreated(address(0xBEEF), _tokenId, 1, 2 ether);
        nftCollection.createOffer{ value: 2 ether }(_tokenId);

        vm.warp(block.timestamp + 1 days);
        vm.expectRevert("Offer has expired");
        vm.prank(address(0xBEEF));
        nftCollection.acceptOffer(1);
    }

    /// @dev getNFTs should return the NFTs by offets and limit
    function testGetNFTs() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;

        for (uint256 i = 0; i < 5; i++) {
            nftCollection.mintNFT(_uri, _price);
        }
        
        uint256 _offset = 2;
        uint256 _limit = 4;

        NFTCollection.NFT[] memory _nfts = nftCollection.getNFTs(_offset, _limit);
        assertEq(_nfts.length, 3);
        assertEq(_nfts[0].tokenId, 2);
        assertEq(_nfts[1].tokenId, 3);
        assertEq(_nfts[2].tokenId, 4);
    }

    /// @dev getNFTs should revert if limit is not greater than offset
    function testGetNFTs_LimitNotValid() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;

        for (uint256 i = 0; i < 5; i++) {
            nftCollection.mintNFT(_uri, _price);
        }

        uint256 _offset = 2;
        uint256 _limit = 1;

        vm.expectRevert("Limit must be greater than offset");
        nftCollection.getNFTs(_offset - 1, _limit);
    }

    /// @dev getNFTs should revert if limit is greater than NFTs
    function testGetNFTs_LimitNotMatchWithNFTs() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;
        uint256 _maxLimit = 2;

        for (uint256 i = 0; i < _maxLimit; i++) {
            nftCollection.mintNFT(_uri, _price);
        }

        uint256 _offset = 2;
        uint256 _limit = _maxLimit + 1;

        vm.expectRevert("Limit must be less than total NFTs");
        nftCollection.getNFTs(_offset - 1, _limit);
    }

    /// @dev getNFTById should return the NFT by id
    function getNFTById() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;
        nftCollection.mintNFT(_uri, _price);

        NFTCollection.NFT memory _nft = nftCollection.getNFTById(1);
        assertEq(_nft.tokenId, 1);
    }
    
    /// @dev getNFTById should revert if NFT does not exist
    function testGetNFTById_NFTDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(NFTDoesNotExist.selector, 1));
        nftCollection.getNFTById(1);
    }

    /// @dev getNFTByOwner should return the NFT by owner
    function getNFTByOwner() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;
        nftCollection.mintNFT(_uri, _price);

        NFTCollection.NFT memory _nft = nftCollection.getNFTByOwner(address(this), 1);
        assertEq(_nft.tokenId, 1);
    }
    
    /// @dev getNFTByOwner should revert if NFT does not exist
    function testGetNFTByOwner_NFTDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(NFTDoesNotExist.selector, 1));
        nftCollection.getNFTByOwner(address(this), 1);
    }

    /// @dev getAllNFTByOwner should return the NFTs by owner
    function testGetAllNFTByOwner() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;

        for (uint256 i = 0; i < 3; i++) {
            nftCollection.mintNFT(_uri, _price);
        }

        NFTCollection.NFT[] memory _nfts = nftCollection.getAllNFTByOwner(address(this));
        assertEq(_nfts.length, 3);
        assertEq(_nfts[0].tokenId, 1);
        assertEq(_nfts[1].tokenId, 2);
        assertEq(_nfts[2].tokenId, 3);
    }

    /// @dev getOffers should return offers by offset and limit
    function testGetOffers() external {
        string memory _uri = "test-uri";
        uint256 _price = 0.5 ether;

        for (uint256 i = 0; i < 4; i++) {
            nftCollection.mintNFT(_uri, _price);
        }

        for (uint256 i = 0; i < 4; i++) {
            nftCollection.setNFTAsListed(i + 1);
        }

        for (uint256 i = 0; i < 4; i++) {
            vm.prank(address(0xBEEF));
            vm.deal(address(0xBEEF), 5 ether);
            nftCollection.createOffer{ value: 1 ether }(i + 1);
        }

        uint256 _offset = 2;
        uint256 _limit = 4;

        NFTCollection.NFTOffer[] memory _offers = nftCollection.getOffers(_offset, _limit);
        assertEq(_offers.length, 3);
        assertEq(_offers[0].tokenId, 2);
        assertEq(_offers[1].tokenId, 3);
        assertEq(_offers[2].tokenId, 4);
    }

    /// @dev getOffers should revert if limit is not greater than offset
    function testGetOffers_LimitNotValid() external {
        string memory _uri = "test-uri";
        uint256 _price = 0.5 ether;

        for (uint256 i = 0; i < 4; i++) {
            nftCollection.mintNFT(_uri, _price);
        }

        for (uint256 i = 0; i < 4; i++) {
            nftCollection.setNFTAsListed(i + 1);
        }

        for (uint256 i = 0; i < 4; i++) {
            vm.prank(address(0xBEEF));
            vm.deal(address(0xBEEF), 5 ether);
            nftCollection.createOffer{ value: 1 ether }(i + 1);
        }

        uint256 _offset = 2;
        uint256 _limit = 1;

        vm.expectRevert("Limit must be greater than offset");
        nftCollection.getOffers(_offset - 1, _limit);
    }

    /// @dev getOffers should revert if limit is greater than NFTs
    function testGetOffers_LimitNotMatchWithNFTs() external {
        string memory _uri = "test-uri";
        uint256 _price = 0.5 ether;

        for (uint256 i = 0; i < 4; i++) {
            nftCollection.mintNFT(_uri, _price);
        }

        for (uint256 i = 0; i < 4; i++) {
            nftCollection.setNFTAsListed(i + 1);
        }

        for (uint256 i = 0; i < 4; i++) {
            vm.prank(address(0xBEEF));
            vm.deal(address(0xBEEF), 5 ether);
            nftCollection.createOffer{ value: 1 ether }(i + 1);
        }

        uint256 _offset = 2;
        uint256 _limit = 4 + 1;

        vm.expectRevert("Limit must be less than total NFTs");
        nftCollection.getOffers(_offset - 1, _limit);
    }

    /// @dev getOfferById should return the offer by id
    function testGetofferById() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;
        nftCollection.mintNFT(_uri, _price);
        nftCollection.setNFTAsListed(1);

        vm.prank(address(0xBEEF));
        vm.deal(address(0xBEEF), 5 ether);
        nftCollection.createOffer{ value: 2 ether }(1);

        NFTCollection.NFTOffer memory _offer = nftCollection.getOfferById(1);
        assertEq(_offer.offerId, 1);
    }

    /// @dev getOfferById should revert if Offer does not exist
    function testGetOfferById_OfferDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(OfferDoesNotExist.selector, 1));
        nftCollection.getOfferById(1);
    }

    /// @dev getOfferByOwner should return the Offer by owner
    function getOfferByOwner() external {
        string memory _uri = "test-uri";
        uint256 _price = 1 ether;
        nftCollection.mintNFT(_uri, _price);
        nftCollection.setNFTAsListed(1);

        vm.prank(address(0xBEEF));
        vm.deal(address(0xBEEF), 5 ether);
        nftCollection.createOffer{ value: 2 ether }(1);

        vm.prank(address(0xBEEF));
        NFTCollection.NFTOffer memory _offer = nftCollection.getOfferByOwner(address(this), 1);
        assertEq(_offer.offerId, 1);
    }
    
    /// @dev getOfferByOwner should revert if Offer does not exist
    function testGetOfferByOwner_OfferDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(OfferDoesNotExist.selector, 1));
        nftCollection.getOfferByOwner(address(this), 1);
    }

    /// @dev getAllOffersByOwner should return the Offers by owner
    function testGetAllOffersByOwner() external {
        string memory _uri = "test-uri";
        uint256 _price = 0.5 ether;

        for (uint256 i = 0; i < 3; i++) {
            nftCollection.mintNFT(_uri, _price);
        }

        for (uint256 i = 0; i < 3; i++) {
            nftCollection.setNFTAsListed(i + 1);
        }

        for (uint256 i = 0; i < 3; i++) {
            vm.prank(address(0xBEEF));
            vm.deal(address(0xBEEF), 6 ether);
            nftCollection.createOffer{ value: 0.7 ether }(i + 1);
        }

        NFTCollection.NFTOffer[] memory _offers = nftCollection.getAllOffersByOwnerID(address(0xBEEF));
        assertEq(_offers.length, 3);
        assertEq(_offers[0].tokenId, 1);
        assertEq(_offers[1].tokenId, 2);
        assertEq(_offers[2].tokenId, 3);
    }

    /// @dev getAllOffersByNft should return the Offers by NFT
    function testGetAllOffersByNft() external {
        string memory _uri = "test-uri";
        uint256 _price = 0.5 ether;

        nftCollection.mintNFT(_uri, _price);
        nftCollection.setNFTAsListed(1);

        vm.prank(address(0xBEEF));
        vm.deal(address(0xBEEF), 6 ether);
        nftCollection.createOffer{ value: 0.7 ether }(1);
        vm.stopPrank();

        vm.prank(address(0xBAAF));
        vm.deal(address(0xBAAF), 6 ether);
        nftCollection.createOffer{ value: 1 ether }(1);
        vm.stopPrank();

        vm.prank(address(0xBFFF));
        vm.deal(address(0xBFFF), 6 ether);
        nftCollection.createOffer{ value: 1.7 ether }(1);
        vm.stopPrank();

        NFTCollection.NFTOffer[] memory _offers = nftCollection.getAllOffersByNft(1);
        assertEq(_offers.length, 3);
        assertEq(_offers[0].tokenId, 1);
        assertEq(_offers[0].price, 0.7 ether);
        assertEq(_offers[0].buyer, address(0xBEEF));

        assertEq(_offers[1].tokenId, 1);
        assertEq(_offers[1].price, 1 ether);
        assertEq(_offers[1].buyer, address(0xBAAF));

        assertEq(_offers[2].tokenId, 1);
        assertEq(_offers[2].price, 1.7 ether);
        assertEq(_offers[2].buyer, address(0xBFFF));
    }

    function testGetAllOffersByNft_NFTDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(NFTDoesNotExist.selector, 1));
        nftCollection.getAllOffersByNft(1);
    }
}
