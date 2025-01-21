import { getMetadata } from '../services';
import { ContractNFTItem, NFTItem } from '~/types';

export const getNFTList = async (
  fetchNFTs: () => Promise<ContractNFTItem[]>
): Promise<NFTItem[]> => {
  // Fetch NFTs from the contract
  const nfts = await fetchNFTs();

  return await Promise.all(
    nfts.map(async nft => {
      // Fetch metadata for each NFT
      const metadata = await getMetadata(nft.uri);

      return {
        ...nft,
        metadata,
      } satisfies NFTItem;
    })
  );
};
