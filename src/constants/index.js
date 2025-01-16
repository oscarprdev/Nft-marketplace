import NFTMarketplace from '../../contracts/NFTMarketplace.json';

export const NFTMarketplaceAddress = process.env.ADDRESS || '';
export const NFTMarketplaceABI = NFTMarketplace.abi;
