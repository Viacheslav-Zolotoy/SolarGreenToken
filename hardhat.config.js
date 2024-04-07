// require("dotenv").config();
// ("@nomicfoundation/hardhat-ethers");
// require("@nomicfoundation/hardhat-toolbox");

// const { API_URL, PRIVATE_KEY } = process.env;

// module.exports = {
//   solidity: {
//     version: "0.8.24",
//     settings: {
//       optimizer: {
//         enabled: true,
//         runs: 200,
//       },
//     },
//   },
//   defaultNetwork: "sepolia",
//   networks: {
//     hardhat: {},
//     sepolia: {
//       url: API_URL,
//       accounts: [PRIVATE_KEY],
//     },
//   },
// };

// // /** @type import('hardhat/config').HardhatUserConfig */
// // module.exports = {
// //   solidity: "0.8.24",
// // };

// module.exports = {
//   defaultNetwork: "sepolia",
//   networks: {
//     hardhat: {},
//     sepolia: {
//       url: API_URL,
//       accounts: [PRIVATE_KEY],
//     },
//   },
//   solidity: {
//     version: "0.8.24",
//     settings: {
//       optimizer: {
//         enabled: true,
//         runs: 200,
//       },
//     },
//   },
//   paths: {
//     sources: "./contracts",
//     tests: "./test",
//     cache: "./cache",
//     artifacts: "./artifacts",
//   },
//   mocha: {
//     timeout: 40000,
//   },
// };

require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
};
