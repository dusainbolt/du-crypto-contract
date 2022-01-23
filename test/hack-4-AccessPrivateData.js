const { expect } = require('chai');
const { ethers } = require('hardhat');
const _ = require('../common/constant');
const Factory = require('../common/factory');
// const _helper = require('../common/helper');

// export const createVaultContract = async () => {
//   const vaultFactory = await ethers.getContractFactory('Vault');
//   const vault = await vaultFactory.deploy(_.passwordDuDevBytes32);
//   await vault.deployed();
//   return vault;
// };

describe('Access to private data on smart contract', async () => {
  it('Create Demo Access Private Data smart contract', async () => {
    const vault = await Factory.createVaultContract();
    expect(vault.address).to.exist;
  });
  // it('Demo flow access private data on contract', async () => {
  //   const vault = await createVaultContract();
  //   const getContract = await ethers.getContractAt('Vault', vault.address);
  //   // console.log("getContract =========> ", getContract);
  // });
});
