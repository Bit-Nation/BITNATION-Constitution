pragma solidity ^0.4.11;

contract ReentrancyAttack {

  function callSender(bytes4 data) {
    if(!msg.sender.call(data)) {
      throw;
    }
  }

}
