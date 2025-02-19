# ConcertPass NFT Ticketing System

A secure and decentralized NFT-based ticketing system built on the Stacks blockchain. This smart contract enables concert organizers to mint, sell, and manage digital concert passes as NFTs, while providing concert-goers with verifiable ownership and transfer capabilities.

## Features

- **NFT-Based Tickets**: Each concert pass is minted as a unique NFT, providing proof of ownership and preventing counterfeiting
- **Flexible Concert Management**: Organizers can create, update, and cancel concerts
- **Capacity Controls**: Built-in venue capacity management to prevent overselling
- **Secure Transfers**: Pass holders can safely transfer their tickets to other users
- **Refund System**: Automatic refund processing for cancelled events

## Smart Contract Functions

### For Concert Organizers

- `mint-pass`: Create a new concert pass with specified details
- `update-concert-details`: Modify concert information before any passes are sold
- `cancel-concert`: Cancel a concert and enable refunds

### For Concert-Goers

- `purchase-pass`: Buy a concert pass
- `transfer-pass`: Transfer pass ownership to another user
- `refund-pass`: Get a refund for cancelled concerts

### Read-Only Functions

- `get-pass-owner`: Check the current owner of a pass
- `get-pass-metadata`: View concert details for a specific pass

## Data Structures

### Pass Metadata
```clarity
{
    concert-name: string-ascii,
    show-time: string-ascii,
    pass-price: uint,
    venue-capacity: uint,
    tickets-sold: uint,
    is-cancelled: bool
}
```

## Error Codes

- `ERR-NOT-OWNER (u100)`: Operation restricted to contract owner
- `ERR-PASS-ALREADY-MINTED (u101)`: Pass ID already exists
- `ERR-PASS-NOT-FOUND (u102)`: Pass ID doesn't exist
- `ERR-UNAUTHORIZED-TRANSFER (u103)`: Transfer attempted by non-owner
- `ERR-INVALID-INPUT (u104)`: Invalid input parameters
- `ERR-VENUE-FULL (u105)`: No more passes available
- `ERR-SHOW-ALREADY-CANCELLED (u106)`: Concert already cancelled
- `ERR-REFUND-FAILED (u107)`: Refund transaction failed
- `ERR-PASSES-ALREADY-SOLD (u108)`: Cannot modify concert after sales
- `ERR-INVALID-TRANSFER-RECIPIENT (u109)`: Invalid transfer recipient

## Security Features

- Input validation for all public functions
- Ownership verification for transfers and refunds
- Capacity control to prevent overselling
- Protection against unauthorized concert modifications
- Safe transfer mechanisms

## Development

This contract is written in Clarity and designed for deployment on the Stacks blockchain. It follows best practices for NFT contracts and includes comprehensive error handling.

