require("@nomicfoundation/hardhat-toolbox");
// require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-etherscan");
require("solidity-coverage");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10000,
      },
    },
  },
  gasReporter: {
    enabled: false,
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    goerli: {
      url: "https://rpc.ankr.com/eth_goerli",
      accounts: [],
    },
    polygon: {
      url: "https://polygon-rpc.com",
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "8SDDMUYUZDQBCN1WDYP36I59UCFRJEX6UF",
  },
};
