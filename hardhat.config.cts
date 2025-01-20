import '@nomicfoundation/hardhat-toolbox-viem';
import dotenv from 'dotenv';
import type { HardhatUserConfig } from 'hardhat/config';

dotenv.config();

const config: HardhatUserConfig = {
  solidity: '0.8.28',
};
export default config;
