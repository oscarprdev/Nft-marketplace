# NFTCollection
[Git Source](https://github.com/oscarprdev/nft-marketplace/blob/606dfa796897367cccb8d11dbd89cc3093f0cf87/contracts/NFTMarketplace.sol)

**Inherits:**
ERC721URIStorage

**Author:**
@Oscarprdev

*A simple NFT collection contract*


## State Variables
### NFTCount
nft counter


```solidity
uint256 public NFTCount;
```


### offersCount
nft offers counter


```solidity
uint256 public offersCount;
```


### owner
owner address


```solidity
address immutable owner;
```


### nftList
nft list


```solidity
NFT[] public nftList;
```


### offersList
nft offers list


```solidity
NFTOffer[] public offersList;
```


## Functions
### onlyOwner

modifier to check if the caller is the owner


```solidity
modifier onlyOwner();
```

### constructor

constructor

*sets the owner address*


```solidity
constructor() ERC721("NFT Collection", "NFTC");
```

### mintNFT

mints a new NFT

*mints a new NFT with the given URI and price*


```solidity
function mintNFT(string memory _uri, uint256 _price) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_uri`|`string`|URI of the NFT|
|`_price`|`uint256`|Price of the NFT|


### createOffer

creates an offer for a NFT

*creates an offer for a NFT with the given token ID and expiration date*


```solidity
function createOffer(uint256 _tokenId, uint256 _expirationDate) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|Token ID|
|`_expirationDate`|`uint256`|Expiration date|


### finalizeAuction

check if the offer is higher than the current highest offer

finalizes an auction for a NFT

*finalizes an auction for a NFT with the given token ID*


```solidity
function finalizeAuction(uint256 _tokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|Token ID|


### getNFTs

find the highest offer by token id and expiration date

transfer the NFT to the highest bidder

update NFT offers array deleting all the offers for the NFT already sold

returns all NFTs

*returns all NFTs*


```solidity
function getNFTs() external view returns (NFT[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`NFT[]`|nftList NFT list|


### getNFTsByOwner

returns all NFTs by owner

*returns all NFTs by owner*


```solidity
function getNFTsByOwner(address _address) external view returns (NFT[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_address`|`address`|Owner address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`NFT[]`|nftsByOwner NFT list by owner|


### getNFTByTokenId

returns an NFT by token ID

*returns an NFT by token ID*


```solidity
function getNFTByTokenId(uint256 _tokenId) external view returns (NFT memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|Token ID|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`NFT`|nft NFT|


### getOffersByTokenId

returns all offers by token ID

*returns all offers by token ID*


```solidity
function getOffersByTokenId(uint256 _tokenId) external view returns (NFTOffer[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|Token ID|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`NFTOffer[]`|offersByTokenId Offers list by token ID|


### deleteOffersForNFT

deletes all offers for a NFT

*deletes all offers for a NFT with the given token ID*


```solidity
function deleteOffersForNFT(uint256 _tokenId) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|Token ID|


## Events
### NFTMinted
event emitted when a new NFT is minted


```solidity
event NFTMinted(address indexed owner, uint256 indexed tokenId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|Owner address|
|`tokenId`|`uint256`|Token ID|

### NFTSelled
event emitted when an NFT is sold


```solidity
event NFTSelled(address indexed from, address indexed to, uint256 price);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Seller address|
|`to`|`address`|Buyer address|
|`price`|`uint256`|Price|

## Structs
### NFT
NFT struct


```solidity
struct NFT {
    uint256 tokenId;
    address creator;
    address owner;
    string uri;
    uint256 price;
    bool isListed;
    uint256 timestamp;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|Unique token ID|
|`creator`|`address`|Creator of the NFT|
|`owner`|`address`|Current owner of the NFT|
|`uri`|`string`|Metadata URI|
|`price`|`uint256`|Price if listed for sale|
|`isListed`|`bool`|Is it listed for sale|
|`timestamp`|`uint256`|Minting timestamp|

### NFTOffer
NFT Offer struct


```solidity
struct NFTOffer {
    uint256 offerId;
    uint256 tokenId;
    address buyer;
    uint256 price;
    uint256 expirationDate;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`offerId`|`uint256`|Offer ID|
|`tokenId`|`uint256`|Token ID|
|`buyer`|`address`|Buyer address|
|`price`|`uint256`|Price|
|`expirationDate`|`uint256`|Expiration date|

