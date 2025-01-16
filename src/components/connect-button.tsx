'use client';

import React, { useContext, useRef, useState } from 'react';
import { SmartContractContext } from '~/context/smart-contract-context';

const ConnectButton = () => {
  const [cid, setCid] = useState<string>('');
  const inputRef = useRef<HTMLInputElement>(null);
  const { uploadNFTtoIPFS, getImageFromIPFS } = useContext(SmartContractContext);

  const onClickHandler = () => {
    inputRef.current?.click();
  };

  const inputChangeHandler = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const cid = await uploadNFTtoIPFS(file, 'NFT Name', 'NFT Description');
    setCid(cid);
  };

  const getImageFromIPFSHandler = async () => {
    getImageFromIPFS(cid);
  };

  return (
    <div>
      <button onClick={onClickHandler}>Upload NFT</button>
      <button onClick={getImageFromIPFSHandler}>Get image</button>
      <input className="hidden" ref={inputRef} type="file" onChange={inputChangeHandler} />
    </div>
  );
};

export default ConnectButton;
