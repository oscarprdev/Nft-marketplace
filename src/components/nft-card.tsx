import Image from 'next/image';
import React, { useContext } from 'react';
import { ModalContext, ModalProps } from '~/context/modal';
import { NFTItem } from '~/types';

const Test = (props: ModalProps) => {
  return <div>{JSON.stringify(props)}</div>;
};

const NFTCard = (props: NFTItem) => {
  const modalContext = useContext(ModalContext);
  const { title, image } = props.metadata;

  const handleClick = () => {
    modalContext?.open(
      <Test
        id="1"
        title="TES"
        data={{ test: 'test' }}
      />
    );
  };

  return (
    <article className="w-full rounded-xl border">
      <div className="flex w-full flex-col justify-between gap-2 p-5">
        <Image
          src={image}
          alt={title}
          className="object-fit w-full rounded-lg"
          width={500}
          height={500}
        />
        <div className="mt-auto flex w-full items-center justify-between">
          <div className="flex flex-col gap-1">
            <p>{title}</p>
            <p>{props.price} ETH</p>
          </div>
          <button
            className="h-fit rounded-full bg-white px-4 py-2 text-black"
            onClick={handleClick}>
            Create offer
          </button>
        </div>
      </div>
    </article>
  );
};

export default NFTCard;
