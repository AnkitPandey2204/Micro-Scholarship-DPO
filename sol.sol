// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MicroScholarshipDAO {
    // DAO owner (Creator)
    address public owner;
    
    // Scholarship proposal structure
    struct ScholarshipProposal {
        string description;
        uint256 amount;
        address recipient;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    
    // Array of proposals
    ScholarshipProposal[] public proposals;
    
    // DAO members
    mapping(address => bool) public members;
    
    // Events
    event NewProposal(uint256 proposalId, string description, uint256 amount, address recipient);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, bool success);
    event NewMember(address member);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only DAO members can perform this action");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposals.length, "Proposal does not exist");
        _;
    }

    modifier proposalNotExecuted(uint256 proposalId) {
        require(!proposals[proposalId].executed, "Proposal already executed");
        _;
    }

    modifier proposalOpen(uint256 proposalId) {
        require(block.timestamp < proposals[proposalId].deadline, "Voting period has ended");
        _;
    }

    modifier proposalClosed(uint256 proposalId) {
        require(block.timestamp >= proposals[proposalId].deadline, "Voting period is still open");
        _;
    }

    constructor() {
        owner = msg.sender;
        members[msg.sender] = true; // Owner is a member by default
        emit NewMember(msg.sender);
    }

    // Add new members to the DAO
    function addMember(address _newMember) external onlyOwner {
        members[_newMember] = true;
        emit NewMember(_newMember);
    }

    // Remove members from the DAO
    function removeMember(address _member) external onlyOwner {
        members[_member] = false;
    }

    // Create a new scholarship proposal
    function createProposal(string memory _description, uint256 _amount, address _recipient, uint256 _votingPeriod) external onlyMember {
        uint256 proposalId = proposals.length;
        ScholarshipProposal storage newProposal = proposals.push();
        newProposal.description = _description;
        newProposal.amount = _amount;
        newProposal.recipient = _recipient;
        newProposal.deadline = block.timestamp + _votingPeriod;
        emit NewProposal(proposalId, _description, _amount, _recipient);
    }

    // Vote on a proposal
    function vote(uint256 proposalId, bool _support) external onlyMember proposalExists(proposalId) proposalOpen(proposalId) {
        ScholarshipProposal storage proposal = proposals[proposalId];
        require(!proposal.hasVoted[msg.sender], "You have already voted on this proposal");
        
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        proposal.hasVoted[msg.sender] = true;
        emit Voted(proposalId, msg.sender, _support);
    }

    // Execute a proposal if it has passed
    function executeProposal(uint256 proposalId) external proposalExists(proposalId) proposalClosed(proposalId) proposalNotExecuted(proposalId) {
        ScholarshipProposal storage proposal = proposals[proposalId];

        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass");

        proposal.executed = true;
        payable(proposal.recipient).transfer(proposal.amount);
        emit ProposalExecuted(proposalId, true);
    }

    // Retrieve the contract balance
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Fund the contract to enable scholarship payments
    function fundContract() external payable {
        require(msg.value > 0, "Must send Ether to fund the contract");
    }

    // Withdraw funds (only by the owner)
    function withdrawFunds(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner).transfer(amount);
    }
}
