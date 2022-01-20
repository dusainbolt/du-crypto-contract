const { expect } = require('chai');
const { ethers } = require('hardhat');
const _ = require('../common/constant');
const _helper = require('../common/helper');

const createEtherGame = async () => {
  const etherGameFactory = await ethers.getContractFactory('EtherGame');
  const etherGame = await etherGameFactory.deploy();
  await etherGame.deployed();
  return etherGame;
};

const createAttackEtherGame = async etherGameAddress => {
  const attackFactory = await ethers.getContractFactory('AttackEtherGame');
  const attackEtherGame = await attackFactory.deploy(etherGameAddress);
  await attackEtherGame.deployed();
  return attackEtherGame;
};

describe('Attack to EtherGame with selfDestruct', async () => {
  it('Create EtherGame smart contract', async () => {
    const etherGame = await createEtherGame();
    expect(etherGame.address).to.exist;
  });
  it('Create AttackEtherGame smart contract', async () => {
    const etherGame = await createEtherGame();
    const attackEtherGame = await createAttackEtherGame(etherGame.address);
    expect(attackEtherGame.address).to.exist;
  });
  it('Attack EtherGame contract with SelfDestruct', async () => {
    const etherGame = await createEtherGame();
    const attackEtherGame = await createAttackEtherGame(etherGame.address);
    console.log('====> balance attack init: ', _helper.convertWeiToEther(await attackEtherGame.getBalance()));
    const etherDeposit = ethers.utils.parseUnits('1', 'ether');

    await etherGame.deposit({ value: etherDeposit });
    await etherGame.deposit({ value: etherDeposit });

    await attackEtherGame.fallback({ value: etherDeposit.mul(5) });

    await attackEtherGame.attack();

    await etherGame.deposit({ value: etherDeposit });
  });
});
