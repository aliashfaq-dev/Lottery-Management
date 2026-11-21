// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";

contract LotteryScript is Script {
    function run() external returns (Lottery) {
        address usdcAddress = vm.envAddress("USDC_ADDRESS");
        uint256 ticketPrice = vm.envOr("TICKET_PRICE_USDC", uint256(5e6)); // 5 USDC

        vm.startBroadcast();
        Lottery lottery = new Lottery(usdcAddress, ticketPrice);
        vm.stopBroadcast();

        return lottery;
    }
}
