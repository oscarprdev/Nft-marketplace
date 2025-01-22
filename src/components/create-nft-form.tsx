'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import Image from 'next/image';
import React, { useContext, useRef, useState } from 'react';
import { useForm } from 'react-hook-form';
import { toast } from 'sonner';
import { z } from 'zod';
import { SmartContractContext } from '~/context/smart-contract';
import { uploadFile, uploadMetadata } from '~/lib/services';

const DEFAULT_FORM_VALUES = {
  title: '',
  description: '',
  price: '',
  image: '',
};

const formValuesSchema = z.object({
  title: z.string().max(20),
  description: z.string().max(50),
  price: z.string().refine(
    value => {
      const parsed = parseFloat(value);
      return !isNaN(parsed) && parsed >= 0 && /^\d+(\.\d{1,2})?$/.test(value);
    },
    { message: 'Invalid price format.' }
  ),
  image: z.string().url('Invalid Image URL format'),
});

type FormValues = z.infer<typeof formValuesSchema>;

const CreateNFTForm = () => {
  const [uploadingFile, setUploadingFile] = useState(false);

  const { createNFT } = useContext(SmartContractContext)!;
  const { handleSubmit, register, formState, setValue, setError, watch, reset } = useForm({
    resolver: zodResolver(formValuesSchema),
    defaultValues: DEFAULT_FORM_VALUES,
  });

  const inputFileRef = useRef<HTMLInputElement | null>(null);

  const onSubmit = async (formValues: FormValues) => {
    try {
      const { title, description, image, price } = formValues;
      const metadataUrl = await uploadMetadata({ title, description, image });

      await createNFT({ metadataUrl, price });
      toast.success('NFT created successfully');
      reset();
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Something went wrong creating NFT');
    }
  };

  const handleChangeFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    try {
      setUploadingFile(true);

      const file = e.target.files?.[0];
      if (!file) throw new Error('File is required');

      const imageUrl = await uploadFile(file);

      setValue('image', imageUrl);
    } catch (error) {
      setError('image', {
        message: error instanceof Error ? error.message : 'Something went wrong uploading file',
      });
    } finally {
      setUploadingFile(false);
    }
  };
  return (
    <>
      {/* Upload image */}
      <div className="flex items-center gap-2">
        {watch('image') && (
          <Image
            src={watch('image')}
            alt="NFT Image"
            width={300}
            height={300}
          />
        )}
        <button
          type="button"
          className="rounded-full bg-white px-5 py-2 text-black"
          onClick={() => inputFileRef?.current?.click()}>
          {uploadingFile ? 'Uploading...' : 'Upload file'}
        </button>
        <input
          className="hidden"
          type="file"
          ref={inputFileRef}
          onChange={handleChangeFile}
        />
        {formState.errors.image && (
          <p className="text-xs text-red-500">{formState.errors.image.message}</p>
        )}
      </div>
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="flex w-full flex-col items-center space-y-2">
        <label className="flex w-1/2 flex-col items-start gap-2">
          Title
          <input
            className="px-3 py-2"
            placeholder="Enter your title"
            {...register('title')}
          />
          {formState.errors.title && (
            <p className="text-xs text-red-500">{formState.errors.title.message}</p>
          )}
        </label>
        <label className="flex w-1/2 flex-col items-start gap-2">
          Description
          <input
            {...register('description')}
            className="px-3 py-2"
            placeholder="Enter the NFT description"
          />
          {formState.errors.description && (
            <p className="text-xs text-red-500">{formState.errors.description.message}</p>
          )}
        </label>
        <label className="flex w-1/2 flex-col items-start gap-2">
          Price
          <input
            {...register('price')}
            className="px-3 py-2"
            placeholder="Enter the NFT price"
          />
          {formState.errors.price && (
            <p className="text-xs text-red-500">{formState.errors.price.message}</p>
          )}
        </label>

        <button
          type="submit"
          disabled={formState.isSubmitting}
          className="rounded-full bg-purple-400 px-5 py-2 font-bold text-white">
          {formState.isSubmitting ? 'Creating...' : 'Create NFT'}
        </button>
      </form>
    </>
  );
};

export default CreateNFTForm;
