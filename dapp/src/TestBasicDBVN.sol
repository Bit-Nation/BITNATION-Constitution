pragma solidity ^0.4.13;

import "ds-test/test.sol";
import "./BasicDBVN.sol";

import "./StakeToken.sol";
import "./Constitution.sol";

// TODO: test events
// TODO: test modifiers


contract User {
    BasicDBVN dbvn;

    function User(BasicDBVN dbvnContract) {
        dbvn = dbvnContract;
    }

    function apply() {
        dbvn.applyForMembership();
    }

    function newProposal(address to, uint amount, string description, bytes32 bytecode) returns (uint) {
        return dbvn.newProposal(to, amount, description, bytecode);
    }

    function vote(uint id) returns (uint) {
        // It's a dumb member, it always vote the same thing
        return dbvn.vote(id, false);
    }

    function execute(uint id, bytes32 code) {
        dbvn.executeProposal(id, code);
    }
}

contract TestBasicDBVNn is DSTest {

    BasicDBVN dbvn;
    User member;

    // token will be instantiated before each test case
    function setUp() {
        StakeToken token = new StakeToken();
        Constitution const = new Constitution();

        dbvn = new BasicDBVN(0, 0, 100, 150000, token, const);
        token.addBalance(address(this), 100);

        token.transferOwnership(address(dbvn));
        const.transferOwnership(address(dbvn));

        member = new User(dbvn);

        member.apply();
        dbvn.acceptApplication(member);
    }

    function test_shouldBeOwner() {
        assert(dbvn.owner() == address(this));
    }

    function test_shouldBeMember() {
        assert(dbvn.hasMembership(address(this)));
    }

    function test_changeConstitution() {
        Constitution const = new Constitution();
        dbvn.changeConstitution(const);

        assert(dbvn.constitution() == const);
    }

    function test_changeToken() {
        StakeToken token = new StakeToken();
        dbvn.changeToken(token);

        assert(dbvn.sharesToken() == token);
    }

    function test_changeVotingRules() {
        dbvn.changeVotingRules(10, 60);

        assert(dbvn.minimumQuorum() == 10);
        assert(dbvn.debatingPeriod() == 60 * 1 minutes);
    }

    function test_setSettings() {
        dbvn.setSettings(10);

        assert(dbvn.maximumGas() == 10);
    }

    function test_addProposal() {
        assert(member.newProposal(0x0, 0, "test 1", 0x0) == 0);
        assert(member.newProposal(0x1, 1, "test 2", 0x1) == 1);

        assert(dbvn.numberOfProposals() == 2);

        var (submitter, recipient, amount, votingDeadline, executed, executionSuccess, proposalPassed, , numberOfVotes,) = dbvn.proposals(1);

        assert(submitter == address(member));
        assert(recipient == 0x1);
        assert(amount == 1);
        assert(votingDeadline > 0);
        assert(executed == false);
        assert(executionSuccess == false);
        assert(proposalPassed == false);
        assert(numberOfVotes == 0);
    }

    function testFail_addProposalNotMember() {
        User user = new User(dbvn);

        user.newProposal(0x1, 1, "should fail", 0x0);
    }

    function test_checkProposalCode() {
        assert(member.newProposal(0x0, 0, "test 1", 0x0) == 0);

        assert(dbvn.checkProposalCode(0, 0x0));
    }

    function test_voteForProposal() {
        assert(dbvn.newProposal(0x0, 0, "test 1", 0x0) == 0);

        assert(dbvn.vote(0, true) == 0);

        var (support, voter) = dbvn.getVote(0, 0);

        assert(support == true);
        assert(voter == address(this));

        var (submitter, recipient, amount, votingDeadline, executed, executionSuccess, proposalPassed, , numberOfVotes,)  = dbvn.proposals(0);

        assert(numberOfVotes == 1);
    }

    function testFail_voteTwice() {
        assert(dbvn.newProposal(0x0, 0, "test 1", 0x0) == 0);

        assert(dbvn.vote(0, true) == 0);
        assert(dbvn.vote(0, true) == 0);
    }

    function testFail_voteForUnknownProposal() {
        assert(dbvn.vote(42, true) == 0);
    }

    function testFail_voteNotShareholder() {
        member.vote(42);
    }

    function testFail_executeTwice() {
        assert(dbvn.newProposal(0x0, 0, "test 1", 0x0) == 0);
        assert(dbvn.vote(0, true) == 0);

        dbvn.executeProposal(0, 0x0);
        dbvn.executeProposal(0, 0x0);
    }

    function test_execute() {
        assert(dbvn.newProposal(0x0, 0, "test 1", 0x0) == 0);
        assert(dbvn.vote(0, true) == 0);

        member.execute(0, 0x0);

        var (submitter, recipient, amount, votingDeadline, executed, executionSuccess, proposalPassed, , numberOfVotes,) = dbvn.proposals(0);

        assert(executed);
        assert(proposalPassed);
    }

    function testFail_executeWrongCode() {
        assert(dbvn.newProposal(0x0, 0, "test 1", 0x0) == 0);
        assert(dbvn.vote(0, true) == 0);

        dbvn.executeProposal(0, 0x42);
    }

    function testFail_executeSubDeadline() {
        // We need to increase the deadline
        dbvn.changeVotingRules(0, 60);

        assert(dbvn.newProposal(0x0, 0, "test 1", 0x0) == 0);
        assert(dbvn.vote(0, true) == 0);

        dbvn.executeProposal(0, 0x0);
    }

    function testFail_executeNotMember() {
        assert(dbvn.newProposal(0x0, 0, "test 1", 0x0) == 0);
        assert(dbvn.vote(0, true) == 0);

        User user = new User(dbvn);

        user.execute(0, 0x0);
    }

    function testFail_subQuorum() {
        // Increase minimumQuorum
        dbvn.changeVotingRules(50, 0);
        assert(dbvn.newProposal(0x0, 0, "test 1", 0x0) == 0);
        // We do not vote so proposal get no quorum

        dbvn.executeProposal(0, 0x0);
    }
}
