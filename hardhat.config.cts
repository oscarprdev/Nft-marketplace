import '@nomicfoundation/hardhat-foundry';
import '@nomicfoundation/hardhat-toolbox-viem';
import dotenv from 'dotenv';
import type { HardhatUserConfig } from 'hardhat/config';

dotenv.config();

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
};
export default config;
