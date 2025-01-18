'use client';

import { useContext } from 'react';
import { SmartContractContext } from '~/context/smart-contract';

export default function ConnectButton() {
  const { connectToWallet, currentAccount } = useContext(SmartContractContext)!;

  return (
    <>
      {currentAccount ? (
        <p>Connected!</p>
      ) : (
        <button
          className="rounded-full bg-white px-5 py-2"
          onClick={async () => await connectToWallet()}>
          Connect Wallet
        </button>
      )}
    </>
  );
}
