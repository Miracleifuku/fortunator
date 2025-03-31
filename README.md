# 🎲 Fortunator

A decentralized and transparent random giveaway management system built on Clarity for the Stacks blockchain.

## Overview

Fortunator allows anyone to create, enter, and manage random giveaways in a fully transparent and verifiable way. The smart contract handles everything from creating giveaways with custom parameters to randomly selecting winners using blockchain data as a source of randomness.

## Features

- **Decentralized Giveaway Creation**: Anyone can create a giveaway with custom parameters
- **Flexible Configuration**: Set custom participant limits, entry fees, and timeframes
- **Transparent Winner Selection**: Random winner selection based on blockchain data
- **Simplified Architecture**: No complex token transfers within the contract
- **Full Audit Trail**: All giveaway details are permanently stored on the blockchain

## How It Works

1. **Create a Giveaway**: Set title, description, entry fee, max participants, and entry duration
2. **Enter the Giveaway**: Participants register on the contract
3. **Draw a Winner**: After the entry period ends, the creator can draw a random winner
4. **Prize Distribution**: The prize winner is recorded on the blockchain for off-chain distribution

The contract uses an index-based participant tracking system instead of storing a list directly. This allows for efficient storage and retrieval of participant data without running into list size limitations.

## Functions

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-giveaway` | Get all details about a specific giveaway |
| `get-giveaway-count` | Get the total number of giveaways created |
| `has-user-entered` | Check if a user has entered a specific giveaway |
| `get-participants` | Get the list of participants for a giveaway |
| `get-participant-count` | Get the total number of participants in a giveaway |

### Public Functions

| Function | Description |
|----------|-------------|
| `create-giveaway` | Create a new giveaway with custom parameters |
| `fund-giveaway` | Add funds to a giveaway (for tracking purposes only) |
| `enter-giveaway` | Enter an existing giveaway |
| `draw-winner` | Draw a random winner (creator only) |
| `cancel-giveaway` | Cancel a giveaway (creator only) |

## Error Codes

| Code | Description |
|------|-------------|
| `ERR-NOT-AUTHORIZED` | Caller is not authorized to perform this action |
| `ERR-GIVEAWAY-NOT-FOUND` | The specified giveaway does not exist or is inactive |
| `ERR-ALREADY-ENTERED` | User has already entered this giveaway |
| `ERR-ENTRY-PERIOD-ENDED` | The entry period for this giveaway has ended |
| `ERR-ENTRY-PERIOD-NOT-ENDED` | The entry period for this giveaway has not ended yet |
| `ERR-INSUFFICIENT-FUNDS` | Not enough funds to complete this transaction |
| `ERR-ALREADY-DRAWN` | A winner has already been drawn for this giveaway |
| `ERR-INVALID-PARAMS` | Invalid parameters provided |
| `ERR-NOT-ENOUGH-PARTICIPANTS` | Not enough participants to draw a winner |

## Usage Examples

### Creating a Giveaway

```clarity
(contract-call? .fortunator create-giveaway 
  "Birthday Giveaway" 
  "Giving away 1000 STX for my blockchain birthday!" 
  u100 
  u0 
  u144)
```

This creates a giveaway with:
- Title: "Birthday Giveaway"
- Description: "Giving away 1000 STX for my blockchain birthday!"
- Max participants: 100
- Entry fee: 0 STX (free entry)
- Entry period: 144 blocks (approximately 24 hours)

### Funding a Giveaway (Optional)

```clarity
(contract-call? .fortunator fund-giveaway u1 u1000)
```

This records a fund amount of 1000 for giveaway #1 (for tracking purposes).

### Entering a Giveaway

```clarity
(contract-call? .fortunator enter-giveaway u1)
```

This enters the caller into giveaway #1.

### Drawing a Winner

```clarity
(contract-call? .fortunator draw-winner u1)
```

This selects a random winner for giveaway #1 (only the creator can call this).

## Security Considerations

- The randomness mechanism uses block data as a source of entropy
- The contract tracks prize amounts but does not handle actual token transfers
- Only the creator can draw winners or cancel giveaways
- Entry periods are measured in block height, not time
- Actual prize distribution happens off-chain (the winner is publicly recorded)

## License

This project is released under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.