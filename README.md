# Lottery Management — USDC (Foundry CLI)

This repository is a command-line-only USDC lottery for Ethereum Sepolia. No frontend is included.

## Requirements
- Foundry installed (`forge`, `cast`)
- MetaMask or another wallet with a Sepolia account
- Sepolia ETH for gas
- Sepolia USDC test tokens
- A Sepolia RPC URL (Alchemy, Infura, or another provider)

## 1. Configure Windows CMD environment

In Command Prompt, from the project root:

```cmd
set SEPOLIA_RPC_URL=YOUR_SEPOLIA_RPC_URL
set PRIVATE_KEY=YOUR_TEST_WALLET_PRIVATE_KEY
set USDC_ADDRESS=YOUR_SEPOLIA_USDC_CONTRACT
set TICKET_PRICE_USDC=5000000
```

**Never use your main wallet's private key. Never commit secrets or share them.** The ticket price is 5 USDC; USDC uses 6 decimals, so 5 USDC = 5,000,000 units.

## 2. Build and test

```cmd
forge build
forge test -vv
```

## 3. Deploy to Sepolia

```cmd
forge script script/Deploy.s.sol:LotteryScript --rpc-url %SEPOLIA_RPC_URL% --broadcast --private-key %PRIVATE_KEY%
```

Copy the deployed Lottery contract address from the deployment output and set it:

```cmd
set LOTTERY_ADDRESS=YOUR_DEPLOYED_LOTTERY_ADDRESS
```

## 4. Check contract details

Ticket price:
```cmd
cast call %LOTTERY_ADDRESS% "ticketPrice()(uint256)" --rpc-url %SEPOLIA_RPC_URL%
```

Lottery status:
```cmd
cast call %LOTTERY_ADDRESS% "lotteryOpen()(bool)" --rpc-url %SEPOLIA_RPC_URL%
```

USDC pool balance (base units):
```cmd
cast call %LOTTERY_ADDRESS% "getLotteryBalance()(uint256)" --rpc-url %SEPOLIA_RPC_URL%
```

Participants:
```cmd
cast call %LOTTERY_ADDRESS% "getPlayers()(address[])" --rpc-url %SEPOLIA_RPC_URL%
```

## 5. Buy a ticket (each participant)

First, approve the Lottery contract to spend 5 USDC:

```cmd
cast send %USDC_ADDRESS% "approve(address,uint256)" %LOTTERY_ADDRESS% 5000000 --rpc-url %SEPOLIA_RPC_URL% --private-key %PRIVATE_KEY%
```

Then enter:

```cmd
cast send %LOTTERY_ADDRESS% "enterLottery()" --rpc-url %SEPOLIA_RPC_URL% --private-key %PRIVATE_KEY%
```

Each participant runs the approval and entry commands from their own wallet/private-key environment. Do not share private keys.

## 6. Draw winner (contract owner only)

```cmd
cast send %LOTTERY_ADDRESS% "pickWinner()" --rpc-url %SEPOLIA_RPC_URL% --private-key %PRIVATE_KEY%
```

The contract sends its entire USDC balance to the selected winner, clears the participant list, and opens the next round.

Check the winner:

```cmd
cast call %LOTTERY_ADDRESS% "recentWinner()(address)" --rpc-url %SEPOLIA_RPC_URL%
```

Check the remaining pool:

```cmd
cast call %LOTTERY_ADDRESS% "getLotteryBalance()(uint256)" --rpc-url %SEPOLIA_RPC_URL%
```

## Notes / security

- All amounts returned by the contract are USDC base units (6 decimals). Divide by 1,000,000 to display USDC.
- This contract currently uses block timestamp and prevrandao to select a winner. It is **not secure randomness** and is only suitable for testnet experiments. Use Chainlink VRF before production.
- This is a testnet demo. Do not use real funds.
- Use the official Sepolia USDC contract address from Circle's documentation; confirm it before deploying.
