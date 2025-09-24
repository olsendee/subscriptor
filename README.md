# Subscriptor Smart Contract

A decentralized subscription management system built on Stacks blockchain using Clarity.

## Overview

Subscriptor enables automatic subscription payments between users and service providers on the Stacks blockchain. It handles STX token locking, automated monthly claims, and proportional refunds for early cancellations.

## Features

- 🔒 **Secure Token Locking**: Users can lock STX tokens for subscription periods
- 💫 **Automated Claims**: Service providers can claim monthly payments automatically
- 💰 **Fair Refunds**: Proportional refunds for early subscription cancellations
- 📊 **Transparent**: Full visibility of subscription status and terms

## Functions

### Public Functions

```clarity
(create-sub (provider principal) (amount uint) (duration uint))
```
- Creates a new subscription
- Locks total payment (amount * duration)
- Returns subscription ID

```clarity
(claim (id uint))
```
- Claims due monthly payments
- Only callable by the service provider
- Transfers STX tokens for claimed months

```clarity
(cancel (id uint))
```
- Cancels active subscription
- Calculates and returns unused funds
- Only callable by subscriber

### Read-Only Functions

```clarity
(get-sub (id uint))
```
- Returns subscription details
- Includes subscriber, provider, amount, duration, etc.

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Subscription not found |
| u101 | Not authorized provider |
| u102 | Not authorized subscriber |
| u103 | Subscription not active |
| u104 | No payment due |
| u200 | Invalid parameters |
| u201 | STX transfer failed |
| u202 | Claim transfer failed |
| u203 | Refund transfer failed |

## Development

```bash
# Clone the repository
git clone https://github.com/yourusername/subscriptor.git

# Install dependencies
cd subscriptor
clarinet install

# Run tests
clarinet test

# Deploy contract (testnet)
clarinet deploy --testnet
```


## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
