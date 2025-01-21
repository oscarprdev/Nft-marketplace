'use client';

import Image from 'next/image';
import React, { useContext, useRef, useState } from 'react';
import { SmartContractContext } from '~/context/smart-contract';
import { uploadFile, uploadMetadata } from '~/lib/services';

const defaultState = {
  username: '',
  description: '',
  price: '',
  image: '',
};

const CreateNFTForm = () => {
  const { createNFT } = useContext(SmartContractContext)!;

  const [error, setError] = useState('');
  const [uploadingFile, setUploadingFile] = useState(false);
  const [creatingNFT, setCreatingNFT] = useState(false);

  const [formState, setFormState] = useState(defaultState);

  const inputFileRef = useRef<HTMLInputElement | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormState({ ...formState, [name]: value });
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    try {
      e.preventDefault();
      setCreatingNFT(true);

      const { username, description, price, image } = formState;

      if (!username || !description || !price || !image) throw new Error('All fields are required');

      const metadataUrl = await uploadMetadata(formState);

      await createNFT({ metadataUrl, price });
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Something went wrong creating NFT');
    } finally {
      setCreatingNFT(false);
    }
  };

  const handleChangeFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    try {
      setUploadingFile(true);

      const file = e.target.files?.[0];
      if (!file) throw new Error('File is required');

      const data = await uploadFile(file);

      setFormState({ ...formState, image: data });
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Something went wrong uploading file');
    } finally {
      setUploadingFile(false);
    }
  };
  return (
    <>
      <div className="flex items-center gap-2">
        {formState.image && (
          <Image src={formState.image} alt="NFT Image" width={300} height={300} />
        )}
        <button
          type="button"
          className="rounded-full bg-white px-5 py-2 text-black"
          onClick={() => inputFileRef?.current?.click()}>
          {uploadingFile ? 'Uploading...' : 'Upload file'}
        </button>
        <input className="hidden" type="file" ref={inputFileRef} onChange={handleChangeFile} />
      </div>
      <form onSubmit={handleSubmit} className="flex w-full flex-col items-center space-y-2">
        <label className="flex w-1/2 flex-col items-start gap-2">
          Username
          <input
            name="username"
            className="px-3 py-2"
            placeholder="Enter your username"
            onChange={handleChange}></input>
        </label>
        <label className="flex w-1/2 flex-col items-start gap-2">
          Description
          <input
            name="description"
            className="px-3 py-2"
            placeholder="Enter the NFT description"
            onChange={handleChange}></input>
        </label>
        <label className="flex w-1/2 flex-col items-start gap-2">
          Price
          <input
            name="price"
            className="px-3 py-2"
            placeholder="Enter the NFT price"
            onChange={handleChange}></input>
        </label>
        <button
          type="submit"
          // disabled={!formState.fileUrl}
          className="rounded-full bg-purple-400 px-5 py-2 font-bold text-white">
          {creatingNFT ? 'Creating...' : 'Create NFT'}
        </button>
        {error && <p className="text-xs text-red-500">{error}</p>}
      </form>
    </>
  );
};

export default CreateNFTForm;
