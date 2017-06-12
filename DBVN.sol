/*

This is a first proposal contract code for the seed of the Bitnation DBVN

File lincensed under WTFPL: http://www.wtfpl.net

*/

pragma solidity ^0.4.2;

contract owned {
    address public owner;

    event OwnerChanged(address owner);

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
        OwnerChanged(newOwner);
    }
}

contract constitution is owned {
    string public constitutionUrl;
    Article[] public articlesOfConstitution;
    
    event ArticleChanged(uint id);
    
    struct Article {
        string summary;
        bool valid;
        uint createdAt;
    }
    
    function setConstitutionUrl(string _url) onlyOwner {
        constitutionUrl = _url;
    }
    
    /* change constitution */
    function addArticle(string summary) onlyOwner {
        uint id = articlesOfConstitution.length++;
        articlesOfConstitution[id] = Article({summary: summary, valid: true, createdAt: now});
        
        ArticleChanged(id);
    }
    
    function repealArticle(uint articleID) onlyOwner {
        Article article = articlesOfConstitution[articleID];
        article.valid = false;
        
        ArticleChanged(articleID);
    }
}

contract memberPool is owned {
    mapping (address => uint) public memberId;
    Member[] public members;
    
    event MembershipChanged(address member);
    
    struct Member {
        address member;
        uint rank;
        bool canAddProposals;
        string name;
        string fieldOfWork;
        uint memberSince;
    }
    
    modifier onlyCanAddProposal {
        if (memberId[msg.sender] == 0 || !members[memberId[msg.sender]].canAddProposals) throw;
        _;
    }
    
    modifier onlyMembers {
        if (memberId[msg.sender] == 0) throw;
        _;
    }
    
    /*make member*/
    function changeMembership(address targetMember, uint rank, bool canAddProposals, string memberName, string _fieldOfWork) onlyOwner {
        uint id;
        if (memberId[targetMember] == 0) {
           memberId[targetMember] = members.length;
           id = members.length++;
           members[id] = Member({member: targetMember, rank: rank, canAddProposals: canAddProposals, memberSince: now, name: memberName, fieldOfWork: _fieldOfWork});
        } else {
            id = memberId[targetMember];
            Member m = members[id];
            m.rank = rank;
            m.canAddProposals = canAddProposals;
            m.name = memberName;
            m.fieldOfWork = _fieldOfWork;
        }

        MembershipChanged(targetMember);
    }
}

