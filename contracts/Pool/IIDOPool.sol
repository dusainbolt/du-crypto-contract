// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIDOPool {
    function initialize(
        address _token,
        uint256 _duration,
        uint256 _openTime,
        address _offeredCurrency,
        uint256 _offeredRate,
        uint256 _offeredCurrencyDecimals,
        address _wallet,
        address _singer
    ) external;
}
