import { type NextRequest, NextResponse } from 'next/server';
import { pinata } from '~/lib/pinata';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const uploadMetadata = await pinata.upload.file(body);
    const url = await pinata.gateways.convert(uploadMetadata.IpfsHash);

    return NextResponse.json(url, { status: 200 });
  } catch (e) {
    console.log(e);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
