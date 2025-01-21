import { ethers } from 'ethers';
import { NFTMarketplaceABI, NFTMarketplaceAddress } from '~/constants';

export const getContract = () => {
  const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8545');
  return new ethers.Contract(NFTMarketplaceAddress, NFTMarketplaceABI, provider);
};
