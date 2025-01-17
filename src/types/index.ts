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

export type NFTToken = {
  tokenId: string;
  seller: string;
  owner: string;
  price: string;
};

export type CreateNFTInput = {
  username: string;
  description: string;
  price: string;
  fileUrl: string;
};
