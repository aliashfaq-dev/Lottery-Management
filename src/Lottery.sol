// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Lottery {
    address public owner;
    IERC20 public immutable usdc;
    uint256 public ticketPrice; // USDC base units (6 decimals)
    address[] public players;
    address public recentWinner;
    bool public lotteryOpen;

    constructor(address _usdc, uint256 _ticketPrice) {
        require(_usdc != address(0), "Invalid USDC address");
        require(_ticketPrice > 0, "Ticket price must be > 0");
        owner = msg.sender;
        usdc = IERC20(_usdc);
        ticketPrice = _ticketPrice;
        lotteryOpen = true;
    }

    event PlayerEntered(address indexed player);
    event WinnerPicked(address indexed winner, uint256 prize);

    function enterLottery() external {
        require(lotteryOpen, "Lottery is closed");
        require(usdc.transferFrom(msg.sender, address(this), ticketPrice), "USDC payment failed");
        players.push(msg.sender);
        emit PlayerEntered(msg.sender);
    }

    function pickWinner() external {
        require(msg.sender == owner, "Only owner can pick winner");
        require(lotteryOpen, "Lottery is closed");
        require(players.length > 0, "No players in lottery");

        lotteryOpen = false;
        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, players.length))
        ) % players.length;

        address winner = players[randomIndex];
        recentWinner = winner;
        uint256 prize = usdc.balanceOf(address(this));
        require(usdc.transfer(winner, prize), "Prize transfer failed");

        delete players;
        lotteryOpen = true;
        emit WinnerPicked(winner, prize);
    }

    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    function getLotteryBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }
}
