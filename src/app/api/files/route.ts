import { type NextRequest, NextResponse } from 'next/server';
import { Pinata } from '~/lib/pinata';

export async function POST(request: NextRequest) {
  try {
    const data = await request.formData();
    const file: File | null = data.get('file') as unknown as File;

    const pinata = new Pinata();
    const url = await pinata.uploadFile(file);

    return NextResponse.json(url, { status: 200 });
  } catch (e) {
    console.log(e);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
