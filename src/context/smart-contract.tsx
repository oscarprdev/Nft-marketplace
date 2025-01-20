'use client';

import { NFTMarketplaceABI, NFTMarketplaceAddress } from '../constants';
import { ethers } from 'ethers';
import React, { createContext, useState } from 'react';
import Web3Modal from 'web3modal';
import { ContractNFT, CreateNFTInput } from '~/types';

type SmartContractContextType = {
  connectToWallet: () => Promise<void>;
  checkIfWalletIsConnected: () => Promise<void>;
  createNFT: (input: CreateNFTInput) => Promise<void>;
  fetchNFTs: () => Promise<void>;
  currentAccount: string | null;
} | null;

const fetchContract = (signerOrProvider: ethers.JsonRpcSigner | ethers.JsonRpcProvider) =>
  new ethers.Contract(NFTMarketplaceAddress, NFTMarketplaceABI, signerOrProvider);

const connectingWithSmartContract = async () => {
  const web3Modal = new Web3Modal({ cacheProvider: true });
  const connection = await web3Modal.connect();
  const provider = new ethers.BrowserProvider(connection);
  const signer = await provider.getSigner();

  return fetchContract(signer);
};

export const SmartContractContext = createContext<SmartContractContextType>(null);

export const SmartContractProvider = ({ children }: { children: React.ReactNode }) => {
  const [currentAccount, setCurrentAccount] = useState<string | null>(null);

  const checkIfWalletIsConnected = async (): Promise<void> => {
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

  const connectToWallet = async (): Promise<void> => {
    try {
      if (!window.ethereum) return console.log('No metamask connected');

      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });

      setCurrentAccount(accounts[0]);
    } catch (error) {
      console.log(`Something went wrong connecting to wallet ${error}`);
    }
  };

  const createNFT = async ({ metadataUrl, price }: CreateNFTInput): Promise<void> => {
    try {
      const contract = await connectingWithSmartContract();

      await contract.mintNFT(metadataUrl, ethers.parseUnits(price, 'ether'));
    } catch (error) {
      console.log(`Something went wrong creating NFT ${error}`);
    }
  };

  const fetchNFTs = async (): Promise<void> => {
    try {
      const contract = await connectingWithSmartContract();
      const data = await contract.listNFTs();

      return data?.map((nft: ContractNFT) => ({
        id: Number(nft['0']),
        owner: nft['1'],
        url: nft['2'],
      }));
    } catch (error) {
      console.log(`Something went wrong fetching NFTs ${error}`);
    }
  };

  return (
    <SmartContractContext.Provider
      value={{
        checkIfWalletIsConnected,
        connectToWallet,
        createNFT,
        fetchNFTs,
        currentAccount,
      }}>
      {children}
    </SmartContractContext.Provider>
  );
};
