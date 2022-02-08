// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Pausable.sol";
import "../libraries/Verify.sol";

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

    // The address of signer account
    address public signer;

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

    // Number of token user purchased
    mapping(address => uint256) public userPurchased;

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

        uint256 amountPurchased = userPurchased[msg.sender].add(tokens);
        require(tokens >= _minAmount, "POOL:MINT_AMOUNT_UNREACHED");
        require(
            amountPurchased <= _maxAmount,
            "POOL:PURCHASE_AMOUNT_OVER_TO_LIMIT"
        );

        _deliverTokens(_beneficiary, tokens);
        _forwardTokens(weiAmount);
        _updatePurchasingState(weiAmount, tokens);
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

        _verifyAllowance(msg.sender, _token, _amount);

        // caculate token amount to created
        uint256 tokens = _getOfferedCurrencyToTokenAmount(_token, _amount);

        uint256 amountPurchased = userPurchased[msg.sender].add(tokens);
        require(tokens >= _minAmount, "POOL:MINT_AMOUNT_UNREACHED");
        require(
            amountPurchased <= _maxAmount,
            "POOL:PURCHASE_AMOUNT_OVER_TO_LIMIT"
        );

        _deliverTokens(_beneficiary, tokens);
        _forwardTokens(_amount);
        _updatePurchasingState(_amount, tokens);

        emit TokenPurchaseByToken(
            msg.sender,
            _beneficiary,
            _token,
            _amount,
            tokens
        );
    }

    function refundRemainingTokens(address _wallet, uint256 _amount)
        external
        onlyOwner
        isFinalized
    {
        require(token.balanceOf(address(this)) > 0, "POOL::ICO_NOT_ENDED");
        _deliverTokens(_wallet, _amount);
        emit RefundedIcoToken(_wallet, _amount);
    }

    modifier isFinalized() {
        require(block.timestamp >= closeTime, "POOL::ICO_NOT_ENDED");
        _;
    }

    function _verifyAllowance(
        address _user,
        address _token,
        uint256 _amount
    ) private view {
        IERC20 tradeToken = IERC20(_token);
        uint256 allowance = tradeToken.allowance(_user, address(this));
        require(allowance >= _amount, "POOL:TOKEN_NOT_APPROVE");
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
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardTokens(uint256 value) internal {
        address payable wallet = payable(fundingWallet);
        (bool sent, ) = wallet.call{value: value}("");
        require(sent, "POOL::WALLET_TRANSFER_ETHER_FAILED");
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
        userPurchased[_beneficiary] = userPurchased[_beneficiary].add(
            _tokenAmount
        );
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
                verify(signer, _candidate, _maxAmount, _minAmount, signature);
        }
        return true;
    }
}
