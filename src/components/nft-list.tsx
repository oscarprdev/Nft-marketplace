'use client';

import NFTCard from './nft-card';
import { useNFTList } from '~/hooks/use-nft-list';

const NFTList = () => {
  const { nftList, error, isLoading } = useNFTList();

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
