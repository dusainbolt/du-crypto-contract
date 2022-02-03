const { expect } = require('chai');
const _ = require('../common/constant');
const Factory = require('../common/factory');
// const _helper = require('../common/helper');

describe('Access to private data on smart contract', () => {
  let vault;
  beforeEach(async () => {
    vault = await Factory.createVaultContract();
  });
  describe('Deployment', () => {
    it('Value Exist Address', async () => {
      expect(vault.address).to.exist;
    });
  })
});
