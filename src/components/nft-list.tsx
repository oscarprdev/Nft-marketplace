'use client';

import { useQuery } from '@tanstack/react-query';
import React, { useContext } from 'react';
import { SmartContractContext } from '~/context/smart-contract';

const NFTList = () => {
  const { fetchNFTs } = useContext(SmartContractContext)!;
  const { data, isLoading } = useQuery({
    queryKey: ['nfts'],
    queryFn: async () => {
      const response = await fetchNFTs();
      console.log({ response });
      return response;
    },
  });

  console.log(data);

  return <div className="size-10 text-white">{isLoading ? 'loading' : JSON.stringify(data)}</div>;
};

export default NFTList;
