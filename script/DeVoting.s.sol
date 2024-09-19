// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DeVoting} from "../src/DeVoting.sol";

contract DeVotingScript is Script {
    DeVoting public counter;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        counter = new DeVoting();

        vm.stopBroadcast();
    }
}
