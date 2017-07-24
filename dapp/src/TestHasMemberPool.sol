pragma solidity ^0.4.13;

import "ds-test/test.sol";
import "./HasMemberPool.sol";


contract User {
    HasMemberPool memberPool;

    function User(HasMemberPool pool) {
        memberPool = pool;
    }

    function apply() {
        memberPool.applyForMembership();
    }

    function cancelApplication() {
        memberPool.cancelMyApplication();
    }

    function cancelMembership() {
        memberPool.cancelMyMembership();
    }
}

contract TestHasMemberPool is DSTest {

    HasMemberPool pool;
    User user;

    // token will be instantiated before each test case
    function setUp() {
        pool = new HasMemberPool();
        user = new User(pool);
    }

    function test_ownerShouldBeMember() {
        assert(pool.hasMembership(this));
    }

    function test_canApply() {
        user.apply();

        assert(pool.hasPendingApplication(user));
    }

    function testFail_cannotApplyTwice() {
        user.apply();
        user.apply();
    }

    function testFail_cannotApplyIfMember() {
        user.apply();
        pool.acceptApplication(user);
        user.apply();
    }

    function test_acceptApplication() {
        user.apply();
        pool.acceptApplication(user);

        assert(pool.hasMembership(user));
        assert(!pool.hasPendingApplication(user));
    }

    function testFail_cannotAcceptNonExistantApplication() {
        pool.acceptApplication(user);
    }

    function test_refuseApplication() {
        user.apply();
        pool.refuseApplication(user);

        assert(!pool.hasPendingApplication(user));
    }

    function test_cancelItsApplication() {
        user.apply();
        user.cancelApplication();

        assert(!pool.hasPendingApplication(user));
    }

    function testFail_cannotRefuseUnexistingApplication() {
        pool.refuseApplication(user);
    }    

    function test_cancelMembership() {
        user.apply();
        pool.acceptApplication(user);

        pool.cancelMembership(user);

        assert(!pool.hasMembership(user));
    }

    function test_cancelItsMembership() {
        user.apply();
        pool.acceptApplication(user);
        user.cancelMembership();

        assert(!pool.hasMembership(user));
    }

    function testFail_cannotCancelUnexistingMembership() {
        pool.cancelMembership(user);
    }
}
