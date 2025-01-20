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
  username: string;
  description: string;
  price: string;
  fileUrl: string;
};

export const uploadMetadata = async (input: UploadMetadataInput) => {
  const resonse = await fetch('/api/metadata', {
    method: 'POST',
    body: JSON.stringify(input),
  });
  return await resonse.json();
};
