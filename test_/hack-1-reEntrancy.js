const { expect, util } = require('chai');
const { ethers } = require('hardhat');
const _ = require('../common/constant');
const _helper = require('../common/helper');

// const createEtherStore = async () => {
//   const etherStoreFactory = await ethers.getContractFactory('EtherStore');
//   const etherStore = await etherStoreFactory.deploy();
//   await etherStore.deployed();
//   return etherStore;
// };

// const createAttackContract = async etherStoreAddress => {
//   const attackFactory = await ethers.getContractFactory('Attack');
//   const attack = await attackFactory.deploy(etherStoreAddress);
//   await attack.deployed();
//   return attack;
// };

// describe('Attack to Ether Store testing', async () => {
//   it('Create EtherStore smart Contract', async () => {
//     const etherStore = await createEtherStore();
//     expect(await etherStore.address).to.exist;
//   });
//   it('Create Attack smart contract', async () => {
//     const etherStore = await createEtherStore();
//     const attack = await createAttackContract(etherStore.address);
//     expect(await attack.address).to.exist;
//   });
//   it('Attack flow', async () => {
//     const etherStore = await createEtherStore();
//     const attack = await createAttackContract(etherStore.address);
//     const [_attacker, Alice, Bob] = await ethers.getSigners();
//     // console.log(_helper.convertWeiToEther(await _attacker.getBalance()));
//     const storeMoney = ethers.utils.parseUnits('1', 'ether');
//     await etherStore.connect(Alice).deposit({ value: storeMoney });
//     await etherStore.connect(Bob).deposit({ value: storeMoney });
//     console.log('===> Alice Balance after deposit 1 Ether: ', await _helper.getAccBalanceEther(Alice), ' ETH');
//     console.log('===> Bob Balance after deposit 1 Ether: ', await _helper.getAccBalanceEther(Alice), 'ETH');
//     // console.log(_helper.convertWeiToEther(await _attacker.getBalance()));
//     console.log(
//       '===> EtherStore balance after Bob & Alice deposit: ',
//       _helper.convertWeiToEther(await etherStore.getBalance()),
//       ' eth'
//     );
//     console.log('===> Balance of attacker when init: ', _helper.convertWeiToEther(await attack.getBalance()), ' eth');
//     await attack.connect(_attacker).attack({ value: storeMoney });
//     console.log(
//       '===> Balance of attacker after hack from Ether Store: ',
//       _helper.convertWeiToEther(await attack.getBalance()),
//       ' eth'
//     );
//   });
// });

const createTimeLock = async () => {
  const timeLockFactory = await ethers.getContractFactory('TimeLock');
  const timeLock = await timeLockFactory.deploy();
  await timeLock.deployed();
  return timeLock;
};

describe('Attack to time lock ether store', async () => {
  it('Create TimeLock smart contract', async () => {
    const timeLock = await createTimeLock();
    expect(await timeLock.address).to.exist;
  });
});
