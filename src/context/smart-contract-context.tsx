'use client';

import { NFTMarketplaceABI, NFTMarketplaceAddress } from '../constants';
import { json } from '@helia/json';
import { unixfs } from '@helia/unixfs';
import { ethers } from 'ethers';
import { createHelia } from 'helia';
import { CID } from 'multiformats/cid';
import React, { createContext, useState } from 'react';
import Web3Modal from 'web3modal';

const fetchContract = (signerOrProvider: ethers.JsonRpcSigner) =>
  new ethers.Contract(NFTMarketplaceAddress, NFTMarketplaceABI, signerOrProvider);

const connectingWithSmartContract = async () => {
  const web3Modal = new Web3Modal({ cacheProvider: true });
  const connection = await web3Modal.connect();
  const provider = new ethers.BrowserProvider(connection);
  const signer = await provider.getSigner();

  return fetchContract(signer);
};

export const SmartContractContext = createContext<{
  connectToWallet: () => Promise<void>;
  checkIfWalletIsConnected: () => Promise<void>;
  getImageFromIPFS: (cid: string) => Promise<void>;
  uploadNFTtoIPFS: (imageFile: File, name: string, description: string) => Promise<string>;
  currentAccount: string | null;
}>({
  connectToWallet: async () => {},
  checkIfWalletIsConnected: async () => {},
  getImageFromIPFS: async () => {},
  uploadNFTtoIPFS: async () => '',
  currentAccount: null,
});

export const SmartContractProvider = ({ children }: { children: React.ReactNode }) => {
  const [currentAccount, setCurrentAccount] = useState<string | null>(null);

  const checkIfWalletIsConnected = async () => {
    try {
      if (!window.ethereum) return console.log('No metamask connected');

      const accounts = await window.ethereum.request({ method: 'eth_accounts' });

      if (accounts.length) {
        setCurrentAccount(accounts[0]);
      } else {
        console.log('No accounts found');
      }
    } catch (error) {
      console.log(`Something went wrong ${error}`);
    }
  };

  const connectToWallet = async () => {
    try {
      if (!window.ethereum) return console.log('No metamask connected');

      const accounts = await window.ethereum.request({ method: 'eth_requestAccount' });

      setCurrentAccount(accounts[0]);
    } catch (error) {
      console.log(`Something went wrong connecting to wallet ${error}`);
    }
  };

  const uploadNFTtoIPFS = async (imageFile: File, name: string, description: string) => {
    try {
      const helia = await createHelia();
      const fs = unixfs(helia);
      const j = json(helia);

      // Upload the image to IPFS
      const imageBuffer = await imageFile.arrayBuffer();
      const imageCID = await fs.addBytes(new Uint8Array(imageBuffer));

      const metadata = {
        name,
        description,
        image: `ipfs://${imageCID.toString()}`,
      };
      // const metadataBuffer = new TextEncoder().encode(JSON.stringify(metadata));
      const metadataCID = await j.add(metadata);

      const response = await j.get(metadataCID);

      const imageCID2 = response.image.replace('ipfs://', '');
      const imageCid = CID.parse(imageCID2);

      const imageUrl = `https://ipfs.io/ipfs/${imageCid.toString()}`;

      console.log('Image URL:', imageUrl);
      return metadataCID.toString();
    } catch (error) {
      console.log(`Something went wrong uploading NFT to IPFS ${error}`);
    }
  };

  const getImageFromIPFS = async (cid: string) => {
    const helia = await createHelia();
    const j = json(helia);

    // const metadataCid = CID.parse(cid);
    const metadataBuffer = await j.get(cid);

    console.log(metadataBuffer);

    // const metadata = JSON.parse(new TextDecoder().decode(metadataBuffer));
    // console.log(metadata);
    // const imageCID = metadata.image.replace('ipfs://', '');
    // const imageCid = CID.parse(imageCID);

    // const imageUrl = `https://ipfs.io/ipfs/${imageCid.toString()}`;

    // console.log('Image URL:', imageUrl);
  };

  return (
    <SmartContractContext.Provider
      value={{
        checkIfWalletIsConnected,
        getImageFromIPFS,
        connectToWallet,
        uploadNFTtoIPFS,
        currentAccount,
      }}>
      {children}
    </SmartContractContext.Provider>
  );
};
