pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
    uint256 public currentId;
    address owner;

    address[] private NFTOwners;

    struct NFT {
        uint256 id;
        address owner;
        string tokenURI;
        uint price;
    }

    mapping(address => NFT[]) private nfts;

    event NFTMinted(address indexed owner, string indexed tokenURI);
    event NFTSelled(address indexed from, address indexed to, uint price);

    constructor() ERC721("NFT Marketplace", "NFTM") {
        owner = msg.sender;
    }

    function mintNFT(string memory _tokenURI, uint _price) external {
         currentId++;
         NFT memory newNFT = NFT({
            id: currentId,
            owner: msg.sender,
            tokenURI: _tokenURI,
            price: _price
        });

        if (!isNFTOwner(msg.sender)) {
            NFTOwners.push(msg.sender);
        }

        nfts[msg.sender].push(newNFT);

        _safeMint(msg.sender, currentId);
        _setTokenURI(currentId, _tokenURI);

        emit NFTMinted(msg.sender, _tokenURI);
    }

    function sellNFT(uint256 _id, address _to) external payable {
        bool isOwner = isNFTOwner(msg.sender);
        require(isOwner, "Only owner can sell NFT");

        bool found = false;
        uint index;

        for (uint i = 0; i < nfts[msg.sender].length; i++) {
            if (nfts[msg.sender][i].id == _id) {
                found = true;
                index = i; 
                break;
            }
        }

        require(found, "NFT not found in sender's collection");

        NFT storage nftToSell = nfts[msg.sender][index];
        require(nftToSell.price == msg.value, "Price must match the sent value");

        (bool success, ) = payable(msg.sender).call{value: msg.value}("");
        require(success, "Payment transfer failed");

        nftToSell.owner = _to;

        emit NFTSelled(msg.sender, _to, msg.value);
    }

    function listNFTs() external view returns (NFT[] memory) {
        uint totalNFTs;

        for (uint i = 0; i < NFTOwners.length; i++) {
            totalNFTs += nfts[NFTOwners[i]].length;
        }

        NFT[] memory allNFTs = new NFT[](totalNFTs);
        uint currentIndex = 0;

        for (uint i = 0; i < NFTOwners.length; i++) {
            for (uint j = 0; j < nfts[NFTOwners[i]].length; j++) {
                allNFTs[currentIndex] = nfts[NFTOwners[i]][j];
                currentIndex++;
            }
        }

        return allNFTs;
    }

    function listOwnedNFTs() external view returns (NFT[] memory) {
        return nfts[msg.sender];
    }

    function isNFTOwner(address _owner) private view returns (bool) {
        for (uint i = 0; i < NFTOwners.length; i++) {
            if (NFTOwners[i] == _owner) {
                return true;
            }
        }
        return false;
    }
}