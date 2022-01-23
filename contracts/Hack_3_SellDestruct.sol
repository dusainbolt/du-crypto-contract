// SPDX-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherGame {
    uint256 public targetAmount = 7 ether;
    address public winner;
    // comment for preventative
    uint256 public balance;


    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() public payable {
        require(msg.value == 1 ether, "You can send only 1 ether");
        // comment for preventative
        // uint256 balance = getBalance();
        balance += msg.value;

        require(balance <= targetAmount, "Game is over");

        if (balance == targetAmount) {
            winner = msg.sender;
        }
    }

    function claimReward() public {
        require(msg.sender == winner, "You're not winner");
        (bool sent, ) = msg.sender.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
}

contract AttackEtherGame {
  EtherGame etherGame;

  fallback() external payable {}

  constructor(address _etherGameAddress) {
    etherGame = EtherGame(_etherGameAddress);
  }

  function attack() public  {
    address payable addr = payable(address(etherGame));
    selfdestruct(addr);
  }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

}