// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StableToken is ERC20 {
    uint8 private decimal;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, 10000000 * 10**_decimal);
        _setDecimal(_decimal);
    }

    function decimals() public view virtual override(ERC20) returns (uint8) {
        return decimal;
    }

    function _setDecimal(uint8 _decimal) internal {
        decimal = _decimal;
    }
}
