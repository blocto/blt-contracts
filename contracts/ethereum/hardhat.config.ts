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
  },
  solidity: {
    compilers: [
      {
        version: "0.8.0",
        settings: {
          optimizer: { enabled: true, runs: 200 },
        },
      },
    ],
  },
  etherscan: {
    apiKey: "", // etherscan api key here...
  },
};

export default config;
