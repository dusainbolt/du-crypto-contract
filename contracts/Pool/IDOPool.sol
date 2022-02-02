// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IDOPool is Pausable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct OfferedCurrency {
        uint256 decimals;
        uint256 rate;
    }

    // Token being sold
    IERC20 public token;

    // Address of factory contract
    address public factory;

    // Address of singer account
    address public singer;

    // Address where funds are collected
    address public fundingWallet;

    // Time when token is opened to sell
    uint256 public openTime;

    // Time When token is closed to sell
    uint256 public closeTime;

    // Amount of wei is raised
    uint256 public weiRaised = 0;

    // Amount of token sold
    uint256 public tokenSold = 0;

    // Total token who each user purchased
    mapping(address => uint256) public userPurchased;

    // Get offer currency
    mapping(address => OfferedCurrency) public offeredCurrencies;

    // Pool extensions
    bool public useWhitelist = true;

    // Event of IDO pool
    event PoolCreated(
        address token,
        uint256 openTime,
        uint256 closeTime,
        address offeredCurrency,
        uint256 offeredCurrencyDecimals,
        uint256 offeredCurrencyRate
    );
    event TokenPurchaseByEther(
        address indexed purchaser,
        address indexed beneficiary,
        address value,
        uint256 amount
    );
    event TokenPurchaseByToken(
        address indexed purchaser,
        address indexed beneficiary,
        address token,
        address value,
        uint256 amount
    );
    event RefundedICOToken(address wallet, uint256 amount);
    event PoolStatsChanged();

    // constructor();
}
