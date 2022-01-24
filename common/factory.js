const { ethers } = require('hardhat');
const _ = require('../common/constant');

class Factory {
  static createVaultContract = async () => {
    const vaultFactory = await ethers.getContractFactory('Vault');
    const vault = await vaultFactory.deploy(_.passwordDuDevBytes32);
    await vault.deployed();
    return vault;
  };

  static createLibDelegateCallContract = async () => {
    const libFactory = await ethers.getContractFactory('LibDelegatecall');
    const lib = await libFactory.deploy();
    await lib.deployed();
    return lib;
  };

  static createHackMeDelegateCallContract = async libAddress => {
    const hackMeFactory = await ethers.getContractFactory('HackMeDelegatecall');
    const hackMe = await hackMeFactory.deploy(libAddress);
    await hackMe.deployed();
    return hackMe;
  };

  static createAttackDelegateCallContract = async hackMeAddress => {
    const attackFactory = await ethers.getContractFactory('AttackDelegatecall');
    const attack = await attackFactory.deploy(hackMeAddress);
    await attack.deployed();
    return attack;
  };
}

module.exports = Factory;
