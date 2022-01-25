const { expect } = require('chai');
const _ = require('../common/constant');
const Factory = require('../common/factory');
const { ethers } = require('hardhat');
const handlerV1ABI = require('../artifacts/contracts/Proxy.sol/HandlerV1.json');

// const _helper = require('../common/helper');

describe('Handle proxy implement upgradeable contract', () => {
  let proxy, handlerV1, handlerV1Factory, handlerV2, owner;
  beforeEach(async () => {
    proxyFactory = await ethers.getContractFactory('Proxy');
    proxy = await proxyFactory.deploy(); // [handlerV1, handlerV1Factory] = await Factory.createHandlerV1Contract();

    handlerV1Factory = await ethers.getContractFactory('HandlerV1');
    handlerV1 = await handlerV1Factory.deploy();

    [handlerV2] = await Factory.createHandlerV2Contract();
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

      console.log('====> handlerV1Factory', handlerV1Factory);
      console.log('====> proxy', proxy.address);
      console.log('====> proxyHandlerV1', proxyHandlerV1.address);

      await proxyHandlerV1.inc();
      // await proxyHandlerV1.increaseCount();
      // await proxyHandlerV1.increaseCount();
      console.log(await proxyHandlerV1.x());
    });
  });
});
