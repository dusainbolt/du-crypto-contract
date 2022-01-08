// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat');
const _ = require('../constant');

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const NFTMarket = await hre.ethers.getContractFactory('NFTMarket');
  const nftMarket = await NFTMarket.deploy(_.listingPrice);
  await nftMarket.deployed();
  console.log('nftMarket deployed to:', nftMarket.address);

  const NFT = await hre.ethers.getContractFactory('NFT');
  const nft = await NFT.deploy(nftMarket.address, _.nftContractName, _.nftContractSymbol);
  await nft.deployed();
  console.log('nft deployed to:', nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
