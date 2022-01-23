const { ethers } = require('hardhat');

module.exports = {
  // nft-market-place-contract
  listingPrice: ethers.utils.parseUnits('0.00025', 'ether'),
  nftContractName: 'NFT contract name',
  nftContractSymbol: 'NFTSymbol',
  // hack-4-access-private-data
  passwordDuDevBytes32: '0x7465737400000000000000000000000000000000000000000000000000000000'
  // hack-1-reEntrancy
};
