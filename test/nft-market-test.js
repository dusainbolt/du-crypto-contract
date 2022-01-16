const { expect } = require('chai');
const { ethers } = require('hardhat');
const _ = require('../constant');

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
  return NFT;
};

const templateItem = async (items, nft) => {
  return await Promise.all(
    items.map(async i => {
      const tokenUri = await nft.tokenURI(i.tokenId);
      let item = {
        price: i.price.toString(),
        tokenId: i.tokenId.toString(),
        seller: i.seller,
        owner: i.owner,
        tokenUri,
      };
      return item;
    })
  );
};

describe('NFT Market Testing', async () => {
  it('Should create NFTMarketPlace', async () => {
    const nftMarket = await createNFTMarketplace();
    expect(await nftMarket.address).to.exist;
    expect((await nftMarket.getListingPrice()).toString()).to.equal(_.listingPrice.toString());
  });
  it('Should create NFT', async () => {
    const nftMarket = await createNFTMarketplace();
    const nft = await createNFT(nftMarket);
    expect(await nft.address).to.exist;
  });
  it('Should create and execute market and sales', async () => {
    const nftMarket = await createNFTMarketplace();
    const nft = await createNFT(nftMarket);

    const listingPrice = await nftMarket.getListingPrice();

    await nft.createToken('https://www.mytokenlocation.com');
    await nft.createToken('https://www.mytokenlocation2.com');
    await nft.createToken('https://www.mytokenlocation3.com');

    const auctionPrice = await ethers.utils.parseUnits('1', 'ether');

    await nftMarket.createMarketItem(nft.address, 1, auctionPrice, { value: listingPrice });
    await nftMarket.createMarketItem(nft.address, 2, auctionPrice, { value: listingPrice });
    await nftMarket.createMarketItem(nft.address, 3, auctionPrice, { value: listingPrice });

    const [senderConsole, buyerAddress1, buyerAddress2] = await ethers.getSigners();

    await nftMarket.connect(buyerAddress1).createMarketSale(nft.address, 2, { value: auctionPrice });

    let marketItems = await nftMarket.fetchMarketItems();
    marketItems = await templateItem(marketItems, nft);
    console.log('marketItems: ', marketItems);

    let myItems = await nftMarket.connect(buyerAddress1).fetchMyNFTs();
    myItems = await templateItem(myItems, nft);
    console.log('myItems: ', myItems);

    let itemsCreated = await nftMarket.connect(senderConsole).fetchItemsCreated();
    itemsCreated = await templateItem(itemsCreated, nft);
    console.log('itemsCreated: ', itemsCreated);

    await nftMarket.setListingPrice(listingPrice);
  });
});
