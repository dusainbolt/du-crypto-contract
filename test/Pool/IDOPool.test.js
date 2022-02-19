const { expect } = require("chai");
const { ethers, upgrades, web3 } = require("hardhat");
const { time } = require("@openzeppelin/test-helpers");

const Helper = require("../../common/helper");

const _ = {
  address0: "0x0000000000000000000000000000000000000000",
  duration: 86400,
  openTime: (Date.now() / 1000).toFixed(),
  offerCurrencyUSDT: "0x7648563Ef8FFDb8863fF7aDB5A860e3b14D28946",
  offerCurrencyRate: 2,
  offerCurrencyDecimals: 6,
  amountTokenOfPool: Helper.parseEther("100000000"),
};

describe("IDO Pool Factory", () => {
  beforeEach(async () => {
    [owner, wallet, buyer] = await ethers.getSigners();
    // USDTToken = '0x7648563Ef8FFDb8863fF7aDB5A860e3b14D28946';

    const StableTokenFactory = await ethers.getContractFactory("StableToken");

    USDTToken = await StableTokenFactory.deploy("Tether", "USDT");
    USDCToken = await StableTokenFactory.deploy("USD Coin", "USDC");

    const ERC20TokenFactory = await ethers.getContractFactory("ERC20Token");
    // Deploy IDO token
    idoToken = await ERC20TokenFactory.deploy("IDOToken", "LHD", owner.address, Helper.mulDecimal(5, 27));

    await idoToken.deployed();

    idoTokenAddress = idoToken.address;

    const IDOPoolFactoryFactory = await ethers.getContractFactory("IDOPoolFactory");

    // Deploy Factory
    poolFactory = await upgrades.deployProxy(IDOPoolFactoryFactory);

    await poolFactory.registerPool(
      idoTokenAddress,
      _.duration,
      _.openTime,
      _.offerCurrencyUSDT,
      _.offerCurrencyDecimals,
      _.offerCurrencyRate,
      wallet.address
    );

    const IDOPoolAddress = poolFactory.allPools(0);

    const IDOPoolFactory = await ethers.getContractFactory("IDOPool");

    pool = IDOPoolFactory.attach(IDOPoolAddress);

    // transfer token to pool
    idoToken.transfer(IDOPoolAddress, _.amountTokenOfPool);
    USDCToken.transfer(buyer.address, Helper.mulDecimal(10000, 6));

  });

  // Initialize properties
  it("Should return the Owner Address", async () => {
    const ownerAddress = await pool.owner();
    expect(ownerAddress).to.equal(owner.address);
  });

  // Token Address
  it("Should return token address", async () => {
    const tokenAddress = await pool.token();
    expect(tokenAddress).to.equal(idoTokenAddress);
  });

  // Factory Address
  it("Should return factory address", async () => {
    const factoryAddress = await pool.factory();
    expect(factoryAddress).to.equal(poolFactory.address);
  });

  // fundingWallet Address
  it("Should return fundingWallet address equal wallet", async () => {
    const fundingWallet = await pool.fundingWallet();
    expect(fundingWallet).to.equal(wallet.address);
  });

  // Open time
  it("Should return correct open time", async () => {
    const openTime = await pool.openTime();
    expect(openTime).to.equal(_.openTime);
  });

  // Close time
  it("Should return correct close time", async () => {
    const closeTime = await pool.closeTime();
    expect(closeTime).to.equal(parseInt(_.openTime) + _.duration);
  });

  // Set Close time
  it("Should set Close time", async () => {
    const newCloseTime = parseInt(_.openTime) + _.duration + _.duration;
    await pool.setCloseTime(newCloseTime);
    expect(newCloseTime).to.equal(await pool.closeTime());
  });

  // Set Close time
  it("Should set Open time", async () => {
    const newOpenTime = parseInt(_.openTime) + _.duration + _.duration - 100000;
    await pool.setOpenTime(newOpenTime);
    expect(newOpenTime).to.equal(await pool.openTime());
  });

  // Get getEtherConversionRate
  // 0x0000000000000000000000000000000000000000
  it("Should return correct etherConversionRate", async () => {
    await pool.setOfferCurrencyRateAndDecimals(_.address0, 1, 100);
    expect(await pool.getOfferedCurrencyRate(_.address0)).to.equal(1);
    expect(await pool.getOfferedCurrencyDecimals(_.address0)).to.equal(100);
  });

  // Set token conversion rate
  // 0x0000000000000000000000000000000000000000
  it("Should return correct USDT token conversion rate", async () => {
    await pool.setOfferCurrencyRateAndDecimals(USDTToken.address, 1, 100);
    expect(await pool.getOfferedCurrencyRate(USDTToken.address)).to.equal(1);
    expect(await pool.getOfferedCurrencyDecimals(USDTToken.address)).to.equal(100);
  });

  it("Should return correct USDC token conversion rate", async () => {
    await pool.setOfferCurrencyRateAndDecimals(USDCToken.address, 1, 100);
    expect(await pool.getOfferedCurrencyRate(USDCToken.address)).to.equal(1);
    expect(await pool.getOfferedCurrencyDecimals(USDCToken.address)).to.equal(100);
  });

  it("Should return correct USDC & USDT token conversion rate", async () => {
    await pool.setOfferCurrencyRateAndDecimals(USDTToken.address, 2, 200);
    await pool.setOfferCurrencyRateAndDecimals(USDCToken.address, 1, 100);

    expect(await pool.getOfferedCurrencyRate(USDTToken.address)).to.equal(2);
    expect(await pool.getOfferedCurrencyDecimals(USDTToken.address)).to.equal(200);
    expect(await pool.getOfferedCurrencyRate(USDCToken.address)).to.equal(1);
    expect(await pool.getOfferedCurrencyDecimals(USDCToken.address)).to.equal(100);
  });

  it("Should Verify Signature success", async () => {
    const maxAmount = _.amountTokenOfPool;
    const signature = await getBuySignature(buyer.address, maxAmount, 0);
    const verify = await pool.verify(owner.address, buyer.address, maxAmount, 0, signature);
    expect(verify).to.true;
  });

  // Should claim correctly
  it("Buy by ETH and Claim correct value for Claim functions", async () => {
    const maxAmount = _.amountTokenOfPool;
    const buyerAddress = buyer.address;
    const amountBuyEther = Helper.parseEther("10");
    let walletBalance = await wallet.getBalance();
    await pool.setOfferCurrencyRateAndDecimals(_.address0, 100, 0);

    const signature = await getBuySignature(buyerAddress, maxAmount, 0);
    await pool.connect(buyer).buyTokenByEtherWithPermission(buyerAddress, buyerAddress, maxAmount, 0, signature, {
      value: amountBuyEther,
    });

    let block = await getCurrentBlock();
    let blockTimestamp = await getBlockTimestamp(block);
    await pool.setCloseTime(Math.floor(blockTimestamp + 10));
    await time.advanceBlockTo((await getCurrentBlock()) + 10);

    expect(await wallet.getBalance()).to.equal(walletBalance.add(amountBuyEther));

    const totalUnclaim = await pool.totalUnclaimed();

    const claimAmount200 = Helper.parseEther("20");

    const claimSignature200 = await getClaimSignature(buyerAddress, claimAmount200);

    await pool.connect(buyer).claimTokens(buyerAddress, claimAmount200, claimSignature200);
    const newTotalUnClaim = await pool.totalUnclaimed();

    expect(await idoToken.balanceOf(buyerAddress)).to.equal(claimAmount200);
    expect(newTotalUnClaim).to.equal(totalUnclaim.sub(claimAmount200));
  });

  it("Buy by Token and Claim correct value for Claim functions", async () => {
    const buyerAddress = buyer.address;

    await pool.setOfferCurrencyRateAndDecimals(USDCToken.address, 10, 18);

    const maxAmount = Helper.mulDecimal("10000000", 18);
    const signature = await getBuySignature(buyerAddress, maxAmount, 0);
    const buyAmount = Helper.mulDecimal("100000", 18);
    console.log("==> buy amount: ", buyAmount);
    await USDCToken.connect(buyer).approve(pool.address, buyAmount);
    expect(await USDCToken.allowance(buyerAddress, pool.address)).to.equal(buyAmount);
 

    await pool.connect(buyer).buyTokenByTokenWithPermission(buyerAddress, USDCToken.address, buyAmount, buyerAddress, maxAmount, 0, signature);

    // let block = await getCurrentBlock();
    // let blockTimestamp = await getBlockTimestamp(block);
    // await pool.setCloseTime(Math.floor(blockTimestamp + 10));
    // await time.advanceBlockTo((await getCurrentBlock()) + 10);

  });

  // Should refund remain token correctly
  it("Refund remaining token", async () => {});

  const getBuySignature = async (buyerAddress, maxAmount, minAmount) => {
    const hash = await pool.getMessageHash(buyerAddress, maxAmount, minAmount);
    const signature = await web3.eth.sign(hash, owner.address);
    return signature;
  };

  async function getClaimSignature(address, amount) {
    // call to contract with parameters
    const hash = await pool.getClaimMessageHash(address, amount);
    // Sign this message hash with private key and account address
    const signature = await web3.eth.sign(hash, owner.address);
    return signature;
  }

  async function getCurrentBlock() {
    return await ethers.provider.getBlockNumber();
  }

  async function getBlockTimestamp(number) {
    let block = await ethers.provider.getBlock(number);
    return block.timestamp;
  }
});
