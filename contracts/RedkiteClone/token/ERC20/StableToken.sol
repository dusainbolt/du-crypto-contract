// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StableToken is ERC20 {
    // uint256 private decimals2;
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _mint(msg.sender, 10000000 * 10** decimals());
    }

    // function decimals() public view virtual override returns (uint8) {
    //     return 2;
    // }
}
