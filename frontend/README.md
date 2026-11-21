# Lucky Draw — USDC Lottery Frontend

React + Vite + ethers.js frontend for the Lottery contract on Ethereum Sepolia.

## Setup

1. Install Node.js LTS and MetaMask.
2. Copy `.env.example` to `.env`.
3. Set `VITE_LOTTERY_ADDRESS` to your deployed Lottery contract address.
4. Install and run:

```bash
npm install
npm run dev
```

Open the local URL printed by Vite.

## Features
- MetaMask connection and automatic Sepolia network switch
- USDC balance, lottery pool, ticket price, participant count
- USDC allowance approval + ticket purchase
- Admin-only draw button
- Winner and transaction explorer links
- Responsive dark UI

## Sepolia USDC
Circle's Ethereum Sepolia USDC token address:
`0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`

USDC has 6 decimals. The contract ticket price is configured in base units (5 USDC = `5000000`).

## Before using
Deploy the updated `Lottery.sol` with the USDC address and ticket price. Add the deployed contract address to `.env`.

The current lottery contract uses block timestamp/prevrandao for winner selection and is **not secure randomness**. This is for testnet demonstrations only; replace randomness with Chainlink VRF before production. Use test tokens only.
