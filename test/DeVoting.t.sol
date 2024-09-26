// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DeVoting.sol";
import "../src/DVT.sol";

contract DeVotingTest is Test {
    DeVoting devoting;
    DVT token;
    address owner = address(0x1); // 模拟合约的所有者
    address user1 = address(0x2); // 模拟用户1
    address user2 = address(0x3); // 模拟用户2

    function setUp() public {
        // 部署一个 ERC20 代币，并为 owner 分配一些初始余额
        vm.prank(owner);
        token = new DVT();
        vm.prank(owner);
        token.mint(owner, 1000 * 10 ** 18);

        // 部署 DeVoting 合约
        vm.prank(owner);
        devoting = new DeVoting(address(token));

        // owner 批准合约可以花费他的代币
        vm.prank(owner);
        token.approve(address(devoting), 500 * 10 ** 18);
    }

    function testSubmitAttestation() public {
        // 模拟 user1 提交 attestation
        vm.prank(user1);
        devoting.submitAttestation("user1-identifier", block.timestamp + 1 days);

        // 检查 attestation 是否提交成功
        (string memory identifier, uint256 validUntil) = devoting.attestations(user1);
        assertEq(identifier, "user1-identifier");
        assertTrue(validUntil > block.timestamp);
    }

    function testCreateVote() public {
        // 模拟 user1 提交 attestation
        vm.prank(user1);
        devoting.submitAttestation("user1-identifier", block.timestamp + 1 days);

        // 模拟 user1 创建投票
        string[] memory options = new string[](2);
        options[0] = "Option 1";
        options[1] = "Option 2";

        vm.prank(user1);
        uint256 voteId = devoting.createVote("Test Topic", options, block.timestamp + 1 days);

        // 检查投票是否创建成功
        (string memory topic,,,, uint256 endTime) = devoting.getVote(voteId);
        assertEq(topic, "Test Topic");
        assertTrue(endTime > block.timestamp);
    }

    function testSubmitVote() public {
        // 模拟 user1 提交 attestation 并创建投票
        vm.prank(user1);
        devoting.submitAttestation("user1-identifier", block.timestamp + 1 days);

        string[] memory options = new string[](2);
        options[0] = "Option 1";
        options[1] = "Option 2";

        vm.prank(user1);
        uint256 voteId = devoting.createVote("Test Topic", options, block.timestamp + 1 days);

        // 模拟 user2 提交 attestation 并投票
        vm.prank(user2);
        devoting.submitAttestation("user2-identifier", block.timestamp + 1 days);

        vm.prank(user2);
        devoting.submitVote(voteId, 0, 1); // 给 Option 1 投 1 票

        // vm.prank(user2);
        // assertEq(devoting.checkIfUserVoted(voteId), true);

        // 检查 Option 1 的投票计数是否更新
        (,, uint256[] memory optionsCount,,) = devoting.getVote(voteId);
        assertEq(optionsCount[0], 1);
    }

    function testDistributeRewards() public {
        // 分发奖励给 user1
        uint256 rewardAmount = 100 * 10 ** 18;
        vm.prank(owner);
        devoting.distributeRewards(user1, rewardAmount);

        // 检查 user1 的余额
        uint256 user1Balance = devoting.getUserRewardBalance(user1);
        assertEq(user1Balance, rewardAmount);
    }
}
