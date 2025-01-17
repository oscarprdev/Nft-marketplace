'use client';

import { NFTMarketplaceABI, NFTMarketplaceAddress } from '../constants';
import { ethers } from 'ethers';
import React, { createContext, useState } from 'react';
import Web3Modal from 'web3modal';
import { CreateNFTInput, NFTItem, NFTToken } from '~/types';

type SmartContractContextType = {
  connectToWallet: () => Promise<void>;
  checkIfWalletIsConnected: () => Promise<void>;
  createNFT: (input: CreateNFTInput) => Promise<void>;
  fetchNFTs: () => Promise<NFTItem[]>;
  fetchMyNFTs: () => Promise<NFTItem[]>;
  fetchListedNFTs: () => Promise<NFTItem[]>;
  buyNFT: (nft: NFTItem) => Promise<void>;
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

const convertNFTTokensToNFTItems = async (
  tokens: NFTToken[],
  contract: ethers.Contract
): Promise<NFTItem[]> =>
  await Promise.all(
    tokens.map(async ({ tokenId, seller, owner, price: unformattedPrice }) => {
      const tokenURI = await contract.tokenURI(tokenId);

      const response = await fetch(tokenURI);
      const data = await response.json();

      const price = ethers.formatUnits(unformattedPrice, 'ether');

      return {
        tokenURI,
        seller,
        owner,
        image: data.image,
        name: data.name,
        description: data.description,
        tokenId: Number(tokenId),
        price: Number(price),
      } satisfies NFTItem;
    })
  );

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

      const accounts = await window.ethereum.request({ method: 'eth_requestAccount' });

      setCurrentAccount(accounts[0]);
    } catch (error) {
      console.log(`Something went wrong connecting to wallet ${error}`);
    }
  };

  const createNFT = async ({
    username,
    description,
    price,
    fileUrl,
  }: CreateNFTInput): Promise<void> => {
    try {
      const response = await fetch('/api/metadata', {
        method: 'POST',
        body: JSON.stringify({ username, description, fileUrl }),
      });
      const url = await response.json();

      await createSale(url, price, false);
    } catch (error) {
      console.log(`Something went wrong creating NFT ${error}`);
    }
  };

  const createSale = async (url: string, price: string, isReselling: boolean): Promise<void> => {
    try {
      const ethPrice = ethers.parseUnits(price, 'ether');
      const contract = await connectingWithSmartContract();

      const listingPrice = await contract.getListingPrice();
      const transaction = !isReselling
        ? await contract.createToken(url, ethPrice, { value: listingPrice.toString() })
        : await contract.reSellToken(url, ethPrice, { value: listingPrice.toString() });

      await transaction.wait();
    } catch (error) {
      console.log(`Something went wrong creating sale ${error}`);
    }
  };

  const fetchNFTs = async (): Promise<NFTItem[]> => {
    try {
      const provider = new ethers.JsonRpcProvider();
      const contract = fetchContract(provider);

      const data = await contract.fetchMarketItems();

      return await convertNFTTokensToNFTItems(data, contract);
    } catch (error) {
      console.log(`Something went wrong fetching NFTs ${error}`);
      return [];
    }
  };

  const fetchMyNFTs = async (): Promise<NFTItem[]> => {
    try {
      const contract = await connectingWithSmartContract();
      const data = (await contract.fetchMyNFT()) as NFTToken[];

      return await convertNFTTokensToNFTItems(data, contract);
    } catch (error) {
      console.log(`Something went wrong fetching my NFTs ${error}`);
      return [];
    }
  };

  const fetchListedNFTs = async (): Promise<NFTItem[]> => {
    try {
      const contract = await connectingWithSmartContract();
      const data = (await contract.fetchItemsListed()) as NFTToken[];

      return await convertNFTTokensToNFTItems(data, contract);
    } catch (error) {
      console.log(`Something went wrong fetching listed NFTs ${error}`);
      return [];
    }
  };

  const buyNFT = async (nft: NFTItem): Promise<void> => {
    try {
      const contract = await connectingWithSmartContract();
      const price = ethers.parseUnits(nft.price.toString(), 'ether');

      const transaction = await contract.createMarketSale(nft.tokenId, { value: price });

      await transaction.wait();
    } catch (error) {
      console.log(`Something went wrong buying NFT ${error}`);
    }
  };

  return (
    <SmartContractContext.Provider
      value={{
        checkIfWalletIsConnected,
        connectToWallet,
        createNFT,
        fetchNFTs,
        fetchMyNFTs,
        fetchListedNFTs,
        buyNFT,
        currentAccount,
      }}>
      {children}
    </SmartContractContext.Provider>
  );
};
