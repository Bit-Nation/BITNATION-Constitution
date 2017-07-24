pragma solidity ^0.4.13;

// TODO: make that upgradeable

import "./StakeToken.sol";
import "./Constitution.sol";
import "./HasMemberPool.sol";

import "zeppelin/contracts/ownership/Ownable.sol";

// The following contract implements a basic DBVN, with the main requirements
// A DBVN controls a constitution and the untradeable by default stake token
// It is controlled by members having a stake, which can vote on proposals.
// Any member (even if they have no stakes) can submit or execute proposals.
// The owner of he DBVN can be set to the DBVN itself.


contract BasicDBVN is Ownable, HasMemberPool {
    uint public minimumQuorum;
    uint public debatingPeriod;

    uint public maximumGas; // Let's not do a new theDAO

    Proposal[] public proposals;
    uint public numberOfProposals;

    // The ERC20 token is used as shares
    StakeToken public sharesToken;

    Constitution public constitution;

    event ProposalAdded(uint indexed proposalID, bytes32 transactionBytecode, string description);
    event ProposalTallied(uint indexed proposalID, uint result, uint quorum, bool active);

    event Voted(uint indexed proposalID, indexed uint voteID, bool indexed inSupport, indexed address voter);

    event ChangeOfRules(uint minimumQuorum, uint debatingPeriodInMinutes);
    event SettingsChanged(uint maximumGas);

    event Deposit(address indexed sender, uint indexed value);

    struct Proposal {
        address submitter;

        address recipient;
        uint amount;

        uint votingDeadline;

        bool executed;
        bool executionSuccess; // Used to log if we succeed executing the proposal
        bool proposalPassed;

        bytes32 proposalHash;

        uint numberOfVotes;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }

    modifier onlyShareholders {
        require(sharesToken.balanceOf(msg.sender) != 0);
        _;
    }

    modifier max_gas(uint maximum) {
        uint initial = msg.gas;
        _;
        assert(initial - msg.gas < maximum);
    }

    function BasicDBVN(uint minimumSharesToPassAVote, uint minutesForDebate, uint initialShares, uint maxGas) {
        // We deploy the token representing the stakes of members
        sharesToken = new StakeToken();
        sharesToken.addBalance(msg.sender, initialShares);

        constitution = new Constitution();

        
        minimumQuorum = minimumSharesToPassAVote;
        debatingPeriod = minutesForDebate;
        maximumGas = maxGas;
    }

    function changeVotingRules(uint minimumSharesToPassAVote, uint minutesForDebate) onlyOwner {
        require(minimumSharesToPassAVote > 0);
        minimumQuorum = minimumSharesToPassAVote;
        debatingPeriod = minutesForDebate * 1 minutes;

        ChangeOfRules(minimumSharesToPassAVote, minutesForDebate);
    }

    function setSettings(uint maxGas) onlyOwner {
        maximumGas = maxGas;

        SettingsChanged(maximumGas);
    }

    function newProposal(address beneficiary, uint etherAmount, string jobDescription, bytes32 transactionBytecode) onlyMembers returns (uint proposalID) {
        proposalID = proposals.length++;

        Proposal p = proposals[proposalID];
        p.submitter = msg.sender;
        p.recipient = beneficiary;
        p.amount = etherAmount;
        p.proposalHash = sha3(beneficiary, etherAmount, transactionBytecode);
        p.votingDeadline = now + debatingPeriod;

        numberOfProposals += 1;

        ProposalAdded(proposalID, transactionBytecode, jobDescription);
    }

    function checkProposalCode(uint proposalNumber, bytes32 transactionBytecode) constant returns (bool hashIsValid) {
        Proposal p = proposals[proposalNumber];
        hashIsValid = p.proposalHash == sha3(p.recipient, p.amount, transactionBytecode);
    }

    function vote(uint proposalNumber, bool inFavorOfProposal) onlyShareholders returns (uint voteID) {
        Proposal p = proposals[proposalNumber];

        require(!p.executed);
        require(!p.voted[msg.sender]);

        voteID = p.votes.length++;
        p.votes[voteID] = Vote({inSupport: inFavorOfProposal, voter: msg.sender});
        p.voted[msg.sender] = true;
        p.numberOfVotes += 1;

        Voted(proposalNumber, voteID, inFavorOfProposal, msg.sender);
    }

    function getVote(uint proposalNumber, uint voteId) constant returns (bool inSupport, address voter) {
        inSupport = proposals[proposalNumber].votes[voteId].inSupport;
        voter = proposals[proposalNumber].votes[voteId].voter;
    }

    // Gas is limited to avoid reentrancy
    function executeProposal(uint proposalNumber, bytes32 transactionBytecode) onlyMembers max_gas(maximumGas) {
        // First, check a few things
        require(checkProposalCode(proposalNumber, transactionBytecode));

        Proposal p = proposals[proposalNumber];

        require(p.votingDeadline <= now);
        require(!p.executed);

        // Time to tally the votes
        uint quorum = 0;
        uint yea = 0;
        uint nay = 0;

        for (uint i = 0; i < p.votes.length; ++i) {
            Vote memory v = p.votes[i];
            uint voteWeight = sharesToken.balanceOf(v.voter);
            quorum += voteWeight;
            if (v.inSupport) {
                yea += voteWeight;
            } else {
                nay += voteWeight;
            }
        }

        // Execute result

        // Not enough voters
        assert(quorum >= minimumQuorum);

        p.executed = true;

        if (yea > nay ) {
            // Approved
            p.proposalPassed = true;
            if (p.recipient.call.value(p.amount * 1 ether)(transactionBytecode)) {
                p.executionSuccess = true;
            }
        }

        // Fire Events
        ProposalTallied(proposalNumber, yea - nay, quorum, p.proposalPassed);
    }

    function () payable {
        require(msg.value > 0);
        // Log the fact someone deposited ETH so you can buy him a beer or something else
        Deposit(msg.sender, msg.value);
    }
}
