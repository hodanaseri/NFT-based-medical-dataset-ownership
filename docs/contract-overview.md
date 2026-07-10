# Smart Contract Overview

## MedicalDatasetNFT.sol

This contract implements the on-chain governance logic for the NFT-based medical dataset framework.

### Key Features

| Feature | Description |
|---------|-------------|
| ERC-721 Compliance | Standard NFT implementation for dataset ownership |
| Merkle Root Anchoring | Cryptographic commitment to dataset integrity |
| Access Control | Programmable time-limited access licenses |
| Sub-licensing | Controlled redistribution with depth limits |
| Audit Trail | Comprehensive event logging |
| Key Recovery | Guardian-based threshold recovery (3-of-5) |
| License Revocation | Immediate on-chain invalidation |

### Gas Costs

Estimated gas costs on Polygon:

| Operation | Gas | Cost (USD) |
|-----------|-----|------------|
| mintDatasetNFT | 180,000-220,000 | $0.15-0.45 |
| requestAccess | 85,000-110,000 | $0.07-0.12 |
| approveAccess | 45,000-60,000 | $0.04-0.06 |
| revokeAccess | 35,000-50,000 | $0.03-0.05 |

### Security

- ReentrancyGuard protection
- Role-based access control
- Formal verification using Certora Prover
- Slither and Mythril audit passed
- OpenZeppelin contracts used
