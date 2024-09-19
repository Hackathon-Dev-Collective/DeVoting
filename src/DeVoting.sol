// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract DeVoting {
    constructor() {}

    struct VoteDetails {
        string topic;
        string[] options;
        uint256[] optionsCount;
        address creator;
        uint256 endTime;
        bool exist;
        mapping(address => uint256) usersVotedCount;
    }

    struct Attestation {
        string identifier; // 用户身份标识（例如某种唯一标识）
        uint256 validUntil; // Attestation的有效期
    }

    /* vote module */
    uint256 public voteId = 0;
    mapping(uint256 => VoteDetails) public votes;

    event VoteCreate(uint256 indexed voteId, string topic, uint256 endTime, address owner);
    event VoteClose(uint256 indexed voteId);
    event VoteUpdate(uint256 indexed voteId, uint256 endTime);
    event VoteSubmit(uint256 indexed voteId, uint256 optionIndex, uint256 optionCount, address submitor);

    /* attestation module */
    mapping(address => Attestation) public attestations;

    event AttestationSubmit(address indexed owner, string identifier, uint256 validUntil);
    event AttestationRevoke(address owner);

    function submitAttestation(string memory _identifier, uint256 _validUntil) public {
        require(_validUntil > block.timestamp, "attestation must valid tiem must more than now");

        Attestation storage attestation = attestations[msg.sender];
        attestation.identifier = _identifier;
        attestation.validUntil = _validUntil;

        emit AttestationSubmit(msg.sender, _identifier, _validUntil);
    }

    function verifyAttestation() public view returns (bool) {
        Attestation storage attestation = attestations[msg.sender];
        return attestation.validUntil > block.timestamp;
    }

    function revokeAttestation() public {
        delete attestations[msg.sender];
        emit AttestationRevoke(msg.sender);
    }

    function createVote(string memory _topic, string[] memory _options, uint256 _endTimestampSeconds)
        public
        returns (uint256)
    {
        // require(isAttestationValid());

        require(_options.length > 2, "at least have two choice");

        require(_endTimestampSeconds > block.timestamp, "at least _endTimestampSeconds more than now time");

        VoteDetails storage newVote = votes[++voteId];

        newVote.topic = _topic;
        for (uint256 i = 0; i < _options.length; i++) {
            newVote.options.push(_options[i]);
            newVote.optionsCount.push(0);
        }
        newVote.creator = msg.sender;
        newVote.endTime = _endTimestampSeconds;
        newVote.exist = true;
        emit VoteCreate(voteId, _topic, _endTimestampSeconds, msg.sender);
        return voteId;
    }

    function getVote(uint256 _voteId)
        public
        view
        returns (
            string memory _topic,
            string[] memory _options,
            uint256[] memory _optionsCount,
            address _owner,
            uint256 _endTime
        )
    {
        require(_voteId > 0 && _voteId < voteId, "vote Id is invalid");
        require(votes[_voteId].exist, "vote is not exist");

        VoteDetails storage vote = votes[_voteId];

        return (vote.topic, vote.options, vote.optionsCount, vote.creator, vote.endTime);
    }

    function closeVote(uint256 _voteId) public returns (bool) {
        // require(isAttestationValid());
        require(_voteId > 0 && _voteId < voteId, "vote Id is invalid");
        require(votes[_voteId].exist, "vote is not exist");
        votes[_voteId].exist = false;
        emit VoteClose(_voteId);
        return true;
    }

    function updateVote(uint256 _voteId, uint256 _endTime) public returns (bool) {
        // require(isAttestationValid());
        require(_voteId > 0 && _voteId < voteId, "vote Id is invalid");
        require(votes[_voteId].exist, "vote is not exist");
        require(block.timestamp < votes[_voteId].endTime, "this vote is end");
        require(_endTime > block.timestamp, "modify time must more than block.timestamp");

        votes[_voteId].endTime = _endTime;
        emit VoteUpdate(_voteId, _endTime);
        return true;
    }

    function submitVote(uint256 _voteId, uint256 _optionIndex, uint256 _optionCount) public returns (bool) {
        // require(isAttestationValid());
        require(_voteId > 0 && _voteId < voteId, "vote Id is invalid");
        require(_optionCount > 0, "option Count must more than zero");
        VoteDetails storage vote = votes[_voteId];
        require(vote.usersVotedCount[msg.sender] > 0, "user voted");
        require(vote.exist, "vote is not exist");
        require(block.timestamp < vote.endTime, "this vote is end");
        require(_optionIndex >= 0 && _optionIndex < vote.options.length, "_optionIndex is invalid");

        vote.optionsCount[_optionIndex] += _optionCount;
        vote.usersVotedCount[msg.sender] = _optionCount;
        emit VoteSubmit(_voteId, _optionIndex, _optionCount, msg.sender);
        return true;
    }

    function checkIfUserVoted(uint256 _voteId) public view returns (bool) {
        // require(isAttestationValid());
        require(_voteId > 0 && _voteId < voteId, "vote Id is invalid");
        VoteDetails storage vote = votes[_voteId];
        return vote.usersVotedCount[msg.sender] > 0;
    }
}
