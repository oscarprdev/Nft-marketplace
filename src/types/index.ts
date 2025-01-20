export type NFTItem = {
  tokenId: number;
  tokenURI: string;
  seller: string;
  owner: string;
  image: string;
  name: string;
  description: string;
  price: number;
};

export type ContractNFT = {
  0: string; // id
  1: string; // owner
  2: string; // metadat-URL
  3: string; // price
};

export type CreateNFTInput = {
  metadataUrl: string;
  price: string;
};
