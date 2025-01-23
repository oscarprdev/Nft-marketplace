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

    /// @notice setNFTAsListed should set the NFT as listed
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

    /// @notice setNFTAsListed should revert if the NFT does not exist
    function testSetNFTasListed_NFTDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(NFTDoesNotExist.selector, 1));
        nftCollection.setNFTAsListed(1);
    }

    /// @notice setNFTAsListed should revert if the NFT is already listed
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

    /// @notice setNFTAsListed should revert if the caller is not the owner of the NFT
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

    /// @notice createOffer should add a offer to the offer's list
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

    /// @notice createOffer should rever if NFT does not exist
    function testCreateOffer_NFTDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(NFTDoesNotExist.selector, 1));
        nftCollection.createOffer(1);
    } 

    /// @notice createOffer should revert if NFT is not listed
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

    /// @notice createOffer should revert if NFT is not listed
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

    /// @notice createOffer should revert if owner creates offer
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

    /// @notice cancelOffer should cancel an offer
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

    /// @notice cancelOffer should revert if offer does not exist
    function testCancelOffer_OfferDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(OfferDoesNotExist.selector, 1));
        nftCollection.cancelOffer(1);
    }

    /// @notice cancelOffer should revert if sender is not the owner of the offer
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
}
