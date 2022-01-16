const { ethers } = require('hardhat');

module.exports = {
  // nft-market-place-contract
  listingPrice: ethers.utils.parseUnits('0.00025', 'ether'),
  nftContractName: 'NFT contract name',
  nftContractSymbol: 'NFTSymbol',

  // hack-1-reEntrancy
};
