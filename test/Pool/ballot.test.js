const { expect } = require('chai');
const { ethers } = require('hardhat');
const _ = require('../common/constant');
const Factory = require('../common/factory');
// const _helper = require('../common/helper');

describe('Denial Of Service', () => {
  let kingOfEther, attackKingOfEther, Alice, Bob;
  beforeEach(async () => {
    [kingOfEther] = await Factory.createKingOfEtherContract();
    [attackKingOfEther] = await Factory.createAttackKingOfEtherContract(kingOfEther.address);
    [owner, Alice, Bob] = await ethers.getSigners();
  });

  describe('Deployment', () => {
    it('KingOfEther Exist Address', async () => {
      expect(kingOfEther.address).to.exist;
    });
    it('Attack Exist Address', async () => {
      expect(attackKingOfEther.address).to.exist;
    });
  });

  describe('Demo', () => {
    it('Demo attack king of ether', async () => {
      const oneEther = ethers.utils.parseUnits('1', 'ether');
      await kingOfEther.connect(Alice).claimThrone({ value: oneEther });
      expect(await kingOfEther.king()).to.equal(Alice.address);

      await kingOfEther.connect(Bob).claimThrone({ value: oneEther.mul(2) });
      expect(await kingOfEther.king()).to.equal(Bob.address);

      await attackKingOfEther.attack({ value: oneEther.mul(3) });
      expect(await kingOfEther.king()).to.equal(attackKingOfEther.address);

      await expect(kingOfEther.connect(Bob).claimThrone({ value: oneEther.mul(4) })).to.be.reverted;
    });
  });
});
