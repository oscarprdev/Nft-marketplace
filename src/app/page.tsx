// import ConnectButton from '~/components/connect-button';
import CreateNFTForm from '~/components/create-nft-form';
import NFTList from '~/components/nft-list';

export default async function Home() {
  return (
    <main className="w-screen">
      {/* <ConnectButton /> */}
      <CreateNFTForm />
      <NFTList />
    </main>
  );
}
