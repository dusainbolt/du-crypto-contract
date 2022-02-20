// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./ERC20Mintable.sol";

contract ERC20Token is ERC20Burnable, ERC20Mintable {
    uint8 private decimal;

    constructor(
        string memory name_,
        string memory symbol_,
        address owner,
        uint256 totalSupply,
        uint8 _decimal
    ) ERC20(name_, symbol_) {
        _mint(owner, totalSupply);
        _setDecimal(_decimal);
    }

    function decimals() public view virtual override(ERC20) returns (uint8) {
        return decimal;
    }

    function _setDecimal(uint8 _decimal) internal {
        decimal = _decimal;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
