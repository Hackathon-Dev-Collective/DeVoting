// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract DeVoting {
    constructor() {}

    struct VoteDetails {
        string topic;
        string[] options;
        uint[] optionsCount;
        address creator;
        uint endTime;
        bool exist;
        mapping(address => uint) usersVotedCount;
    }
    uint public voteId = 0;
    mapping(uint => VoteDetails) votes;

    event VoteCreate(
        uint indexed voteId,
        string topic,
        uint endTime,
        address owner
    );
    event VoteClose(uint indexed voteId);
    event VoteUpdate(uint indexed voteId, uint endTime);
    event VoteSubmit(
        uint indexed voteId,
        uint optionIndex,
        uint optionCount,
        address submitor
    );

    function createVote(
        string memory _topic,
        string[] memory _options,
        uint _endTimestampSeconds
    ) public returns (uint) {
        require(_options.length > 2, "at least have two choice");

        require(
            _endTimestampSeconds > block.timestamp,
            "at least _endTimestampSeconds more than now time"
        );

        VoteDetails storage newVote = votes[++voteId];

        newVote.topic = _topic;
        for (uint i = 0; i < _options.length; i++) {
            newVote.options.push(_options[i]);
            newVote.optionsCount.push(0);
        }
        newVote.creator = msg.sender;
        newVote.endTime = _endTimestampSeconds;
        newVote.exist = true;
        emit VoteCreate(voteId, _topic, _endTimestampSeconds, msg.sender);
        return voteId;
    }

    function getVote(
        uint _voteId
    )
        public
        view
        returns (
            string memory _topic,
            string[] memory _options,
            uint[] memory _optionsCount,
            address _owner,
            uint _endTime
        )
    {
        require(_voteId > 0 && _voteId < voteId, "vote Id is invalid");
        require(votes[_voteId].exist, "vote is not exist");

        VoteDetails storage vote = votes[_voteId];

        return (
            vote.topic,
            vote.options,
            vote.optionsCount,
            vote.creator,
            vote.endTime
        );
    }

    function closeVote(uint _voteId) public returns (bool) {
        require(_voteId > 0 && _voteId < voteId, "vote Id is invalid");
        require(votes[_voteId].exist, "vote is not exist");
        votes[_voteId].exist = false;
        emit VoteClose(_voteId);
        return true;
    }

    function updateVote(uint _voteId, uint _endTime) public returns (bool) {
        require(_voteId > 0 && _voteId < voteId, "vote Id is invalid");
        require(votes[_voteId].exist, "vote is not exist");
        require(block.timestamp < votes[_voteId].endTime, "this vote is end");
        require(
            _endTime > block.timestamp,
            "modify time must more than block.timestamp"
        );

        votes[_voteId].endTime = _endTime;
        emit VoteUpdate(_voteId, _endTime);
        return true;
    }

    function submitVote(
        uint _voteId,
        uint _optionIndex,
        uint _optionCount
    ) public returns (bool) {
        require(_voteId > 0 && _voteId < voteId, "vote Id is invalid");
        require(_optionCount > 0, "option Count must more than zero");
        VoteDetails storage vote = votes[_voteId];
        require(vote.usersVotedCount[msg.sender] > 0, "user voted");
        require(vote.exist, "vote is not exist");
        require(block.timestamp < vote.endTime, "this vote is end");
        require(
            _optionIndex >= 0 && _optionIndex < vote.options.length,
            "_optionIndex is invalid"
        );

        vote.optionsCount[_optionIndex] += _optionCount;
        vote.usersVotedCount[msg.sender] = _optionCount;
        emit VoteSubmit(_voteId, _optionIndex, _optionCount, msg.sender);
        return true;
    }

    function checkIfUserVoted(uint _voteId) public view returns (bool) {
        require(_voteId > 0 && _voteId < voteId, "vote Id is invalid");
        VoteDetails storage vote = votes[_voteId];
        return vote.usersVotedCount[msg.sender] > 0;
    }
}
