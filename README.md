# NFT-based Medical Dataset Ownership

> Prototype implementation of an NFT-based framework for secure medical dataset ownership, controlled access governance, and post-distribution accountability.

---

##  Overview

This repository contains a research prototype implementation of an NFT-based framework for secure medical dataset ownership, controlled access governance, and post-distribution accountability.

The framework is designed to address key challenges in medical data sharing environments, including:

- **Preservation of dataset ownership**
- **Cryptographic integrity verification**
- **Fine-grained and revocable access control**
- **Immutable audit logging**
- **Leakage traceability and forensic reconstruction**
- **Secure key custody and recovery mechanisms**

This implementation accompanies the research study proposing an integrated blockchain architecture for medical data governance. It is intended for academic validation and reproducibility purposes.

---

## Dataset

The framework was evaluated using the **OpenNeuro DS007328** dataset, a dense longitudinal single-subject multimodal neuroimaging dataset.

| Property | Details |
|----------|---------|
| **Dataset Name** | OpenNeuro DS007328 |
| **URL** | [https://openneuro.org/datasets/ds007328](https://openneuro.org/datasets/ds007328) |
| **Total Files** | 3,151 files |
| **Modalities** | Resting-state fMRI, T1-weighted structural MRI, Diffusion Tensor Imaging (DTI) |
| **fMRI Runs** | 458 runs across 243 sessions (85 hours total) |
| **Structural Scans** | 195 T1-weighted scans |
| **DTI Sessions** | 54 DTI sessions |
| **Metadata** | Behavioral, physiological, and pharmacological data |
| **License** | CC0 (public domain) |
| **Anonymization** | Fully anonymized |

The dataset is publicly available and was used to benchmark the framework's performance across:

- SHA-256 hashing and Merkle Tree construction (3,151 files)
- Ephemeral key derivation and AES-256 decryption (20‑file subset)
- Scalability testing (100, 500, 1,000, 2,000, and 3,151 files)
- Concurrent access simulation (10, 50, 100, and 200 simultaneous users)
- Watermark robustness evaluation (30 T1‑weighted MRI slices)

---
## Architectural Summary

The system combines off-chain encrypted storage with on-chain governance logic.

### Core Components

| Component | Description |
|-----------|-------------|
| **NFT-Based Ownership Representation** | Each dataset is represented as an ERC-721 token. The NFT metadata includes a Merkle Root derived from encrypted dataset files stored off-chain. |
| **Merkle Tree Integrity Anchoring** | Encrypted files are hashed using SHA-256 and aggregated into a Merkle Tree. The resulting Merkle Root is stored on-chain to provide tamper-evident dataset integrity. |
| **Smart Contract–Driven Access Control** | Access requests, approvals, revocations, and ownership transfers are managed through smart contracts deployed on an EVM-compatible blockchain. |
| **Ephemeral Key Enforcement** | Access to encrypted datasets is controlled via time-bound decryption keys issued upon approval. |
| **Auditability and Event Logging** | All governance actions (minting, transfer, access approval, revocation) emit on-chain events for transparent and immutable auditing. |
| **Forensic Accountability Layer** | The design supports integration with watermarking and perceptual fingerprinting mechanisms for leakage attribution. |

---

## Technology Stack

| Layer | Technology |
|-------|------------|
| **Smart Contracts** | Solidity (v0.8.x), ERC-721 standard |
| **Development** | Hardhat development environment |
| **Cryptography** | SHA-256 hashing, AES-256-GCM encryption |
| **Client** | Python (Merkle construction and encryption utilities) |
| **Blockchain Networks** | EVM-compatible (Polygon, Ethereum, and other Ethereum-compatible chains) |

---

## Example Workflow

1. **Prepare and anonymize** medical dataset (performed off-chain).
2. **Encrypt** dataset files using AES-256-GCM.
3. **Generate** SHA-256 hashes and build a Merkle Tree.
4. **Store** encrypted files in decentralized storage (e.g., IPFS).
5. **Mint** NFT containing the Merkle Root and dataset metadata.
6. **Researcher** submits access request via smart contract.
7. **Data owner** approves or rejects request.
8. **Upon approval**, ephemeral decryption key is issued.
9. **All actions** are recorded as immutable on-chain events.

---

## Security Considerations

- Sensitive medical data are **never stored on-chain**.
- Encryption is applied **before uploading** to decentralized storage.
- Smart contracts **enforce access governance** rules.
- Key custody mechanisms must be **deployed in secure environments**.

> **Important:** This prototype does not include production-grade key management infrastructure and should **not be used in clinical environments** without further security validation.

---

## Research Context

This repository supports a research study proposing a unified NFT-based governance architecture for medical datasets. The prototype demonstrates feasibility of:

- Ownership-transfer versus licensed-access separation
- Merkle-root integrity binding
- On-chain evidence packaging
- Custodial key recovery integration

The implementation is provided to enable **transparency and reproducibility**.

---

## License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.
