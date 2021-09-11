import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";

const config: HardhatUserConfig = {
  networks: {
    rinkeby: {
      url: "", // rinkeby url
      accounts: [/* private key here. 0x... */],
    },
    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      accounts: [],
    },
    bscMainnet: {
      url: "https://bsc-dataseed1.binance.org",
      accounts: [],
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.7",
        settings: {
          optimizer: { enabled: true, runs: 1000 },
        },
      },
    ],
  },
  etherscan: {
    apiKey: "", // etherscan api key here...
  },
};

export default config;
