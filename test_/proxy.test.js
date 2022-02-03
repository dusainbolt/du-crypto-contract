const { expect } = require('chai');
const _ = require('../common/constant');
const Factory = require('../common/factory');
const { ethers } = require('hardhat');

describe('Handle proxy implement upgradeable contract', () => {
  let proxy, handlerV1, handlerV1Factory, handlerV2, owner;
  beforeEach(async () => {
    proxy = await Factory.createProxyContract();
    [handlerV1, handlerV1Factory] = await Factory.createHandlerV1Contract();
    [handlerV2, handlerV2Factory] = await Factory.createHandlerV2Contract();
    [owner] = await ethers.getSigners();
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
      const proxyHandlerV1 = await handlerV1Factory.attach(proxy.address);

      await proxyHandlerV1.inc();
      await proxyHandlerV1.inc();
      await proxyHandlerV1.inc();
      expect(await proxyHandlerV1.x()).to.equal(3);

      await proxy.setImplementation(handlerV2.address);
      const proxyHandlerV2 = await handlerV2Factory.attach(proxy.address);

      await proxyHandlerV2.dec();

      expect(await proxyHandlerV1.x()).to.equal(2);
    });
  });
});
