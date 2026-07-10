// scripts/deploy.js
const hre = require("hardhat");
const fs = require('fs');

async function main() {
    console.log("Deploying MedicalDatasetNFT...");
    console.log("Network:", hre.network.name);
    
    const MedicalDatasetNFT = await hre.ethers.getContractFactory("MedicalDatasetNFT");
    const contract = await MedicalDatasetNFT.deploy();
    await contract.deployed();
    
    console.log("MedicalDatasetNFT deployed to:", contract.address);
    console.log("Block Number:", await ethers.provider.getBlockNumber());
    
    // Save deployment info
    const deploymentInfo = {
        address: contract.address,
        network: hre.network.name,
        blockNumber: await ethers.provider.getBlockNumber(),
        deployTx: contract.deployTransaction.hash,
        timestamp: new Date().toISOString()
    };
    
    fs.writeFileSync(
        `deployment-${hre.network.name}.json`,
        JSON.stringify(deploymentInfo, null, 2)
    );
    
    console.log("Deployment info saved to:", `deployment-${hre.network.name}.json`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
