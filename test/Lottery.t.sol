// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract MockUSDC {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount && allowance[from][msg.sender] >= amount, "insufficient");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract LotteryTest is Test {
    Lottery lottery;
    MockUSDC usdc;

    address player1 = makeAddr("player1");
    address player2 = makeAddr("player2");
    uint256 ticketPrice = 5e6; // 5 USDC

    function setUp() public {
        usdc = new MockUSDC();
        lottery = new Lottery(address(usdc), ticketPrice);
        usdc.mint(player1, 100e6);
        usdc.mint(player2, 100e6);
    }

    function testLotteryStartsOpen() public view {
        assertTrue(lottery.lotteryOpen());
    }

    function testPlayerCanEnterWithUSDC() public {
        vm.startPrank(player1);
        usdc.approve(address(lottery), ticketPrice);
        lottery.enterLottery();
        vm.stopPrank();

        assertEq(lottery.players(0), player1);
        assertEq(lottery.getLotteryBalance(), ticketPrice);
    }

    function testMultiplePlayersCanEnter() public {
        vm.startPrank(player1);
        usdc.approve(address(lottery), ticketPrice);
        lottery.enterLottery();
        vm.stopPrank();

        vm.startPrank(player2);
        usdc.approve(address(lottery), ticketPrice);
        lottery.enterLottery();
        vm.stopPrank();

        assertEq(lottery.getPlayers().length, 2);
        assertEq(lottery.getLotteryBalance(), ticketPrice * 2);
    }

    function testWinnerGetsUSDCPrize() public {
        vm.startPrank(player1);
        usdc.approve(address(lottery), ticketPrice);
        lottery.enterLottery();
        vm.stopPrank();

        vm.startPrank(player2);
        usdc.approve(address(lottery), ticketPrice);
        lottery.enterLottery();
        vm.stopPrank();

        lottery.pickWinner();
        address winner = lottery.recentWinner();

        assertTrue(winner == player1 || winner == player2);
        assertEq(usdc.balanceOf(winner), 100e6 + ticketPrice * 2);
        assertEq(lottery.getLotteryBalance(), 0);
        assertEq(lottery.getPlayers().length, 0);
        assertTrue(lottery.lotteryOpen());
    }
}
