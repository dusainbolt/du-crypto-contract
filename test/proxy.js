const { expect } = require('chai');
const _ = require('../common/constant');
const Factory = require('../common/factory');
const { ethers } = require('hardhat');
// const _helper = require('../common/helper');

describe('Handle proxy implement upgradeable contract', () => {
  let proxy, handlerV1, handlerV2;
  beforeEach(async () => {
    proxy = await Factory.createProxyContract();
    handlerV1 = await Factory.createHandlerV1Contract();
    handlerV2 = await Factory.createHandlerV2Contract();
  });
  describe('Deployment', () => {
    it('proxy Exist Address', async () => {
      expect(proxy.address).to.exist;
    });
    it('handlerV1 Exist Address', async () => {
      expect(handlerV1.address).to.exist;
    });
    it('handlerV2 Exist Address', async () => {
      expect(handlerV2.address).to.exist;
    });
  });

  describe('Demo', () => {
    it('upgrade version Handler by Proxy Contract', async () => {
      await proxy.setImplementation(handlerV1.address);
      // await proxy.countValue();
    
      // const value = proxy.value();
      // console.log("value ===> ", value);
    });
  });
});
