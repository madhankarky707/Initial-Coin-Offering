# Sale Smart Contract

A secure and gas-efficient smart contract for conducting a token sale with delayed token claiming.

## Overview

This smart contract facilitates a sale of ERC20 tokens in exchange for Ether. Buyers can purchase tokens and claim them after a predefined claim duration. All Ether collected is transferred directly to the owner's address.

## Features

* Purchase tokens with Ether
* Token lock and claim mechanism
* Reentrancy protection
* EOA-only enforcement
* Event emission for key actions
* Accurate tracking of each user’s purchases
* Detailed error reporting for better debugging

## Constructor

```solidity
constructor(
    address token_,
    address owner_,
    uint256 ethPerToken_,
    uint64 duration_
)
```

### Parameters

| Name           | Type    | Description                             |
| -------------- | ------- | --------------------------------------- |
| `token_`       | address | ERC20 token contract address being sold |
| `owner_`       | address | Wallet address to receive all ETH funds |
| `ethPerToken_` | uint256 | Price per token in wei                  |
| `duration_`    | uint64  | Claim delay period in seconds           |

## Public Functions

### `buy()`

Allows users to buy tokens with Ether.

* Validates that sender is an EOA
* Reverts if zero Ether is sent
* Calculates token amount using `computeToken`
* Transfers Ether to owner
* Records the purchase with claim timestamp

### `claim()`

Allows users to claim their tokens after the lock duration has passed.

* Reverts if all tokens have already been claimed
* Iterates through unclaimed purchases
* Transfers eligible tokens to the user
* Emits `Claim` event

### `computeToken(uint256 ethAmount_)`

Computes the number of tokens corresponding to the Ether sent.

* Uses ERC20 decimals from token contract
* Returns calculated token amount

### `getUserDetails(address user)`

Returns user's aggregated data:

* Next purchase index eligible for claim
* Total tokens acquired
* Total ETH spent

### `getUserPurchasesAt(address user, uint256 index)`

Returns a specific token purchase record for a user.

### `getUserAllPurchases(address user)`

Returns all purchase records for a user.

## Structs

### `TokenPurchase`

```solidity
struct TokenPurchase {
    uint256 ethSpent;
    uint256 tokenAcquired;
    uint64 claimAt;
}
```

### `UserDetails`

```solidity
struct UserDetails {
    uint256 nextPurchaseIndex;
    uint256 totalTokensAcquired;
    uint256 totalEtherSpent;
    TokenPurchase[] tokenPurchases;
}
```

### `Info`

```solidity
struct Info {
    uint256 totalTokensAcquired;
    uint256 totalEtherSpent;
}
```

## Events

### `Buy`

```solidity
event Buy(address indexed user, uint256 ethAmount, uint256 tknAmount);
```

Emitted when a user purchases tokens.

### `Claim`

```solidity
event Claim(address indexed user, uint256 indexed fromIndex, uint256 indexed toIndex, uint256 tknAmount);
```

Emitted when a user claims eligible tokens.

## Errors

* `ZeroEtherAmount`: No Ether sent during purchase
* `ZeroTokenAcquired`: No tokens to claim
* `AlreadyClaimedAll`: All tokens have been claimed
* `OnlyEOA`: Only externally owned accounts can call `buy`
* `InvalidTokenAddress`: Token address is not a contract
* `EtherTransferFailed`: ETH transfer to owner failed

## Modifiers

### `onlyEoa`

Ensures the function caller is an externally owned account, not a contract.

## Security Considerations

* **ReentrancyGuard** used to prevent reentrant calls
* **SafeERC20** ensures safe transfers of tokens
* **EOA-only check** blocks contracts from calling `buy()`
* **Checks-Effects-Interactions pattern** followed in critical paths

## License

```solidity
// SPDX-License-Identifier: NOLICENSE
```
