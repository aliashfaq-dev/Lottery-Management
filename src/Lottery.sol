// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Lottery {
    address public owner;
    uint256 public ticketPrice;

    address[] public players;

    address public recentWinner;

    bool public lotteryOpen;

    constructor(uint256 _ticketPrice) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        lotteryOpen = true;
    }

    event PlayerEntered(address indexed player);

    function enterLottery() public payable {
        require(lotteryOpen, "Lottery is closed");
        require(msg.value == ticketPrice, "Incorrect ticket price");

        players.push(msg.sender);

        emit PlayerEntered(msg.sender);
    }

    function pickWinner() public {
        require(msg.sender == owner, "Only owner can pick winner");
        require(lotteryOpen, "Lottery is closed");
        require(players.length > 0, "No players in lottery");

        lotteryOpen = false;

        uint256 randomIndex = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    players.length
                )
            )
        ) % players.length;

        address winner = players[randomIndex];

        recentWinner = winner;

        payable(winner).transfer(address(this).balance);

        delete players;

        lotteryOpen = true;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getLotteryBalance() public view returns (uint256) {
        return address(this).balance;
    }
}