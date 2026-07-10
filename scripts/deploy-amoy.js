// scripts/deploy-amoy.js
const hre = require("hardhat");
const fs = require('fs');
require('dotenv').config();

async function main() {
    console.log("Deploying to Polygon Amoy Testnet...");
    
    const MedicalDatasetNFT = await hre.ethers.getContractFactory("MedicalDatasetNFT");
    const contract = await MedicalDatasetNFT.deploy();
    await contract.deployed();
    
    console.log("Contract Address:", contract.address);
    console.log("Network: Polygon Amoy");
    console.log("Tx Hash:", contract.deployTransaction.hash);
    
    // Verify on Polygonscan
    console.log("Waiting for verification...");
    await new Promise(resolve => setTimeout(resolve, 30000));
    
    try {
        await hre.run("verify:verify", {
            address: contract.address,
            constructorArguments: [],
        });
        console.log("Contract verified on Polygonscan");
    } catch (e) {
        console.log("Verification failed:", e.message);
    }
    
    // Save deployment
    fs.writeFileSync(
        'deployment-amoy.json',
        JSON.stringify({
            address: contract.address,
            network: 'amoy',
            deployTx: contract.deployTransaction.hash,
            timestamp: new Date().toISOString()
        }, null, 2)
    );
}

main().catch(console.error);
