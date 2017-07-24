pragma solidity ^0.4.13;

import "zeppelin/contracts/ownership/Ownable.sol";


contract HasMemberPool is Ownable {
    mapping (address => uint) public applierSince;
    mapping (address => uint) public memberSince;

    event NewApplication(address applier);
    event ApplicationCanceled(address applier);
    event ApplicationRefused(address applier);
    event ApplicationAccepted(address applier);

    event MembershipCanceled(address member);

    modifier onlyMembers {
        require(hasMembership(msg.sender));
        _;
    }

    function hasPendingApplication(address applier) constant returns (bool hasApplication) {
        hasApplication = applierSince[applier] > 0;
    }

    function hasMembership(address member) constant returns (bool isMember) {
        isMember = memberSince[member] > 0;
    }

    function HasMemberPool() {
        memberSince[msg.sender] = now;
    }

    function applyForMembership() {
        require(!hasPendingApplication(msg.sender));
        require(!hasMembership(msg.sender));

        applierSince[msg.sender] = now;

        NewApplication(msg.sender);
    }

    function acceptApplication(address applier) onlyOwner {
        require(hasPendingApplication(applier));

        applierSince[applier] = 0;
        memberSince[applier] = now;

        ApplicationAccepted(applier);
    }

    function refuseApplication(address applier) onlyOwner {
        require(hasPendingApplication(applier));

        applierSince[applier] = 0;

        ApplicationRefused(applier);
    }

    function cancelMembership(address member) onlyOwner {
       require(hasMembership(member));

       memberSince[member] = 0;

       MembershipCanceled(member);
    }

    function cancelMyApplication() {
       require(hasPendingApplication(msg.sender));

       applierSince[msg.sender] = 0;

       ApplicationCanceled(msg.sender);
    }

    function cancelMyMembership() {
       require(hasMembership(msg.sender));

       memberSince[msg.sender] = 0;

       MembershipCanceled(msg.sender);
    }
}
