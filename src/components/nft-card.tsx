import Image from 'next/image';
import React from 'react';
import { NFTItem } from '~/types';

const NFTCard = (props: NFTItem) => {
  const { username, description, image } = props.metadata;

  return (
    <article>
      <Image
        src={image}
        alt={username}
        className="object-fit size-20"
        width={500}
        height={500}
      />
      <p>{description}</p>
    </article>
  );
};

export default NFTCard;
