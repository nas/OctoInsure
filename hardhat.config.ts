require('dotenv').config();
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const accountKey = process.env.PVT_KEY as string;
console.info(accountKey)

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    hardhat: {},
    goerli: {
      url: process.env.GOERLI_RPC_URL,
      accounts: [accountKey],
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [accountKey],
    },
    'base-goerli':{
      url: process.env.BASE_RPC_URL,
      accounts: [accountKey],
    }
  },
  // find all supported networks by:
  // npx hardhat verify --list-networks
  // https://hardhat.org/hardhat-runner/plugins/nomicfoundation-hardhat-verify#multiple-api-keys-and-alternative-block-explorers
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_PRIVATE_KEY as string,
      goerli: process.env.ETHERSCAN_PRIVATE_KEY as string,
    },
  },
  paths: {
    artifacts: "./artifacts",
    tests: "./test",
  },
  gasReporter: {
    enabled: String(process.env.REPORT_GAS) == "1" ? true : false,
  },
};

export default config;
