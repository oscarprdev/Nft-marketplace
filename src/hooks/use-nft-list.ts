import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useContext, useEffect } from 'react';
import { SmartContractContext } from '~/context/smart-contract';
import { getNFTList } from '~/lib/queries/get-nft-list';

const QUERY_KEY = 'nfts';

export const useNFTList = () => {
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

  return {
    nftList: response.data,
    isLoading: response.isLoading,
    error: response.error,
  };
};
