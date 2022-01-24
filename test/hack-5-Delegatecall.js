const { expect } = require('chai');
const { ethers } = require('hardhat');
const _ = require('../common/constant');
const Factory = require('../common/factory');
// const _helper = require('../common/helper');

describe('Attack with Delegatecall', () => {
  let lib, hackMe, attack;
  beforeEach(async () => {
    lib = await Factory.createLibDelegateCallContract();
    hackMe = await Factory.createHackMeDelegateCallContract(lib.address);
    attack = await Factory.createAttackDelegateCallContract(hackMe.address);
  });
  describe('Deployment', () => {
    it('Lib Exist Address', async () => {
      expect(lib.address).to.exist;
    });
    it('HackMe Exist Address', async () => {
      expect(hackMe.address).to.exist;
    });
    it('Attack Exist Address', async () => {
      expect(attack.address).to.exist;
    });
  });
  describe('Demo', () => {
    it('Attack with delegate call', async () => {
      await attack.attack();
      expect(attack.address).to.equal(await hackMe.owner());
    });
  });
});
