import '@nomicfoundation/hardhat-foundry';
import '@nomicfoundation/hardhat-toolbox-viem';
import dotenv from 'dotenv';
import type { HardhatUserConfig } from 'hardhat/config';

dotenv.config();

const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY || '';
const SEPOLIA_URL = process.env.SEPOLIA_URL || '';

function utf8ToHex(str: string) {
  return Array.from(str)
    .map(c =>
      c.charCodeAt(0) < 128
        ? c.charCodeAt(0).toString(16)
        : encodeURIComponent(c).replace(/\%/g, '').toLowerCase()
    )
    .join('');
}

const SEPOLIA_PRIVATE_KEY_HEX = utf8ToHex(SEPOLIA_PRIVATE_KEY ?? '');

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.28',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: 'sepolia',
  networks: {
    hardhat: {},
    sepolia: {
      url: SEPOLIA_URL,
      accounts: [`0x${SEPOLIA_PRIVATE_KEY_HEX}`],
    },
  },
};
export default config;
