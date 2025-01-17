import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'sapphire-advisory-piranha-206.mypinata.cloud',
        port: '',
        pathname: '**',
        search: '',
      },
    ],
  },
};

export default nextConfig;
