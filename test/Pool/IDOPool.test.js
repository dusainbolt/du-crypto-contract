const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');

describe('IDO Pool Factory', () => {

    beforeEach(async () => {
    [owner, idoOwner] = await ethers.getSigners();
    USDTToken = '0x7648563Ef8FFDb8863fF7aDB5A860e3b14D28946';

    const ERC20TokenFactory = await ethers.getContractFactory('ERC20Token');
    // // Deploy IDO token
    const ERC20Token = await ERC20TokenFactory.deploy('IDOToken', 'LHD', idoOwner.address, `5${'0'.repeat(2)}`);
    await ERC20Token.deployed();

    idoTokenAddress = ERC20Token.address;

    const IDOPoolFactoryFactory = await ethers.getContractFactory('IDOPoolFactory');

    // Deploy Factory
    poolFactory = await upgrades.deployProxy(IDOPoolFactoryFactory);
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
    const token = idoTokenAddress;
    const duration = 86400;
    const openTime = (Date.now() / 1000).toFixed();
    const offerCurrency = USDTToken;
    const offerCurrencyRate = 2;
    const offerCurrencyDecimals = 6;
    const wallet = idoOwner.address;
    await poolFactory.registerPool(token, duration, openTime, offerCurrency, offerCurrencyDecimals, offerCurrencyRate, wallet);
    // get Pool length
    const poolLength = await poolFactory.getPoolsLength();
    expect(poolLength).to.equal(1);

    const createdPool = await poolFactory.allPools(0);
    const pool = await poolFactory.getPools(owner.address, token, 0);
    expect(createdPool).to.equal(pool)
  });

});
