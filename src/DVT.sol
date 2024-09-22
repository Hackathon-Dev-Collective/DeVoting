// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// approve DeVoting use token.
contract DVT is ERC20, Ownable {
    constructor() ERC20("Decentralization Vote Token", "DVT") Ownable(msg.sender) {
        _mint(msg.sender, 10000000000 * 10 ** 18); // 初始发行100亿代币
    }

    function mint(address to, uint256 amount) public onlyOwner() {
        _mint(to, amount);
    }
}
