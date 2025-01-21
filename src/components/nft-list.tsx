'use client';

import NFTCard from './nft-card';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import React, { useContext, useEffect } from 'react';
import { SmartContractContext } from '~/context/smart-contract';
import { getMetadata } from '~/lib/services';
import { NFTItem } from '~/types';

const QUERY_KEY = 'nfts';

const NFTList = () => {
  const queryClient = useQueryClient();

  const { fetchNFTs, contract } = useContext(SmartContractContext)!;
  const {
    data: nftList,
    isLoading,
    error,
  } = useQuery({
    queryKey: [QUERY_KEY],
    queryFn: async (): Promise<NFTItem[]> => {
      const nfts = await fetchNFTs();
      return await Promise.all(
        nfts.map(async nft => {
          const metadata = await getMetadata(nft.uri);
          return {
            ...nft,
            metadata,
          } satisfies NFTItem;
        })
      );
    },
  });

  useEffect(() => {
    contract?.on('NFTMinted', async (creator, tokenId) => {
      console.log('NFTMinted', creator, tokenId);
      await queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    });
  }, [contract, queryClient]);

  if (error) return <p>Error: {error.message}</p>;
  if (isLoading) return <p>Loading...</p>;
  if (!nftList || nftList.length === 0) return <p>Empty values</p>;

  return (
    <section className="size-10 text-white">
      {nftList.map(nft => (
        <NFTCard key={nft.tokenId} {...nft} />
      ))}
    </section>
  );
};

export default NFTList;
