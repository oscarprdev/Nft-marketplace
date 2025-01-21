export interface NFTItem extends ContractNFTItem {
  metadatata: NFTMetadata;
}

export type NFTMetadata = {
  name: string;
  description: string;
  image: string;
};

export type ContractNFTItem = {
  tokenId: number;
  creator: string;
  owner: string;
  uri: string;
  price: string;
  isListed: string;
  timestamp: string;
};

// NFT from Smart Contract
export type ContractNFT = {
  0: string; // Unique token ID
  1: string; // Creator of the NFT
  2: string; // Current owner of the NFT
  3: string; // Metadata URI
  4: string; // Price if listed for sale
  5: string; // Is it listed for sale
  6: string; // Minting timestamp
};

export type CreateNFTInput = {
  metadataUrl: string;
  price: string;
};
