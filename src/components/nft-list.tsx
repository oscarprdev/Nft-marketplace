'use client';

import { useQuery } from '@tanstack/react-query';
import React, { useContext } from 'react';
import { SmartContractContext } from '~/context/smart-contract';
import { getMetadata } from '~/lib/services';
import { NFTItem } from '~/types';

const NFTList = () => {
  const { fetchNFTs } = useContext(SmartContractContext)!;
  const { data, isLoading, error } = useQuery({
    queryKey: ['nfts'],
    queryFn: async (): Promise<NFTItem[]> => {
      const nfts = await fetchNFTs();
      return await Promise.all(
        nfts.map(async nft => {
          const metadata = await getMetadata(nft.uri);
          return {
            ...nft,
            ...metadata,
          } satisfies NFTItem;
        })
      );
    },
  });

  if (error) return <p>Error: {error.message}</p>;
  if (isLoading) return <p>Loading...</p>;

  return <div className="size-10 text-white">{JSON.stringify(data)}</div>;
};

export default NFTList;
