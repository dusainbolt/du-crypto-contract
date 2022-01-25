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

  static createProxyContract = async () => {
    const proxyFactory = await ethers.getContractFactory('Proxy');
    const proxy = await proxyFactory.deploy();
    await proxy.deployed();
    return proxy;
  };

  static createHandlerV1Contract = async () => {
    const handlerV1Factory = await ethers.getContractFactory('HandlerV1');
    const handlerV1 = await handlerV1Factory.deploy();
    await handlerV1.deployed();
    return handlerV1;
  };

  static createHandlerV2Contract = async () => {
    const handlerV2Factory = await ethers.getContractFactory('HandlerV2');
    const handlerV2 = await handlerV2Factory.deploy();
    await handlerV2.deployed();
    return handlerV2;
  };
}

module.exports = Factory;
