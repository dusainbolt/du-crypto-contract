const { expect } = require('chai');
const { ethers } = require('hardhat');

const _ = {
  // listingPrice: 0.025 * 10 ** 18,
  listingPrice: ethers.utils.parseUnits('0.00025', 'ether'),
  nftContractName: 'NFT contract name',
  nftContractSymbol: 'NFTSymbol',
};

const createNFTMarketplace = async () => {
  const NFTMarketFactory = await ethers.getContractFactory('NFTMarket');
  const NFTMarket = await NFTMarketFactory.deploy(_.listingPrice);
  await NFTMarket.deployed();
  return NFTMarket;
};

const createNFT = async nftMarket => {
  const NFTFactory = await ethers.getContractFactory('NFT');
  const NFT = await NFTFactory.deploy(nftMarket.address, _.nftContractName, _.nftContractSymbol);
  await NFT.deployed();
};

describe('NFT Market Testing', async () => {
  it('Should create NFTMarketPlace', async () => {
    const nftMarket = await createNFTMarketplace();
    expect(await nftMarket.address).to.exist;
    expect((await nftMarket.getListingPrice()).toString()).to.equal(_.listingPrice.toString());
  });
  it('Should create NFT', async () => {
    const nftMarket = await createNFTMarketplace();
    const nft = createNFT(nftMarket);
    // expect((await nftMarket.getListingPrice()).toString()).to.equal(_.listingPrice.toString());
  });
  // it('Should create and execute market and sales', async () => {
  //   // const Greeter = await ethers.getContractFactory('NFT');
  //   // const greeter = await Greeter.deploy('Hello, world!');
  //   // await greeter.deployed();
  //   // expect(await greeter.greet()).to.equal('Hello, world!');
  //   // const setGreetingTx = await greeter.setGreeting('Hola, mundo!');
  //   // // wait until the transaction is mined
  //   // await setGreetingTx.wait();
  //   // expect(await greeter.greet()).to.equal('Hola, mundo!');
  // });
});
