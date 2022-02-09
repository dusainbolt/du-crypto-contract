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
    [owner, idoOwner] = await ethers.getSigners();
    USDTToken = '0x7648563Ef8FFDb8863fF7aDB5A860e3b14D28946';

    const ERC20TokenFactory = await ethers.getContractFactory('ERC20Token');
    // Deploy IDO token
    ERC20Token = await ERC20TokenFactory.deploy('IDOToken', 'LHD', idoOwner.address, Helper.mulDecimal(5, 27));
    await ERC20Token.deployed();

    idoTokenAddress = ERC20Token.address;

    const IDOPoolFactoryFactory = await ethers.getContractFactory('IDOPoolFactory');

    // Deploy Factory
    poolFactory = await upgrades.deployProxy(IDOPoolFactoryFactory);

    wallet = idoOwner.address;
  });

  it('Should return the Owner address', async () => {
    expect(await poolFactory.owner()).to.equal(owner.address);
  });

  it('Should return false for initialize suspending status', async () => {
    expect(await poolFactory.paused()).to.equal(false);
  });

  it('Should return zero pool length', async () => {
    const poolLength = await poolFactory.getPoolsLength();
    expect(poolLength).to.equal(0);
  });

  it('Should register success pool', async () => {
    await poolFactory.registerPool(
      idoTokenAddress,
      _.duration,
      _.openTime,
      _.offerCurrencyUSDT,
      _.offerCurrencyDecimals,
      _.offerCurrencyRate,
      wallet
    );
    // get Pool length
    const poolLength = await poolFactory.getPoolsLength();
    expect(poolLength).to.equal(1);

    const createdPool = await poolFactory.allPools(0);
    const pool = await poolFactory.getPools(owner.address, idoTokenAddress, 0);
    expect(createdPool).to.equal(pool);
  });

  it('Should revert register pool with token address 0', async () => {
    await expect(
      poolFactory.registerPool(
        _.address0,
        _.duration,
        _.openTime,
        _.offerCurrencyUSDT,
        _.offerCurrencyDecimals,
        _.offerCurrencyRate,
        wallet
      )
    ).to.revertedWith('ICOFactory::ZERO_TOKEN_ADDRESS');
  });

  it('Should revert register pool with duration equal 0', async () => {
    await expect(
      poolFactory.registerPool(
        idoTokenAddress,
        0,
        _.openTime,
        _.offerCurrencyUSDT,
        _.offerCurrencyDecimals,
        _.offerCurrencyRate,
        wallet
      )
    ).to.revertedWith('ICOFactory::ZERO_DURATION');
  });

  it('Should revert register pool with wallet address 0', async () => {
    await expect(
      poolFactory.registerPool(
        idoTokenAddress,
        _.duration,
        _.openTime,
        _.offerCurrencyUSDT,
        _.offerCurrencyDecimals,
        _.offerCurrencyRate,
        _.address0
      )
    ).to.revertedWith('ICOFactory::ZERO_WALLET_ADDRESS');
  });

  it('Should revert register pool with Offer rate equal 0', async () => {
    await expect(
      poolFactory.registerPool(
        idoTokenAddress,
        _.duration,
        _.openTime,
        _.offerCurrencyUSDT,
        _.offerCurrencyDecimals,
        0,
        wallet
      )
    ).to.revertedWith('ICOFactory::ZERO_OFFERED_RATE');
  });

  it('Should revert register pool when paused is true', async () => {
    await poolFactory.pause();
    await expect(
      poolFactory.registerPool(
        idoTokenAddress,
        _.duration,
        _.openTime,
        _.offerCurrencyUSDT,
        _.offerCurrencyDecimals,
        _.offerCurrencyRate,
        wallet
      )
    ).to.revertedWith('CONTRACT_PAUSED');
  });
});
