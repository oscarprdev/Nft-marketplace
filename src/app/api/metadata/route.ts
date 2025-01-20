import { type NextRequest, NextResponse } from 'next/server';
import { Pinata } from '~/lib/pinata';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const file = new File([JSON.stringify(body)], 'metadata.json');

    const pinata = new Pinata();
    const url = await pinata.uploadFile(file);

    return NextResponse.json(url, { status: 200 });
  } catch (e) {
    console.log(e);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
