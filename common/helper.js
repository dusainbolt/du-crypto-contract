const { ethers } = require('hardhat');

class Helper {
  static convertWeiToEther = value => {
    return ethers.utils.formatEther(value);
  };
  static getAccBalanceEther = async account => {
    const balance = await account.getBalance();
    return Helper.convertWeiToEther(balance);
  };
}

module.exports = Helper;
