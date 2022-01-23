const { ethers } = require('hardhat');
const _ = require('../common/constant');

class Factory {
  static createVaultContract = async () => {
    const vaultFactory = await ethers.getContractFactory('Vault');
    const vault = await vaultFactory.deploy(_.passwordDuDevBytes32);
    await vault.deployed();
    return vault;
  };
  
}

module.exports = Factory;
