import './globals.css';
import type { Metadata } from 'next';
import { Geist } from 'next/font/google';
import { Toaster } from 'sonner';
import { ModalProvider } from '~/context/modal';
import { SmartContractProvider } from '~/context/smart-contract';
import QueryProvider from '~/context/tanstack-query';

const geistSans = Geist({
  variable: '--font-geist-sans',
  subsets: ['latin'],
});

export const metadata: Metadata = {
  title: 'NFT AI Art',
  description: 'Create NFTs with AI art',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${geistSans.variable} antialiased`}>
        <QueryProvider>
          <SmartContractProvider>
            <ModalProvider>
              <Toaster />
              {children}
            </ModalProvider>
          </SmartContractProvider>
        </QueryProvider>
      </body>
    </html>
  );
}
