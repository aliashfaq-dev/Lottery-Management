// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import {Test} from "forge-std/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract LotteryTest is Test {
    Lottery lottery;

    address owner = address(this);
    address player1 = makeAddr("player1");
    address player2 = makeAddr("player2");

    uint256 ticketPrice = 0.01 ether;

    function setUp() public {
        lottery = new Lottery(ticketPrice);

        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);
    }

    function testLotteryStartsOpen() public view {
        assertTrue(lottery.lotteryOpen());
    }

    function testPlayerCanEnter() public {
        vm.prank(player1);

        lottery.enterLottery{value: ticketPrice}();

        assertEq(lottery.players(0), player1);
        assertEq(lottery.getLotteryBalance(), ticketPrice);
    }

    function testCannotEnterWithIncorrectPrice() public {
        vm.prank(player1);

        vm.expectRevert("Incorrect ticket price");

        lottery.enterLottery{value: 0.02 ether}();
    }

    function testMultiplePlayersCanEnter() public {
        vm.prank(player1);
        lottery.enterLottery{value: ticketPrice}();

        vm.prank(player2);
        lottery.enterLottery{value: ticketPrice}();

        assertEq(lottery.getPlayers().length, 2);
    }

    function testWinnerGetsPrize() public {
        vm.prank(player1);
        lottery.enterLottery{value: ticketPrice}();

        vm.prank(player2);
        lottery.enterLottery{value: ticketPrice}();

        uint256 balanceBefore = player1.balance;

        lottery.pickWinner();

        address winner = lottery.recentWinner();

        assertTrue(winner == player1 || winner == player2);

        assertEq(winner.balance, balanceBefore + (ticketPrice * 2));

        assertEq(lottery.getPlayers().length, 0);
        assertTrue(lottery.lotteryOpen());
    }
}