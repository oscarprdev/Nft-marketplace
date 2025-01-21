'use client';

import { ethers } from 'ethers';
import React, { createContext, useState } from 'react';
import { connectWithSmartContract } from '~/lib/ethers/connect-contract';
import { getContract } from '~/lib/ethers/get-contract';
import { ContractNFT, ContractNFTItem, CreateNFTInput } from '~/types';

type SmartContractContextType = {
  connectToWallet: () => Promise<void>;
  createNFT: (input: CreateNFTInput) => Promise<void>;
  fetchNFTs: () => Promise<ContractNFTItem[]>;
  contract: ethers.Contract | null;
} | null;

export const SmartContractContext = createContext<SmartContractContextType>(null);

export const SmartContractProvider = ({ children }: { children: React.ReactNode }) => {
  const [contract, setContract] = useState<ethers.Contract | null>(null);

  const connectToWallet = async (): Promise<void> => {
    try {
      if (!window.ethereum) return console.log('No metamask connected');

      // const accounts = await window.ethereum.request({ method: 'eth_accounts' });
      // const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
      const contract = await connectWithSmartContract();

      setContract(contract);
    } catch (error) {
      console.log(`Something went wrong connecting to wallet ${error}`);
    }
  };

  const createNFT = async ({ metadataUrl, price }: CreateNFTInput): Promise<void> => {
    try {
      const contract = await connectWithSmartContract();

      await contract.mintNFT(metadataUrl, ethers.parseUnits(price, 'ether'));
    } catch (error) {
      console.log(`Something went wrong creating NFT ${error}`);
    }
  };

  const fetchNFTs = async (): Promise<ContractNFTItem[]> => {
    try {
      const contract = getContract();
      const data = await contract.getNFTs();

      return data?.map((nft: ContractNFT) => {
        const [tokenId, creator, owner, uri, price, isListed, timestamp] = Object.values(nft);

        return {
          tokenId: Number(tokenId),
          creator,
          owner,
          uri,
          isListed,
          price: ethers.formatEther(price),
          timestamp: Number(timestamp).toString(),
        } satisfies ContractNFTItem;
      });
    } catch (error) {
      console.log(`Something went wrong fetching NFTs ${error}`);
      return [];
    }
  };

  return (
    <SmartContractContext.Provider
      value={{
        createNFT,
        fetchNFTs,
        connectToWallet,
        contract,
      }}>
      {children}
    </SmartContractContext.Provider>
  );
};
