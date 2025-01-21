'use client';

import NFTCard from './nft-card';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import React, { useContext, useEffect } from 'react';
import { SmartContractContext } from '~/context/smart-contract';
import { getNFTList } from '~/lib/queries/get-nft-list';

const QUERY_KEY = 'nfts';

const NFTList = () => {
  const queryClient = useQueryClient();

  const { fetchNFTs, contract } = useContext(SmartContractContext)!;

  const response = useQuery({
    queryKey: [QUERY_KEY],
    queryFn: async () => await getNFTList(fetchNFTs),
  });

  useEffect(() => {
    contract?.on('NFTMinted', async () => {
      await queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    });
  }, [contract, queryClient]);

  const { data: nftList, error, isLoading } = response;

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
