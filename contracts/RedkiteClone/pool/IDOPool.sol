// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Pausable.sol";
import "../libraries/Verify.sol";
import "hardhat/console.sol";

contract IDOPool is Pausable, ReentrancyGuard, Verify {
    using SafeMath for uint256;

    struct OfferedCurrency {
        uint256 decimals;
        uint256 rate;
    }

    // The token being sold
    IERC20 public token;

    // The address of factory contract
    address public factory;

    // Address where funds are collected
    address public fundingWallet;

    // Timestamps when token started to sell
    uint256 public openTime = block.timestamp;

    // Timestamps when token stopped to sell
    uint256 public closeTime;

    // Amount of wei raised
    uint256 public weiRaised = 0;

    // Amount of token sold
    uint256 public tokenSold = 0;

    // Amount of token sold
    uint256 public totalUnclaimed = 0;

    // Number of token user purchased
    mapping(address => uint256) public userPurchased;

    // Number of token user claimed
    mapping(address => uint256) public userClaimed;

    // Number of token user purchased
    mapping(address => mapping(address => uint256)) public investedAmountOf;

    // Get offered currencies
    mapping(address => OfferedCurrency) public offeredCurrencies;

    // Pool extensions
    bool public useWhitelist = true;

    // -----------------------------------------
    // Lauchpad Starter's event
    // -----------------------------------------
    event PoolCreated(
        address token,
        uint256 openTime,
        uint256 closeTime,
        address offeredCurrency,
        uint256 offeredCurrencyDecimals,
        uint256 offeredCurrencyRate,
        address wallet,
        address owner
    );
    event TokenPurchaseByEther(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );
    event TokenPurchaseByToken(
        address indexed purchaser,
        address indexed beneficiary,
        address token,
        uint256 value,
        uint256 amount
    );
    event TokenClaimed(address user, uint256 amount);
    event RefundedIcoToken(address wallet, uint256 amount);
    event PoolStatsChanged();

    // -----------------------------------------
    // Constructor
    // -----------------------------------------
    constructor() {
        factory = msg.sender;
    }

    // -----------------------------------------
    // Red Kite external interface
    // -----------------------------------------

    /**
     * @dev fallback function
     */
    fallback() external {
        revert();
    }

    /**
     * @dev fallback function
     */
    receive() external payable {
        revert();
    }

    function initialize(
        address _token,
        uint256 _duration,
        uint256 _openTime,
        address _offeredCurrency,
        uint256 _offeredRate,
        uint256 _offeredCurrencyDecimals,
        address _wallet
    ) external {
        require(msg.sender == factory, "POOL:UNAUTHORIZED");

        token = IERC20(_token);
        openTime = _openTime;
        closeTime = openTime.add(_duration);
        fundingWallet = _wallet;
        _transferOwnership(tx.origin);
        paused = false;
        offeredCurrencies[_offeredCurrency] = OfferedCurrency({
            rate: _offeredRate,
            decimals: _offeredCurrencyDecimals
        });

        emit PoolCreated(
            _token,
            _openTime,
            closeTime,
            _offeredCurrency,
            _offeredCurrencyDecimals,
            _offeredRate,
            _wallet,
            owner
        );
    }

    /**
     * @notice Returns the conversion rate when user buy by offered token
     * @return Returns only a fixed number of rate.
     */
    function getOfferedCurrencyRate(address _token)
        public
        view
        returns (uint256)
    {
        return offeredCurrencies[_token].rate;
    }

    /**
     * @notice Returns the conversion rate decimals when user buy by offered token
     * @return Returns only a fixed number of decimals.
     */
    function getOfferedCurrencyDecimals(address _token)
        public
        view
        returns (uint256)
    {
        return offeredCurrencies[_token].decimals;
    }

    /**
     * @notice Return the available tokens for purchase
     * @return availableTokens Number of total available
     */
    function getAvailableTokensForSale() public view returns (uint256) {
        return token.balanceOf(address(this)).sub(totalUnclaimed);
    }

    function setOfferCurrencyRateAndDecimals(
        address _token,
        uint256 _rate,
        uint256 _decimals
    ) external onlyOwner {
        offeredCurrencies[_token].rate = _rate;
        offeredCurrencies[_token].decimals = _decimals;
        emit PoolStatsChanged();
    }

    function setCloseTime(uint256 _closeTime) external onlyOwner {
        require(_closeTime >= block.timestamp, "POOL:INVALID_TIME");
        closeTime = _closeTime;
        emit PoolStatsChanged();
    }

    function setOpenTime(uint256 _openTime) external onlyOwner {
        require(_openTime < closeTime, "POOL:OPENTIME_MUST_BE_SMALLER_THAN_CLOSETIME");
        openTime = _openTime;
        emit PoolStatsChanged();
    }

    /**
     * @notice Owner can set extentions.
     * @param _whitelist Value in bool. True if using whitelist
     */
    function setPoolExtentions(bool _whitelist) external onlyOwner {
        useWhitelist = _whitelist;
        emit PoolStatsChanged();
    }

    function buyTokenByEtherWithPermission(
        address _beneficiary,
        address _candidate,
        uint256 _maxAmount,
        uint256 _minAmount,
        bytes memory _signature
    ) public payable whenNotPaused nonReentrant {
        uint256 weiAmount = msg.value;

        require(
            offeredCurrencies[address(0)].rate != 0,
            "POOL::PURCHASE_METHOD_NOT_ALLOW"
        );
        _preValidatePurchase(_beneficiary, weiAmount);

        require(_validPurchase(), "POOL::ENDED");
        require(
            _verifyWhitelist(_candidate, _maxAmount, _minAmount, _signature),
            "POOL:INVALID_SIGNATURE"
        );

        // caculate token amount to created
        uint256 tokens = _getOfferedCurrencyToTokenAmount(
            address(0),
            weiAmount
        );

        require(
            getAvailableTokensForSale() >= tokens,
            "POOL::NOT_ENOUGHT_TOKENS_FOR_SALE"
        );

        uint256 amountPurchased = userPurchased[msg.sender].add(tokens);

        require(tokens >= _minAmount, "POOL:MINT_AMOUNT_UNREACHED");
        require(
            amountPurchased <= _maxAmount,
            "POOL:PURCHASE_AMOUNT_OVER_TO_LIMIT"
        );

        _forwardFunds(weiAmount);
        _updatePurchasingState(weiAmount, tokens);

        investedAmountOf[address(0)][_candidate] = investedAmountOf[address(0)][
            _candidate
        ].add(weiAmount);

        emit TokenPurchaseByEther(msg.sender, _beneficiary, weiAmount, tokens);
    }

    function buyTokenByTokenWithPermission(
        address _beneficiary,
        address _token,
        uint256 _amount,
        address _candidate,
        uint256 _maxAmount,
        uint256 _minAmount,
        bytes memory _signature
    ) public payable whenNotPaused nonReentrant {
        require(
            offeredCurrencies[_token].rate != 0,
            "POOL::PURCHASE_METHOD_NOT_ALLOW"
        );
        _preValidatePurchase(_beneficiary, _amount);

        require(_validPurchase(), "POOL::ENDED");
        require(
            _verifyWhitelist(_candidate, _maxAmount, _minAmount, _signature),
            "POOL:INVALID_SIGNATURE"
        );

        // _verifyAllowance(msg.sender, _token, _amount);

        // caculate token amount to created
        uint256 tokens = _getOfferedCurrencyToTokenAmount(_token, _amount);
        require(
            getAvailableTokensForSale() >= tokens,
            "POOL::NOT_ENOUGHT_TOKENS_FOR_SALE"
        );

        uint256 amountPurchased = userPurchased[msg.sender].add(tokens);
        require(tokens >= _minAmount, "POOL:MINT_AMOUNT_UNREACHED");
        require(
            amountPurchased <= _maxAmount,
            "POOL:PURCHASE_AMOUNT_OVER_TO_LIMIT"
        );

        _forwardTokenFunds(_token, _amount);
        _updatePurchasingState(_amount, tokens);

        investedAmountOf[_token][_candidate] = investedAmountOf[address(0)][
            _candidate
        ].add(_amount);

        emit TokenPurchaseByToken(
            msg.sender,
            _beneficiary,
            _token,
            _amount,
            tokens
        );
    }

    function refundRemainingTokens(address _wallet)
        external
        onlyOwner
        isFinalized
    {
        require(token.balanceOf(address(this)) > 0, "POOL::ICO_NOT_ENDED");
        uint256 remainingTokens = getAvailableTokensForSale();

        _deliverTokens(_wallet, remainingTokens);
        emit RefundedIcoToken(_wallet, remainingTokens);
    }

    modifier isFinalized() {
        require(block.timestamp >= closeTime, "POOL::ICO_NOT_ENDED");
        _;
    }

    /**
     * @notice User can receive their tokens when pool finished
     */
    function claimTokens(
        address _candidate,
        uint256 _amount,
        bytes memory _signature
    ) public nonReentrant isFinalized {
        require(
            _verifyClaimToken(_candidate, _amount, _signature),
            "POOL:INVALID_SINGATURE_CLAIM"
        );
        require(
            _amount >= userClaimed[_candidate],
            "POOL:AMOUNT_MUST_GREATER_THAN_CLAIMED"
        );

        uint256 maxClaimAmount = userPurchased[_candidate].sub(
            userClaimed[_candidate]
        );

        uint256 claimAmount = _amount.sub(userClaimed[_candidate]);

        if (claimAmount > maxClaimAmount) {
            claimAmount = maxClaimAmount;
        }

        userClaimed[_candidate] = userClaimed[_candidate].add(claimAmount);

        _deliverTokens(msg.sender, claimAmount);

        totalUnclaimed = totalUnclaimed.sub(claimAmount);

        emit TokenClaimed(msg.sender, claimAmount);
    }

    /**
     * @param _tokens Value of sold tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(uint256 _weiAmount, uint256 _tokens)
        internal
    {
        tokenSold = tokenSold.add(_tokens);
        weiRaised = weiRaised.add(_weiAmount);
        userPurchased[msg.sender] = userPurchased[msg.sender].add(_tokens);
        totalUnclaimed = totalUnclaimed.add(_tokens);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds(uint256 _value) internal {
        address payable wallet = payable(fundingWallet);
        (bool sent, ) = wallet.call{value: _value}("");
        require(sent, "POOL::WALLET_TRANSFER_FAILED");
    }

    /**
     * @dev Determines how Token is stored/forwarded on purchases.
     */
    function _forwardTokenFunds(address _token, uint256 _amount) internal {
        IERC20(_token).transferFrom(msg.sender, fundingWallet, _amount);
    }

    /**
     * @dev Source of tokens, Transfer / mint
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of token to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        token.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _amount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getOfferedCurrencyToTokenAmount(address _token, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 rate = getOfferedCurrencyRate(_token);
        uint256 decimals = getOfferedCurrencyDecimals(_token);
        // console.log("====>rate %s", rate);
        // console.log("====>decimals %s", decimals);
        // console.log("====>_amount %s", _amount.mul(rate));
        return _amount.mul(rate).div(10**decimals);
    }

    /**

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        pure
    {
        require(_beneficiary != address(0), "POOL::INVALID_BENEFICIARY");
        require(_weiAmount != 0, "POOL::INVALID_WEI_AMOUNT");
    }

    // @return true if the transaction can buy tokens
    function _validPurchase() internal view returns (bool withinPeriod) {
        withinPeriod =
            block.timestamp >= openTime &&
            block.timestamp <= closeTime;
    }

    function _verifyWhitelist(
        address _candidate,
        uint256 _maxAmount,
        uint256 _minAmount,
        bytes memory signature
    ) private view returns (bool) {
        if (useWhitelist) {
            return
                verify(owner, _candidate, _maxAmount, _minAmount, signature);
        }
        return true;
    }

    /**
     * @dev Verify permission of purchase
     * @param _candidate Address of buyer
     * @param _amount claimable amount
     * @param _signature Signature of owners
     */
    function _verifyClaimToken(
        address _candidate,
        uint256 _amount,
        bytes memory _signature
    ) private view returns (bool) {
        require(msg.sender == _candidate, "POOL::WRONG_CANDIDATE");

        return (verifyClaimToken(owner, _candidate, _amount, _signature));
    }
}
