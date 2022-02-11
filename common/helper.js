const { ethers } = require('hardhat');

// const BigNumber = ethers.BigNumber;
class Helper {
  static formatEther = value => {
    return ethers.utils.formatEther(value);
  };
  static parseEther = value => {
    return ethers.utils.parseEther(value);
  };
  static getAccBalanceEther = async account => {
    const balance = await account.getBalance();
    return Helper.formatEther(balance);
  };
  static mulDecimal = (number = 0, decimal = 18) => {
    return ethers.utils.parseUnits(number?.toString(), decimal)
    //  BigNumber.from(number).mul(BigNumber.from(10).pow(decimal));
  }
}

module.exports = Helper;
