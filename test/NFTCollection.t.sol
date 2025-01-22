// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Test} from "forge-std/Test.sol";
import {NFTCollection} from "../contracts/NFTCollection.sol";

contract NFTCollectionTest is Test, IERC721Receiver {
    NFTCollection public nftCollection;
    address public user;

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

    // Test minting a new NFT
    function testMintNFT() external {
        string memory _uri = "test-uri";
        uint256 _price = 0.01 ether;

        nftCollection.mintNFT(_uri, _price);

        // Check if the NFT exists
        NFTCollection.NFT[] memory nftList = nftCollection.getNFTs();
        assertEq(nftList.length, 1, "NFT should be minted");
        assertEq(nftList[0].uri, _uri, "NFT URI should match");
        assertEq(nftList[0].price, _price, "NFT price should match");
        assertEq(nftList[0].creator, address(this), "Creator should be the contract deployer");
    }
}
