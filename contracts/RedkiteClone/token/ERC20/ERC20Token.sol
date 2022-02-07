// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./ERC20Mintable.sol";

contract ERC20Token is ERC20Burnable, ERC20Mintable {
    constructor (
        string memory name_,
        string memory symbol_,
		    address owner,
        uint256 totalSupply
    ) ERC20(name_, symbol_) {
        _mint(owner, totalSupply);
    }
    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 amount
    // ) internal virtual override(ERC20) {
    //     super._beforeTokenTransfer(from, to, amount);
    // }
}