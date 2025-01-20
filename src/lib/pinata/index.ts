'server only';

import { PinataSDK } from 'pinata-web3';

const MAX_MB_SIZE = 5;

export class Pinata {
  private sdk: PinataSDK;

  constructor() {
    this.sdk = new PinataSDK({
      pinataJwt: `${process.env.PINATA_JWT}`,
      pinataGateway: `${process.env.NEXT_PUBLIC_GATEWAY_URL}`,
    });
  }

  async uploadFile(file: File) {
    if (!this.sdk) throw new Error('Pinata not configured');
    if (!file) throw new Error('Pinata requires a file to be uploaded');
    if (file.size > MAX_MB_SIZE * 1024 * 1024)
      throw new Error(`File size exceeded the maximum required (${MAX_MB_SIZE}MB)`);

    const uploadData = await this.sdk.upload.file(file);
    return await this.sdk.gateways.convert(uploadData.IpfsHash);
  }
}
