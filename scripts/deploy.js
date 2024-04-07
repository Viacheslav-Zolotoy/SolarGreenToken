// const hre = require("hardhat");
// const ethers = hre.ethers;

// async function main() {
//   const [signer] = await ethers.getSigners();

//   const TokenSale = await ethers.getContractFactory("TokenSale", signer);
//   const tokenSale = await TokenSale.deploy(222);
//   await tokenSale.getDeployedCode();
//   console.log(await tokenSale.getAddress());
// }

// main()
//   .then(() => process.exit(0))
//   .catch((error) => {
//     console.error(error);
//     process.exit(1);
//   });

// const { ethers } = require("hardhat");

// async function main() {
//   const [deployer] = await ethers.getSigners();
//   console.log("Deploying contracts with the account:", deployer.address);

//   const TokenSale = await ethers.getContractFactory("TokenSale");
//   const token = await TokenSale.deploy(123);
//   await token.getDeployedCode();

//   console.log(await token.getAddress());

//   console.log("Token address:", token.address);
// }

// main()
//   .then(() => process.exit(0))
//   .catch((error) => {
//     console.error(error);
//     process.exit(1);
//   });

const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  const [signer] = await ethers.getSigners();

  const TokenSale = await ethers.getContractFactory("TokenSale", signer);
  const erc = await TokenSale.deploy(222);
  await erc.waitForDeployment();
  console.log(await erc.getAddress());
  // console.log(await erc.token());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
