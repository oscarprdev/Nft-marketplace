'use client';

import { NFTMarketplaceABI, NFTMarketplaceAddress } from '../constants';
import { ethers } from 'ethers';
import React, { createContext, useState } from 'react';
import Web3Modal from 'web3modal';

const fetchContract = (signerOrProvider: ethers.JsonRpcSigner | ethers.JsonRpcProvider) =>
  new ethers.Contract(NFTMarketplaceAddress, NFTMarketplaceABI, signerOrProvider);

const connectingWithSmartContract = async () => {
  const web3Modal = new Web3Modal({ cacheProvider: true });
  const connection = await web3Modal.connect();
  const provider = new ethers.BrowserProvider(connection);
  const signer = await provider.getSigner();

  return fetchContract(signer);
};

type SmartContractContextType = {
  connectToWallet: () => Promise<void>;
  checkIfWalletIsConnected: () => Promise<void>;
  createNFT: (input: CreateNFTInput) => Promise<void>;
  fetchNFTs: () => Promise<NFTItem[]>;
  currentAccount: string | null;
} | null;

type CreateNFTInput = {
  username: string;
  description: string;
  price: string;
  fileUrl: string;
};

type NFTItem = {
  tokenId: number;
  tokenURI: string;
  seller: string;
  owner: string;
  image: string;
  name: string;
  description: string;
  price: number;
};

export const SmartContractContext = createContext<SmartContractContextType>(null);

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

  const createNFT = async ({ username, description, price, fileUrl }: CreateNFTInput) => {
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

  const createSale = async (url: string, price: string, isReselling: boolean) => {
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

  const fetchNFTs = async () => {
    try {
      const provider = new ethers.JsonRpcProvider();
      const contract = fetchContract(provider);

      const data = await contract.fetchMarketItems();
      console.log(data);

      const items = await Promise.all(
        data.map(
          async ({
            tokenId,
            seller,
            owner,
            price: unformattedPrice,
          }: {
            tokenId: string;
            seller: string;
            owner: string;
            price: string;
          }) => {
            const tokenURI = await contract.tokenURI(tokenId);
            const response = await fetch(tokenURI);
            const data = await response.json();
            const {
              data: { image, name, description },
            } = data as { data: { image: string; name: string; description: string } };
            const price = ethers.formatUnits(unformattedPrice, 'ether');

            return {
              tokenId: Number(tokenId),
              tokenURI,
              seller,
              owner,
              image,
              name,
              description,
              price: Number(price),
            } satisfies NFTItem;
          }
        )
      );

      return items as NFTItem[];
    } catch (error) {
      console.log(`Something went wrong fetching NFTs ${error}`);
      return [];
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
