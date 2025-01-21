import { ethers } from 'ethers';
import Web3Modal from 'web3modal';
import { NFTMarketplaceABI, NFTMarketplaceAddress } from '~/constants';

export const connectWithSmartContract = async () => {
  const web3Modal = new Web3Modal({ cacheProvider: true });
  const connection = await web3Modal.connect();
  const provider = new ethers.BrowserProvider(connection);
  const signer = await provider.getSigner();

  return new ethers.Contract(NFTMarketplaceAddress, NFTMarketplaceABI, signer);
};
