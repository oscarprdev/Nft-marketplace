export const uploadFile = async (file: File) => {
  const formData = new FormData();
  formData.append('file', file);

  const resonse = await fetch('/api/files', {
    method: 'POST',
    body: formData,
  });
  return await resonse.json();
};

type UploadMetadataInput = {
  title: string;
  description: string;
  image: string;
};

export const uploadMetadata = async (input: UploadMetadataInput) => {
  const resonse = await fetch('/api/metadata', {
    method: 'POST',
    body: JSON.stringify(input),
  });
  return await resonse.json();
};

export const getMetadata = async (url: string) => {
  const resonse = await fetch(url);

  return await resonse.json();
};
