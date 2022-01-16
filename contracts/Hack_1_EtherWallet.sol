pragma solidity ^0.8.0;

contract EtherStore {
  mapping(address => uint) public balances;

  // Send Ether to contract
  function deposit() public payable {
    balances[msg.sender] += msg.value;
  }

  // withdraw by user
  function withdraw() public {
    uint bal = balances[msg.sender];
    require(bal > 0, "You don't have balance");
    // Send Ether to sender
    (bool sent, ) = msg.sender.call{value: bal}("");
    require(sent, "Send Ether fail");
    
    balances[msg.sender] = 0;
  }

  // get balance of contract
  function getBalance() public view returns(uint){
    return address(this).balance;
  }
}