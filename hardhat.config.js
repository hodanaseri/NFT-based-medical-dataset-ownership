require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

module.exports = {
    solidity: {
        version: "0.8.19",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    networks: {
        // Local Hardhat network (for testing)
        hardhat: {
            chainId: 1337
        },
        // Local blockchain node
        localhost: {
            url: "http://127.0.0.1:8545"
        },
        // Polygon Amoy Testnet
        amoy: {
            url: `https://polygon-amoy.infura.io/v3/${process.env.INFURA_API_KEY || ""}`,
            accounts: process.env.DEPLOYER_PRIVATE_KEY ? [`0x${process.env.DEPLOYER_PRIVATE_KEY}`] : [],
            gasPrice: 30000000000 // 30 Gwei
        },
        // Ethereum Sepolia Testnet
        sepolia: {
            url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY || ""}`,
            accounts: process.env.DEPLOYER_PRIVATE_KEY ? [`0x${process.env.DEPLOYER_PRIVATE_KEY}`] : [],
            gasPrice: 30000000000
        },
        // Polygon Mainnet
        polygon: {
            url: `https://polygon-mainnet.infura.io/v3/${process.env.INFURA_API_KEY || ""}`,
            accounts: process.env.DEPLOYER_PRIVATE_KEY ? [`0x${process.env.DEPLOYER_PRIVATE_KEY}`] : [],
            gasPrice: 30000000000
        }
    },
    etherscan: {
        apiKey: {
            polygon: process.env.POLYGONSCAN_API_KEY || "",
            polygonAmoy: process.env.POLYGONSCAN_API_KEY || "",
            sepolia: process.env.ETHERSCAN_API_KEY || ""
        }
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts"
    }
};
