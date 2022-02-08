const { ethers, upgrades } = require('hardhat');

const main = async () => {
  const PoolFactory = await ethers.getContractFactory('IDOPoolFactory');

  const poolFactory = await upgrades.deployProxy(PoolFactory, [], { initializer: 'initialize' });

  // Log info
  console.log("Pool Factory deploy at: ", poolFactory.address);
  console.log("Pool Factory Owner: ", await poolFactory.owner());

  // Wait to deploy success

  await poolFactory.deployed();

};

main();