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


---

# Blockchain Assignments 6–13

The `blockchain-assignments-6-13` branch adds educational implementations for assignments 7–13. The existing USDC Lottery remains assignment 6.

## Contracts

| Assignment | File | What it demonstrates |
|---|---|---|
| 6. Lottery | `src/Lottery.sol` | USDC ticket payments, participants, owner draw and prize payout |
| 7. Multisignature Wallet | `src/MultisigWallet.sol` | Owners submit, confirm, revoke and execute transactions after a threshold |
| 8. EIP-191 | `src/EIP191Verifier.sol` | Ethereum Signed Message prefix and signer recovery |
| 9. EIP-712 | `src/EIP712Mail.sol` | Domain separator, typed struct hash and typed-data signature verification |
| 10. EIP-3009 | `src/EIP3009Token.sol` | Gasless authorization-based token transfers and cancellation |
| 11. Low-Level Call | `src/LowLevelCallDemo.sol` | `call()` executes another contract in its own storage context |
| 12. Delegated Call | `src/DelegateCallDemo.sol` | `delegatecall()` executes external code against the caller's storage |
| 13. UUPS Proxy | `src/UUPSExample.sol` | ERC-1967 implementation slot, proxy delegation and owner-authorized upgrade |

## Run the tests

Install Foundry and run from the repository root:

```bash
forge build
forge test -vv
```

The added test suite is `test/AdvancedAssignments.t.sol`.

## Important learning and security notes

- EIP-191 and EIP-712 are signature formats; they do not themselves move tokens or provide access control.
- EIP-3009 authorizations are signed by the token holder and can be submitted by a relayer. The nonce prevents replay.
- `call()` and `delegatecall()` are powerful low-level primitives. Always check the success flag and understand the storage/context implications.
- The multisig example is educational. It uses a simple owner list and threshold and is not a substitute for a thoroughly audited wallet.
- The UUPS example is a minimal educational implementation to make the proxy mechanics visible. For production, use audited OpenZeppelin upgradeable contracts, storage-layout validation, access controls and an audited upgrade process.
- The Lottery's current `block.timestamp` / `block.prevrandao` selection is not secure randomness. Use Chainlink VRF before any real-value deployment.
- Do not deploy these teaching examples with real funds or use real wallet private keys.
