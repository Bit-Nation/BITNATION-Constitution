pragma solidity ^0.4.13;

import "ds-test/test.sol";
import "./StakeToken.sol";

// We only check the new functions, basic ones are already tested by zeppelin


contract TokenUser {
    StakeToken  token;

    function TokenUser(StakeToken STKtoken) {
        token = STKtoken;
    }

    function doTransfer(address to, uint amount) returns (bool)
    {
        return token.transfer(to, amount);
    }
}

contract TestStakeToken is DSTest {

    StakeToken token;

    // token will be instantiated before each test case
    function setUp() {
        token = new StakeToken();

        // Allocate a few tokens
        token.addBalance(this, 100);
    }

    function testFail_shouldBeUntradeableByDefault() {
        // Must throw on attempts to transfer
        token.transfer(0x1, 10);
    }

    function test_shouldIncrementBalance() {
        TokenUser user = new TokenUser(token);

        token.addBalance(user, 10);

        assert(token.balanceOf(user) == 10);
    }

    function test_shouldEmptyBalance() {
        token.emptyBalance(this);

        assert(token.balanceOf(this) == 0);
    }

    function test_shouldSubBalance() {
        token.subBalance(this, 10);

        assert(token.balanceOf(this) == 90);
    }

    function testFail_shouldNotSubBalanceIfBelowZero() {
        token.subBalance(this, 200);
    }
}
