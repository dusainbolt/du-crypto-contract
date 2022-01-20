const { expect } = require('chai');
const { ethers } = require('hardhat');
const _ = require('../common/constant');
const _helper = require('../common/helper');

const createTimeLock = async () => {
  const timeLockFactory = await ethers.getContractFactory('TimeLock');
  const timeLock = await timeLockFactory.deploy();
  await timeLock.deployed();
  return timeLock;
};

const createAttackTimeLock = async timeLockAddress => {
  const attackFactory = await ethers.getContractFactory('AttackTimeLock');
  const attackTimeLock = await attackFactory.deploy(timeLockAddress);
  await attackTimeLock.deployed();
  return attackTimeLock;
};

describe('Attack to time lock ether store', async () => {
  it('Create TimeLock smart contract', async () => {
    const timeLock = await createTimeLock();
    expect(timeLock.address).to.exist;
  });
  it('Create AttackTimeLock smart contract', async () => {
    const timeLock = await createTimeLock();
    const attackTimeLock = await createAttackTimeLock(timeLock.address);
    expect(attackTimeLock.address).to.exist;
  });
  it('Attack TimeLock contract with increase time in contract', async () => {
    const timeLock = await createTimeLock();
    const attackTimeLock = await createAttackTimeLock(timeLock.address);
    console.log('====> balance attack init: ', _helper.convertWeiToEther(await attackTimeLock.getBalance()));
    const etherDeposit = ethers.utils.parseUnits('1', 'ether');

    await attackTimeLock.attack({ value: etherDeposit });
    console.log('====> balance attack after hack: ', _helper.convertWeiToEther(await attackTimeLock.getBalance()));
    console.log('====> ', await timeLock.lockTime(attackTimeLock.address));
  });
});
