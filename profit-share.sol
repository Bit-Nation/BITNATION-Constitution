/*

This is a profit sharing contract. In order to be sure that shareholders are active, deploy periodically this contract and ask 
for shareholders who want to receive the profit to ping this contract. Their address will be added. All ether sent to the 
contract is automatically disbursed among all active shareholders, in proportion to their share. Tokens can also be disbursed
using a separate function.


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
    
contract token { 
    mapping (address => uint256) public balanceOf;  
    function transfer(address _to, uint256 _value);
}
    
contract profitSharing {
    mapping (address => uint) public holderId;
    ActiveHolder[] public holders;
    token public sharesTokenAddress;
    
    struct ActiveHolder {
        address holder;
        string name;
        uint lastSeen;
    }
    
    function profitSharing(address sharesAddress, string ownerName){
        sharesTokenAddress = token(sharesAddress);
        holders[0] = ActiveHolder({holder: msg.sender, name: ownerName, lastSeen: now});
    }
    
    /*make active Member*/
    function activateMe(string name) {
        uint id;
        if (holderId[msg.sender] == 0) {
           holderId[msg.sender] = holders.length;
           id = holders.length++;
           holders[id] = ActiveHolder({holder: msg.sender, name: name, lastSeen: now});
        } else {
            id = holderId[msg.sender];
            ActiveHolder h = holders[id];
            h.name = name;
            h.lastSeen = now;
        }
    }
    
    function (){
        uint totalShares = 0;
        for (uint i = 0; i <  holders.length; ++i) {
            ActiveHolder h = holders[i];
            uint holderBalance = sharesTokenAddress.balanceOf(h.holder); 
            totalShares += holderBalance;
        }
        
        for (i = 0; i <  holders.length; ++i) {
            h = holders[i];
            holderBalance = sharesTokenAddress.balanceOf(h.holder); 
            h.holder.send(msg.value * holderBalance/totalShares);
        }
    }
    
    function distributeToken(address tokenToDistributeAddress){
        uint totalShares = 0;
        token tokenToDistribute = token(tokenToDistributeAddress);
        uint totalBalance = tokenToDistribute.balanceOf(this);
        
        for (uint i = 0; i <  holders.length; ++i) {
            ActiveHolder h = holders[i];
            uint holderBalance = sharesTokenAddress.balanceOf(h.holder); 
            totalShares += holderBalance;
        }
        
        for (i = 0; i <  holders.length; ++i) {
            h = holders[i];
            holderBalance = sharesTokenAddress.balanceOf(h.holder); 
            tokenToDistribute.transfer(h.holder, msg.value * holderBalance/totalShares);
        }
    }
}
