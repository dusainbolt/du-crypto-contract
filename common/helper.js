const { ethers } = require('hardhat');

const BigNumber = ethers.BigNumber;
class Helper {
  static convertWeiToEther = value => {
    return ethers.utils.formatEther(value);
  };
  static getAccBalanceEther = async account => {
    const balance = await account.getBalance();
    return Helper.convertWeiToEther(balance);
  };
  static mulDecimal = (number = 0, decimal = 18) => {
    return BigNumber.from(number).mul(BigNumber.from(10).pow(decimal));
  }
}

module.exports = Helper;
