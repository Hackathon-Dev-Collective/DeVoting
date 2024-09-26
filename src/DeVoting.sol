// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DeVoting is Ownable {
    IERC20 public contractToken;
    address public ownerAddress;

    constructor(address _contractToken) Ownable(msg.sender) {
        contractToken = IERC20(_contractToken);
        // it needs owner approve this contract to use token.
        ownerAddress = msg.sender;
    }

    struct UserVotedInfo {
        uint256 count;
        string option;
        uint256 voteTime;
    }

    struct VoteDetails {
        string topic;
        string[] options;
        uint256[] optionsCount;
        address creator;
        uint256 endTime;
        bool exist;
        mapping(address => UserVotedInfo) userVotedInfos;
    }

    struct Attestation {
        string identifier; // 用户身份标识（例如某种唯一标识）
        uint256 validUntil; // Attestation的有效期
    }

    /* attestation module */
    mapping(address => Attestation) public attestations;

    event AttestationSubmit(address indexed owner, string identifier, uint256 validUntil);
    event AttestationRevoke(address owner);

    /* vote module */
    uint256 public voteId = 0;
    mapping(uint256 => VoteDetails) public votes;

    event VoteCreate(uint256 indexed voteId, string topic, uint256 endTime, address owner);
    event VoteClose(uint256 indexed voteId);
    event VoteUpdate(uint256 indexed voteId, uint256 endTime);
    event VoteSubmit(uint256 indexed voteId, uint256 optionIndex, uint256 optionCount, address submitor);
    event VoteUserInfo(uint256 count, string option, uint256 voteTime);

    modifier checkVoteIdValid(uint256 _voteId) {
        require(_voteId > 0 && _voteId <= voteId, "vote Id is invalid");
        _;
    }

    /* token module */
    event RewardsDistribute(address userAddress, uint256 amount);

    /* attestation module */
    function submitAttestation(string memory _identifier, uint256 _validUntil) public {
        require(_validUntil > block.timestamp, "attestation must valid tiem must more than now");

        Attestation storage attestation = attestations[msg.sender];
        attestation.identifier = _identifier;
        attestation.validUntil = _validUntil;

        emit AttestationSubmit(msg.sender, _identifier, _validUntil);
    }

    function verifyAttestation(address user) public view returns (bool) {
        Attestation storage attestation = attestations[user];
        return attestation.validUntil > block.timestamp && bytes(attestation.identifier).length > 0;
    }

    function revokeAttestation() public {
        delete attestations[msg.sender];
        emit AttestationRevoke(msg.sender);
    }

    /* vote module */
    function createVote(string memory _topic, string[] memory _options, uint256 _endTimestampSeconds)
        public
        returns (uint256)
    {
        // require(isAttestationValid());

        require(_options.length >= 2, "at least have two choice");

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
        checkVoteIdValid(_voteId)
        returns (
            string memory _topic,
            string[] memory _options,
            uint256[] memory _optionsCount,
            address _owner,
            uint256 _endTime
        )
    {
        require(votes[_voteId].exist, "vote is not exist");

        VoteDetails storage vote = votes[_voteId];

        return (vote.topic, vote.options, vote.optionsCount, vote.creator, vote.endTime);
    }

    function closeVote(uint256 _voteId) public checkVoteIdValid(_voteId) returns (bool) {
        // require(isAttestationValid());
        require(votes[_voteId].exist, "vote is not exist");
        votes[_voteId].exist = false;
        emit VoteClose(_voteId);
        return true;
    }

    function updateVote(uint256 _voteId, uint256 _endTime) public checkVoteIdValid(_voteId) returns (bool) {
        // require(isAttestationValid());
        require(votes[_voteId].exist, "vote is not exist");
        require(block.timestamp < votes[_voteId].endTime, "this vote is end");
        require(_endTime > block.timestamp, "modify time must more than block.timestamp");

        votes[_voteId].endTime = _endTime;
        emit VoteUpdate(_voteId, _endTime);
        return true;
    }

    function submitVote(uint256 _voteId, uint256 _optionIndex, uint256 _optionCount)
        public
        checkVoteIdValid(_voteId)
        returns (bool)
    {
        // require(isAttestationValid());
        require(_optionCount > 0, "option Count must more than zero");
        VoteDetails storage vote = votes[_voteId];
        UserVotedInfo storage voteInfos = vote.userVotedInfos[msg.sender];
        require(
            voteInfos.count == 0 && bytes(voteInfos.option).length == 0 && voteInfos.voteTime == 0,
            "user has already voted"
        );
        require(vote.exist, "vote is not exist");
        require(block.timestamp < vote.endTime, "this vote is end");
        require(_optionIndex >= 0 && _optionIndex < vote.options.length, "_optionIndex is invalid");

        voteInfos.count = _optionCount;
        voteInfos.option = vote.options[_optionIndex];
        voteInfos.voteTime = block.timestamp;
        emit VoteUserInfo(voteInfos.count, voteInfos.option, voteInfos.voteTime);
        vote.optionsCount[_optionIndex] += _optionCount;
        emit VoteSubmit(_voteId, _optionIndex, _optionCount, msg.sender);
        return true;
    }

    function checkIfUserVoted(uint256 _voteId, address user) public view checkVoteIdValid(_voteId) returns (bool) {
        // require(isAttestationValid());
        VoteDetails storage vote = votes[_voteId];
        UserVotedInfo storage voteInfos = vote.userVotedInfos[user];
        return !(voteInfos.count == 0 && bytes(voteInfos.option).length == 0 && voteInfos.voteTime == 0);
    }

    function getVotedInfo(uint256 _voteId, address user)
        public
        view
        checkVoteIdValid(_voteId)
        returns (string memory choice, uint256 choseCount, uint256 timeStamp)
    {
        VoteDetails storage vote = votes[_voteId];
        UserVotedInfo storage voteInfos = vote.userVotedInfos[user];
        return (voteInfos.option, voteInfos.count, voteInfos.voteTime);
    }

    /* token module */
    function distributeRewards(address to, uint256 amount) public onlyOwner {
        contractToken.transferFrom(ownerAddress, to, amount);
        emit RewardsDistribute(to, amount);
    }

    function getUserRewardBalance(address user) public view returns (uint256) {
        return contractToken.balanceOf(user);
    }
}
