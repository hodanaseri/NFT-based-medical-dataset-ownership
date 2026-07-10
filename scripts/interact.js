// scripts/interact.js
const hre = require("hardhat");
const fs = require('fs');

async function main() {
    const contractAddress = process.env.CONTRACT_ADDRESS || "0x...";
    const MedicalDatasetNFT = await hre.ethers.getContractFactory("MedicalDatasetNFT");
    const contract = MedicalDatasetNFT.attach(contractAddress);
    
    console.log("Interacting with contract at:", contractAddress);
    
    // Example: Mint a dataset
    const merkleRoot = "0x" + "a".repeat(64);
    const metadataURI = "ipfs://QmExample";
    
    console.log("Minting NFT...");
    const tx = await contract.mintDatasetNFT(merkleRoot, metadataURI);
    await tx.wait();
    
    console.log("NFT minted!");
    console.log("Transaction:", tx.hash);
    
    // Get tokenId from events
    const receipt = await contract.provider.getTransactionReceipt(tx.hash);
    const event = receipt.logs
        .map(log => {
            try {
                return contract.interface.parseLog(log);
            } catch { return null; }
        })
        .filter(e => e && e.name === 'DatasetMinted')[0];
    
    if (event) {
        console.log("Token ID:", event.args.tokenId.toString());
    }
}

main().catch(console.error);
