//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

// This program solves the trust problem associated with crowdFunding programs today.

contract crowdFunding {
    mapping(address => uint) public contributors;
    uint public goal;
    uint public deadline;
    address public admin;
    uint public noOfContriubutors;
    uint public raisedAmount;
    uint public  minimumCOntribution;
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
        
    }
    
    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent( string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);
    
    
    mapping(uint => Request) public requests;
    uint public numRequests;
    
    constructor(uint _goal, uint _deadline){
        goal = _goal;
        deadline = block.timestamp + _deadline;
        minimumCOntribution = 100 wei;
        admin = msg.sender;
    }
    function contribute() public payable {
        require(block.timestamp < deadline , "The deadline has passed.");
        require(msg.value >= minimumCOntribution, "The contribution did not meet the rquired minimum!");
        
        if(contributors[msg.sender] == 0){
            noOfContriubutors++ ;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
        
        emit ContributeEvent(msg.sender, msg.value);
        
    }
    receive() payable external {
        contribute();
    }
    function getBalance() public view returns(uint){
       return(address(this).balance);
    }
    function getRefund() public {
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributors[msg.sender] > 0);
        
        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        
        recipient.transfer(value);
         // equivalent to:
        // payable(msg.sender).transfer(contributors[msg.sender]);
        
        contributors[msg.sender] = 0;
    }
    modifier onlyAdmin(){
        require(msg.sender == admin, "You must be admin to call this function");
        _;
    }
    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
        
        emit CreateRequestEvent(_description, _recipient, _value);
    }
    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender] > 0, "You must be a contributor to vote");
        Request storage thisRequest = requests[_requestNo];
        
        require(thisRequest.voters[msg.sender] ==  false, "you have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }
    function makePayment(uint _requestNo) public onlyAdmin{
        require(raisedAmount >= goal);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false);
        require(thisRequest.noOfVoters > noOfContriubutors/2); // 50% voted for this request
        
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
        
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
    
}
