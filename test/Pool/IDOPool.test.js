const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');

describe('IDO Pool Factory', () => {

    USDTToken = '0x7648563Ef8FFDb8863fF7aDB5A860e3b14D28946';
    beforeEach(async () => {
    // not console.log() at here
    [owner, idoOwner] = await ethers.getSigners();

    const ERC20TokenFactory = await ethers.getContractFactory('ERC20Token');
    // // Deploy IDO token
    const ERC20Token = await ERC20TokenFactory.deploy('IDOToken', 'LHD', idoOwner.address, `5${'0'.repeat(2)}`);
    await ERC20Token.deployed();

    const IDOPoolFactoryFactory = await ethers.getContractFactory('IDOPoolFactory');

    // Deploy Factory
    deployedPoolFactory = await upgrades.deployProxy(IDOPoolFactoryFactory);
  });

  it('Should return zero pool length', async () => {
    // const poolLength = poolFactory.getPoolsLength();
    // console.log("===> poolLength", poolLength);
    // expect(poolLength).to.equal(0);
  });
});
