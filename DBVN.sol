/*

This is a first proposal contract code for the seed of the Bitnation DAO

File lincensed under WTFPL: http://www.wtfpl.net

*/

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

/* The token is used as a voting shares */
contract token { function mintToken(address target, uint256 mintedAmount);  }

contract DBVN is owned {

    /* Contract Variables and events */
    uint public rankThreshold;
    uint public debatingPeriodInMinutes;
    int public majorityMargin;
    Proposal[] public proposals;
    uint public numProposals;
    mapping (address => uint) public memberId;
    Member[] public members;
    string public constitutionURL;
    
    event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    event Voted(uint proposalID, bool position, address voter);
    event ProposalTallied(uint proposalID, int result, uint quorum, bool active);
    event MembershipChanged(address member);
    event ChangeOfRules(uint minimumQuorum, uint debatingPeriodInMinutes, int majorityMargin);

    struct Proposal {
        address recipient;
        uint amount;
        string description;
        uint waitingWindow;
        bool executed;
        bool proposalPassed;
        uint rankSum;
        int currentResult;
        bytes32 proposalHash;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Member {
        address member;
        uint rank;
        bool canAddProposals;
        string name;
        uint memberSince;
    }

    struct Vote {
        bool inSupport;
        address voter;
        string justification;
    }


    /* First time setup */
    function DBVN(string constitutionURL, uint totalRankNeededForDecisions, uint minutesForDebate, int marginOfVotesForMajority, address congressLeader) {
        rankThreshold = totalRankNeededForDecisions;
        debatingPeriodInMinutes = minutesForDebate;
        majorityMargin = marginOfVotesForMajority;
        members.length++;
        members[0] = Member({member: 0, rank: 0, canAddProposals: false, memberSince: now, name: ''});
        if (congressLeader != 0) owner = congressLeader;
        constitutionURL = constitutionURL;
    }

    /*make member*/
    function changeMembership(address targetMember, uint rank, bool canAddProposals, string memberName) onlyOwner {
        uint id;
        if (memberId[targetMember] == 0) {
           memberId[targetMember] = members.length;
           id = members.length++;
           members[id] = Member({member: targetMember, rank: rank, canAddProposals: canAddProposals, memberSince: now, name: memberName});
        } else {
            id = memberId[targetMember];
            Member m = members[id];
            m.rank = rank;
            m.canAddProposals = canAddProposals;
            m.name = memberName;
        }

        MembershipChanged(targetMember);

    }

    /*change rules*/
    function changeVotingRules(uint minimumQuorumForProposals, uint minutesForDebate, int marginOfVotesForMajority) onlyOwner {
        rankThreshold = minimumQuorumForProposals;
        debatingPeriodInMinutes = minutesForDebate;
        majorityMargin = marginOfVotesForMajority;

        ChangeOfRules(rankThreshold, debatingPeriodInMinutes, majorityMargin);
    }
    

    
    /* Function to create a new proposal */
    function newProposalInWei(address beneficiary, uint weiAmount, string JobDescription, bytes transactionBytecode) returns (uint proposalID) {
        if (memberId[msg.sender] == 0 || !members[memberId[msg.sender]].canAddProposals) throw;
        
        proposalID = proposals.length++;
        Proposal p = proposals[proposalID];
        p.recipient = beneficiary;
        p.amount = weiAmount;
        p.description = JobDescription;
        p.proposalHash = sha3(beneficiary, weiAmount, transactionBytecode);
        p.waitingWindow = now + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.rankSum = 0;
        ProposalAdded(proposalID, beneficiary, weiAmount, JobDescription);
        numProposals = proposalID+1;
    }
    
    /* Function to create a new proposal */
    function newProposalInEther(address beneficiary, uint etherAmount, string JobDescription, bytes transactionBytecode) returns (uint proposalID) {
        if (memberId[msg.sender] == 0 || !members[memberId[msg.sender]].canAddProposals) throw;
        
        proposalID = proposals.length++;
        Proposal p = proposals[proposalID];
        p.recipient = beneficiary;
        p.amount = etherAmount * 1 ether;
        p.description = JobDescription;
        p.proposalHash = sha3(beneficiary, etherAmount * 1 ether, transactionBytecode);
        p.waitingWindow = now + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.rankSum = 0;
        ProposalAdded(proposalID, beneficiary, etherAmount, JobDescription);
        numProposals = proposalID+1;
    }    

    /* function to check if a proposal code matches */
    function checkProposalCode(uint proposalNumber, address beneficiary, uint amount, bytes transactionBytecode) constant returns (bool codeChecksOut) {
        Proposal p = proposals[proposalNumber];
        return p.proposalHash == sha3(beneficiary, amount, transactionBytecode);
    }

    function makeDecision(uint proposalNumber, bool agree) returns (uint voteID){
        if (memberId[msg.sender] == 0) throw;

        uint rank = members[memberId[msg.sender]].rank; 
        
        Proposal p = proposals[proposalNumber];         // Get the proposal
        if (p.voted[msg.sender] == true) throw;         // If has already voted, cancel
        p.voted[msg.sender] = true;                     // Set this voter as having voted
        p.rankSum+= rank;                   // Increase the number of votes
        if (agree) {                         // If they support the proposal
            p.currentResult += int(rank);         // Increase score
        } else {                                        // If they don't
            p.currentResult -= int(rank);         // Decrease the score
        }
        // Create a log of this event
        Voted(proposalNumber, agree, msg.sender);
    }

    function executeProposal(uint proposalNumber, bytes transactionBytecode) returns (int result) {
        Proposal p = proposals[proposalNumber];
        /* Check if the proposal can be executed */
        if (now < p.waitingWindow                                                  // has the voting deadline arrived?  
            || p.executed                                                           // has it been already executed? 
            || p.proposalHash != sha3(p.recipient, p.amount, transactionBytecode)   // Does the transaction code match the proposal? 
            || p.rankSum < rankThreshold)                                    // has minimum quorum?
            throw;

        /* execute result */
        if (p.currentResult > majorityMargin) {     
            /* If difference between support and opposition is larger than margin */
            p.executed = true;
            p.proposalPassed = true;
            if(!p.recipient.call.value(p.amount)(transactionBytecode)) throw;
        } else {
            p.executed = true;
            p.proposalPassed = false;
        } 
        // Fire Events
        ProposalTallied(proposalNumber, p.currentResult, p.rankSum, p.proposalPassed);
    }

}