contract DBVN is memberPool, constitution {
    uint public rankThreshold;
    uint public debatingPeriodInMinutes;
    
    uint public majorityTier1;
    uint public majorityTier2;
    uint public majorityTier3;
    
    uint public tier1;
    uint public tier2;
    uint public tier3;
    
    Proposal[] public proposals;
    uint public numProposals;
    
    event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    event Voted(uint proposalID, bool position, address voter);
    event ProposalTallied(uint proposalID, int result, uint quorum, bool active);
    event ChangeOfRules(uint minimumQuorum, uint debatingPeriodInMinutes);
    event ChangeTiersRules(uint _majorityTier1, uint _tier1, uint _majorityTier2, uint _tier2, uint _majorityTier3, uint _tier3);
    
    struct Proposal {
        address recipient;
        uint amount;
        string description;
        string fieldOfWork;
        uint waitingWindow;
        bool executed;
        bool proposalPassed;
        uint rankSum;
        int currentResult;
        bytes32 proposalHash;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Vote {
        bool inSupport;
        address voter;
        string justification;
    }
    
    /* First time setup */
    function DBVN(uint totalRankNeededForDecisions, uint minutesForDebate, string constitutionURL, uint majorityTier1, uint tier1, uint majorityTier2, uint tier2, uint majorityTier3, uint tier3) {
        changeMembership(0, 0, false, '', '');
        changeVotingRules(totalRankNeededForDecisions, minutesForDebate);
        changeTiersRules(majorityTier1, tier1, majorityTier2, tier2, majorityTier3, tier3);
        
        setConstitutionUrl(constitutionURL);
    }
    
    /*change rules*/
    function changeVotingRules(uint minimumQuorumForProposals, uint minutesForDebate) onlyOwner {
        rankThreshold = minimumQuorumForProposals;
        debatingPeriodInMinutes = minutesForDebate;

        ChangeOfRules(rankThreshold, debatingPeriodInMinutes);
    }
    
    function changeTiersRules(uint _majorityTier1, uint _tier1, uint _majorityTier2, uint _tier2, uint _majorityTier3, uint _tier3) onlyOwner {
        majorityTier1 = _majorityTier1;
        tier1 = _tier1;
        
        majorityTier2 = _majorityTier2;
        tier2 = _tier2;
        
        majorityTier3 = _majorityTier3;
        tier3 = _tier3;
    }
    
    /* Function to create a new proposal */
    function newProposalInWei(address beneficiary, uint weiAmount, string JobDescription, string field, bytes transactionBytecode) onlyCanAddProposal returns (uint proposalID) {
        proposalID = proposals.length++;
        Proposal p = proposals[proposalID];
        p.recipient = beneficiary;
        p.amount = weiAmount;
        p.description = JobDescription;
        p.fieldOfWork = field;
        p.proposalHash = sha3(beneficiary, weiAmount, transactionBytecode);
        p.waitingWindow = now + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.rankSum = 0;
        ProposalAdded(proposalID, beneficiary, weiAmount, JobDescription);
        numProposals = proposalID+1;
    }
    
    /* Function to create a new proposal */
    function newProposalInEther(address beneficiary, uint etherAmount, string JobDescription, string field, bytes transactionBytecode) onlyCanAddProposal returns (uint proposalID) {
        return newProposalInWei(beneficiary, etherAmount * 1 ether, JobDescription, field, transactionBytecode);
    }    

    /* function to check if a proposal code matches */
    function checkProposalCode(uint proposalNumber, address beneficiary, uint amount, bytes transactionBytecode) constant returns (bool codeChecksOut) {
        Proposal p = proposals[proposalNumber];
        return p.proposalHash == sha3(beneficiary, amount, transactionBytecode);
    }

    function makeDecision(uint proposalNumber, bool agree) onlyMembers {
        Member m = members[memberId[msg.sender]];
        uint rank = m.rank;
        
        Proposal p = proposals[proposalNumber];         // Get the proposal
        if (p.voted[msg.sender] == true) throw;         // If has already voted, cancel
        p.voted[msg.sender] = true;                     // Set this voter as having voted
        
        // As asked by Susanne: if your fieldOfWork correspond, double your rank
        if (sha3(p.fieldOfWork) == sha3(m.fieldOfWork)) { // small workaround
            rank = rank * 2;
        }
        
        p.rankSum += rank;                   // Increase the number of votes
        if (agree) {                         // If they support the proposal
            p.currentResult += int(rank);         // Increase score
        } else {                                        // If they don't
            p.currentResult -= int(rank);         // Decrease the score
        }
        // Create a log of this event
        Voted(proposalNumber, agree, msg.sender);
    }

    function executeProposal(uint proposalNumber, bytes transactionBytecode) onlyMembers {
        Proposal p = proposals[proposalNumber];
        /* Check if the proposal can be executed */
        if (now < p.waitingWindow                                                  // has the voting deadline arrived?  
            || p.executed                                                           // has it been already executed? 
            || p.proposalHash != sha3(p.recipient, p.amount, transactionBytecode)   // Does the transaction code match the proposal? 
            || p.rankSum < rankThreshold)                                    // has minimum quorum?
            throw;
        
        uint majorityRequired = majorityTier3; // By default, the highest
        if (p.amount <= tier1) { // below tier1
            majorityRequired = majorityTier1;
        } else if (p.amount > tier1 && p.amount <= tier2) { // between tier1 and tier2
            majorityRequired = majorityTier2;
        } // higher

        /* execute result */
        if (p.currentResult > int(majorityRequired)) {     
            /* If difference between support and opposition is larger than margin */
            p.executed = true;
            if (!p.recipient.call.value(p.amount)(transactionBytecode)) throw;
            p.proposalPassed = true;
        } else {
            p.executed = true;
            p.proposalPassed = false;
        }
        // Fire Events
        ProposalTallied(proposalNumber, p.currentResult, p.rankSum, p.proposalPassed);
    }
}
