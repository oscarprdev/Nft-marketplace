import '@nomicfoundation/hardhat-foundry';
import '@nomicfoundation/hardhat-toolbox-viem';
import dotenv from 'dotenv';
import type { HardhatUserConfig } from 'hardhat/config';

dotenv.config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || '';
const SEPOLIA_URL = process.env.SEPOLIA_URL || '';

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
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },
};
export default config;
