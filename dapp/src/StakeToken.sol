pragma solidity ^0.4.11;

import "zeppelin/contracts/ownership/Ownable.sol";
import "zeppelin/contracts/token/PausableToken.sol";


// That token represents the stake of each member
// By default it is untradeable
// The DBVN is the owner, it decides what balance the members should have


contract StakeToken is Ownable, PausableToken {
  string public name = "Stake Token";
  string public symbol = "%";
  uint public decimals = 18;

  function StakeToken() {
    // By default, token is untradeable
    paused = true;
  }

  function addBalance(address member, uint value) onlyOwner {
    totalSupply = totalSupply.add(value);

    balances[member] = balances[member].add(value);

    Transfer(this, member, value);
  }

  function subBalance(address member, uint value) onlyOwner {
    //require(totalSupply.sub(value) >= 0);
    //require(balances[member].sub(value) >= 0);

    totalSupply = totalSupply.sub(value);

    balances[member] = balances[member].sub(value);

    Transfer(member, this, value);
  }

  function emptyBalance(address member) onlyOwner {
    uint balance = balanceOf(member);
    subBalance(member, balance);
  }
}
