// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";

contract LotteryScript is Script {
    function run() external returns (Lottery) {
        vm.startBroadcast();

        Lottery lottery = new Lottery(0.01 ether);

        vm.stopBroadcast();

        return lottery;
    }
}