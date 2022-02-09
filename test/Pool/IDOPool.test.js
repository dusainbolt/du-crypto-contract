const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');
const Helper = require('../../common/helper');

const _ = {
  address0: '0x0000000000000000000000000000000000000000',
  duration: 86400,
  openTime: (Date.now() / 1000).toFixed(),
  offerCurrencyUSDT: '0x7648563Ef8FFDb8863fF7aDB5A860e3b14D28946',
  offerCurrencyRate: 2,
  offerCurrencyDecimals: 6,
};

describe('IDO Pool Factory', () => {
  beforeEach(async () => {
    [owner, wallet] = await ethers.getSigners();
    // USDTToken = '0x7648563Ef8FFDb8863fF7aDB5A860e3b14D28946';

    const StableTokenFactory = await ethers.getContractFactory('StableToken');

    USDTToken = await StableTokenFactory.deploy('Tether', 'USDT');
    USDCToken = await StableTokenFactory.deploy('USD Coin', 'USDC');

    const ERC20TokenFactory = await ethers.getContractFactory('ERC20Token');
    // Deploy IDO token
    idoToken = await ERC20TokenFactory.deploy('IDOToken', 'LHD', owner.address, Helper.mulDecimal(5, 27));
    await idoToken.deployed();

    idoTokenAddress = idoToken.address;

    const IDOPoolFactoryFactory = await ethers.getContractFactory('IDOPoolFactory');

    // Deploy Factory
    poolFactory = await upgrades.deployProxy(IDOPoolFactoryFactory);

    await poolFactory.registerPool(
      idoTokenAddress,
      _.duration,
      _.openTime,
      _.offerCurrencyUSDT,
      _.offerCurrencyDecimals,
      _.offerCurrencyRate,
      wallet.address
    );

    const IDOPoolAddress = poolFactory.allPools(0);

    const IDOPoolFactory = await ethers.getContractFactory('IDOPool');

    pool = IDOPoolFactory.attach(IDOPoolAddress);

    // transfer token to pool
    idoToken.transfer(IDOPoolAddress, Helper.convertEtherToWei("1000000"));
  });

  // Initialize properties
  it('Should return the Owner Address', async function () {
    const ownerAddress = await pool.owner();
    expect(ownerAddress).to.equal(owner.address);
  });

  // Token Address
  it('Should return token address', async function () {
    const tokenAddress = await pool.token();
    expect(tokenAddress).to.equal(idoTokenAddress);
  });

  // Factory Address
  it('Should return factory address', async function () {
    const factoryAddress = await pool.factory();
    expect(factoryAddress).to.equal(poolFactory.address);
  });

  // fundingWallet Address
  it('Should return fundingWallet address equal wallet', async function () {
    const fundingWallet = await pool.fundingWallet();
    expect(fundingWallet).to.equal(wallet.address);
  });

  // Open time
  it('Should return correct open time', async function () {
    const openTime = await pool.openTime();
    expect(openTime).to.equal(_.openTime);
  });

  // Close time
  it('Should return correct close time', async function () {
    const closeTime = await pool.closeTime();
    expect(closeTime).to.equal(parseInt(_.openTime) + _.duration);
  });

  // Set Close time
  it('Should set Close time', async function () {
    const newCloseTime = (parseInt(_.openTime) + _.duration) + _.duration;
    await pool.setCloseTime(newCloseTime);
    expect(newCloseTime).to.equal(await pool.closeTime());
  });

  // Set Close time
  it('Should set Open time', async function () {
    const newOpenTime = (parseInt(_.openTime) + _.duration) + _.duration - 100000;
    await pool.setOpenTime(newOpenTime);
    expect(newOpenTime).to.equal(await pool.openTime());
  });

  // Get getEtherConversionRate
  // 0x0000000000000000000000000000000000000000
  it('Should return correct etherConversionRate', async function () {
    await pool.setOfferCurrencyRateAndDecimals(_.address0, 1, 100);
    expect(await pool.getOfferedCurrencyRate(_.address0)).to.equal(1);
    expect(await pool.getOfferedCurrencyDecimals(_.address0)).to.equal(100);
  });

  // Set token conversion rate
  // 0x0000000000000000000000000000000000000000
  it('Should return correct USDT token conversion rate', async function () {
    await pool.setOfferCurrencyRateAndDecimals(USDTToken.address, 1, 100);
    expect(await pool.getOfferedCurrencyRate(USDTToken.address)).to.equal(1);
    expect(await pool.getOfferedCurrencyDecimals(USDTToken.address)).to.equal(100);
  });

  it('Should return correct USDC token conversion rate', async function () {
    await pool.setOfferCurrencyRateAndDecimals(USDCToken.address, 1, 100);
    expect(await pool.getOfferedCurrencyRate(USDCToken.address)).to.equal(1);
    expect(await pool.getOfferedCurrencyDecimals(USDCToken.address)).to.equal(100);
  });

  it('Should return correct USDC & USDT token conversion rate', async function () {
    await pool.setOfferCurrencyRateAndDecimals(USDTToken.address, 2, 200);
    await pool.setOfferCurrencyRateAndDecimals(USDCToken.address, 1, 100);

    expect(await pool.getOfferedCurrencyRate(USDTToken.address)).to.equal(2);
    expect(await pool.getOfferedCurrencyDecimals(USDTToken.address)).to.equal(200);
    expect(await pool.getOfferedCurrencyRate(USDCToken.address)).to.equal(1);
    expect(await pool.getOfferedCurrencyDecimals(USDCToken.address)).to.equal(100);
  });

  // Get getEtherConversionRateDecimals
  it('Should return correct etherConversionRateDecimals', async function () {});

  // Should return correct factory
  it('Should return correct factory address', async function () {});

  // Should claim correctly
  it('Buy by ETH and Claim correct value for Claim functions', async function () {});

  it('Buy by Token and Claim correct value for Claim functions', async function () {});

  // Should refund remain token correctly
  it('Refund remaining token', async function () {});
});
