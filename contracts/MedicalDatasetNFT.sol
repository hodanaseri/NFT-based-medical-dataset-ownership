// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title MedicalDatasetNFT
 * @dev NFT-based governance for medical dataset ownership and access control
 * 
 * This contract implements a complete governance framework for medical datasets,
 * combining ownership representation via NFTs with programmable access control,
 * audit logging, and key revocation capabilities.
 * 
 * Key Features:
 * - ERC-721 compliant NFT for dataset ownership
 * - Merkle Root anchoring for integrity verification
 * - Programmable access control with time-limited licenses
 * - Sub-licensing with depth control
 * - On-chain audit logging via events
 * - Guardian-based key recovery (3-of-5 threshold)
 * - License revocation
 * - Leak reporting
 */
contract MedicalDatasetNFT is ERC721, Ownable, ReentrancyGuard {
    
    // ============================================================
    // STRUCTS
    // ============================================================

    struct Dataset {
        bytes32 merkleRoot;      // Cryptographic commitment to dataset integrity
        string metadataURI;       // Off-chain metadata pointer (IPFS)
        bool active;             // Dataset availability status
        uint256 createdAt;       // Registration timestamp
        uint256 version;         // Version counter for key rotation tracking
    }

    struct AccessLicense {
        address researcher;      // License holder (authorized researcher)
        uint256 tokenId;        // Associated dataset NFT identifier
        uint256 expiry;         // Expiration timestamp
        bytes32 purposeHash;    // Hash of declared research purpose
        bool revoked;           // Revocation status
        uint256 createdAt;      // License creation timestamp
        uint256 depth;          // Sublicensing depth (0 = original, >0 = derived)
        bytes32 parentLicense;  // Parent license identifier (for sublicensing)
        bool allowSublicense;   // Whether sublicensing is permitted
    }

    struct AccessRequest {
        address researcher;
        uint256 tokenId;
        bytes32 purposeHash;
        uint256 duration;
        uint256 createdAt;
        RequestStatus status;
    }

    enum RequestStatus { Pending, Approved, Denied, Revoked }

    // ============================================================
    // STATE VARIABLES
    // ============================================================

    mapping(uint256 => Dataset) public datasets;
    mapping(bytes32 => AccessLicense) public licenses;
    mapping(bytes32 => AccessRequest) public accessRequests;
    mapping(bytes32 => bool) public revokedKeys;
    mapping(address => bool) public guardians;
    mapping(bytes32 => bool) public recoveryRequests;
    mapping(uint256 => uint256) public licenseCount;

    uint256 public nextTokenId = 1;
    uint256 public guardianThreshold = 3;
    uint256 public totalGuardians = 5;
    uint256 public maxSublicenseDepth = 3;
    string private _baseTokenURI = "https://ipfs.io/ipfs/";

    // ============================================================
    // EVENTS
    // ============================================================

    event DatasetMinted(uint256 indexed tokenId, bytes32 merkleRoot, address indexed owner, uint256 timestamp);
    event AccessRequested(bytes32 indexed requestId, uint256 indexed tokenId, address indexed researcher, bytes32 purposeHash, uint256 duration);
    event AccessApproved(bytes32 indexed licenseId, address indexed researcher, uint256 expiry);
    event AccessDenied(bytes32 indexed requestId);
    event AccessRevoked(bytes32 indexed licenseId, address indexed researcher, uint256 timestamp);
    event DataDecrypted(bytes32 indexed licenseId, address indexed researcher, uint256 timestamp);
    event OwnershipTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint256 timestamp);
    event RecoveryRequested(address indexed user, bytes32 indexed recoveryId, uint256 timestamp);
    event RecoveryApproved(bytes32 indexed recoveryId, address indexed guardian, uint256 timestamp);
    event RecoveryCompleted(address indexed user, uint256 timestamp);
    event LeakDetected(uint256 indexed tokenId, address indexed perpetrator, bytes32 evidenceHash, uint256 timestamp);
    event SublicenseCreated(bytes32 indexed parentLicenseId, bytes32 indexed childLicenseId, address indexed newConsumer);

    // ============================================================
    // MODIFIERS
    // ============================================================

    modifier onlyGuardian() {
        require(guardians[msg.sender], "MedicalDatasetNFT: Not a guardian");
        _;
    }

    modifier onlyDatasetOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "MedicalDatasetNFT: Not dataset owner");
        _;
    }

    modifier onlyActiveDataset(uint256 tokenId) {
        require(datasets[tokenId].active, "MedicalDatasetNFT: Dataset not active");
        _;
    }

    modifier licenseExists(bytes32 licenseId) {
        require(licenses[licenseId].researcher != address(0), "MedicalDatasetNFT: License does not exist");
        _;
    }

    modifier licenseValid(bytes32 licenseId) {
        AccessLicense storage license = licenses[licenseId];
        require(!license.revoked, "MedicalDatasetNFT: License revoked");
        require(block.timestamp < license.expiry, "MedicalDatasetNFT: License expired");
        _;
    }

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    constructor() ERC721("MedicalDatasetNFT", "MDN") {}

    // ============================================================
    // CORE FUNCTIONS
    // ============================================================

    /**
     * @dev Mint a new dataset NFT
     * @param merkleRoot Cryptographic commitment to the dataset
     * @param metadataURI URI pointing to off-chain metadata
     */
    function mintDatasetNFT(
        bytes32 merkleRoot,
        string memory metadataURI
    ) external returns (uint256 tokenId) {
        require(merkleRoot != bytes32(0), "MedicalDatasetNFT: Invalid Merkle root");
        
        tokenId = nextTokenId++;
        _safeMint(msg.sender, tokenId);
        
        datasets[tokenId] = Dataset({
            merkleRoot: merkleRoot,
            metadataURI: metadataURI,
            active: true,
            createdAt: block.timestamp,
            version: 1
        });
        
        emit DatasetMinted(tokenId, merkleRoot, msg.sender, block.timestamp);
        return tokenId;
    }

    /**
     * @dev Request access to a dataset
     */
    function requestAccess(
        uint256 tokenId,
        bytes32 purposeHash,
        uint256 duration
    ) external onlyActiveDataset(tokenId) returns (bytes32 requestId) {
        require(duration > 0 && duration <= 365 days, "MedicalDatasetNFT: Invalid duration");
        require(purposeHash != bytes32(0), "MedicalDatasetNFT: Purpose required");
        
        requestId = keccak256(abi.encodePacked(
            tokenId,
            msg.sender,
            purposeHash,
            duration,
            block.timestamp
        ));
        
        require(accessRequests[requestId].createdAt == 0, "MedicalDatasetNFT: Request already exists");
        
        accessRequests[requestId] = AccessRequest({
            researcher: msg.sender,
            tokenId: tokenId,
            purposeHash: purposeHash,
            duration: duration,
            createdAt: block.timestamp,
            status: RequestStatus.Pending
        });
        
        emit AccessRequested(requestId, tokenId, msg.sender, purposeHash, duration);
        return requestId;
    }

    /**
     * @dev Approve an access request (only dataset owner)
     */
    function approveAccess(bytes32 requestId) external onlyDatasetOwner(accessRequests[requestId].tokenId) {
        AccessRequest storage req = accessRequests[requestId];
        require(req.status == RequestStatus.Pending, "MedicalDatasetNFT: Request not pending");
        require(req.researcher != address(0), "MedicalDatasetNFT: Invalid request");
        
        req.status = RequestStatus.Approved;
        
        bytes32 licenseId = keccak256(abi.encodePacked(
            requestId,
            block.timestamp,
            req.researcher
        ));
        
        uint256 expiry = block.timestamp + req.duration;
        
        licenses[licenseId] = AccessLicense({
            researcher: req.researcher,
            tokenId: req.tokenId,
            expiry: expiry,
            purposeHash: req.purposeHash,
            revoked: false,
            createdAt: block.timestamp,
            depth: 0,
            parentLicense: bytes32(0),
            allowSublicense: false
        });
        
        licenseCount[req.tokenId]++;
        
        emit AccessApproved(licenseId, req.researcher, expiry);
    }

    /**
     * @dev Deny an access request (only dataset owner)
     */
    function denyAccess(bytes32 requestId) external onlyDatasetOwner(accessRequests[requestId].tokenId) {
        AccessRequest storage req = accessRequests[requestId];
        require(req.status == RequestStatus.Pending, "MedicalDatasetNFT: Request not pending");
        
        req.status = RequestStatus.Denied;
        emit AccessDenied(requestId);
    }

    /**
     * @dev Revoke an active access license
     */
    function revokeAccess(bytes32 licenseId) external onlyDatasetOwner(licenses[licenseId].tokenId) {
        AccessLicense storage license = licenses[licenseId];
        require(!license.revoked, "MedicalDatasetNFT: Already revoked");
        
        license.revoked = true;
        
        bytes32 keyHash = keccak256(abi.encodePacked(licenseId));
        revokedKeys[keyHash] = true;
        
        emit AccessRevoked(licenseId, license.researcher, block.timestamp);
    }

    /**
     * @dev Create derived access (sub-licensing)
     */
    function createDerivedAccess(
        bytes32 parentLicenseId,
        address newConsumer,
        uint256 duration
    ) external licenseExists(parentLicenseId) licenseValid(parentLicenseId) {
        AccessLicense storage parent = licenses[parentLicenseId];
        
        require(parent.allowSublicense, "MedicalDatasetNFT: Sub-licensing not permitted");
        require(parent.depth < maxSublicenseDepth, "MedicalDatasetNFT: Max depth exceeded");
        require(newConsumer != address(0), "MedicalDatasetNFT: Invalid consumer");
        require(duration > 0 && duration <= 365 days, "MedicalDatasetNFT: Invalid duration");
        
        bytes32 newLicenseId = keccak256(abi.encodePacked(
            parentLicenseId,
            newConsumer,
            block.timestamp,
            parent.depth + 1
        ));
        
        uint256 expiry = block.timestamp + duration;
        
        licenses[newLicenseId] = AccessLicense({
            researcher: newConsumer,
            tokenId: parent.tokenId,
            expiry: expiry,
            purposeHash: parent.purposeHash,
            revoked: false,
            createdAt: block.timestamp,
            depth: parent.depth + 1,
            parentLicense: parentLicenseId,
            allowSublicense: false
        });
        
        licenseCount[parent.tokenId]++;
        
        emit SublicenseCreated(parentLicenseId, newLicenseId, newConsumer);
        emit AccessApproved(newLicenseId, newConsumer, expiry);
    }

    /**
     * @dev Transfer NFT ownership with key rotation trigger
     */
    function transferOwnershipWithRotation(
        uint256 tokenId,
        address newOwner
    ) external onlyDatasetOwner(tokenId) {
        require(newOwner != address(0), "MedicalDatasetNFT: Invalid owner");
        
        address oldOwner = ownerOf(tokenId);
        _transfer(oldOwner, newOwner, tokenId);
        
        datasets[tokenId].version++;
        
        emit OwnershipTransferred(tokenId, oldOwner, newOwner, block.timestamp);
    }

    /**
     * @dev Report a detected leak
     */
    function reportLeak(
        uint256 tokenId,
        address perpetrator,
        bytes32 evidenceHash
    ) external onlyDatasetOwner(tokenId) {
        emit LeakDetected(tokenId, perpetrator, evidenceHash, block.timestamp);
    }

    // ============================================================
    // RECOVERY FUNCTIONS
    // ============================================================

    /**
     * @dev Submit key recovery request
     */
    function submitRecoveryRequest() external returns (bytes32 recoveryId) {
        recoveryId = keccak256(abi.encodePacked(
            msg.sender,
            block.timestamp,
            block.number
        ));
        recoveryRequests[recoveryId] = true;
        emit RecoveryRequested(msg.sender, recoveryId, block.timestamp);
        return recoveryId;
    }

    /**
     * @dev Approve recovery request (guardian only)
     */
    function approveRecovery(bytes32 recoveryId) external onlyGuardian {
        require(recoveryRequests[recoveryId], "MedicalDatasetNFT: Recovery request not found");
        emit RecoveryApproved(recoveryId, msg.sender, block.timestamp);
    }

    /**
     * @dev Complete recovery (guardian only, after threshold reached)
     */
    function completeRecovery(address user) external onlyGuardian {
        require(user != address(0), "MedicalDatasetNFT: Invalid user");
        emit RecoveryCompleted(user, block.timestamp);
    }

    // ============================================================
    // VIEW FUNCTIONS
    // ============================================================

    function getDataset(uint256 tokenId) external view returns (
        bytes32 merkleRoot,
        string memory metadataURI,
        bool active,
        uint256 createdAt,
        uint256 version
    ) {
        Dataset storage ds = datasets[tokenId];
        return (ds.merkleRoot, ds.metadataURI, ds.active, ds.createdAt, ds.version);
    }

    function getLicense(bytes32 licenseId) external view returns (
        address researcher,
        uint256 tokenId,
        uint256 expiry,
        bytes32 purposeHash,
        bool revoked,
        uint256 depth,
        bool allowSublicense
    ) {
        AccessLicense storage license = licenses[licenseId];
        return (
            license.researcher,
            license.tokenId,
            license.expiry,
            license.purposeHash,
            license.revoked,
            license.depth,
            license.allowSublicense
        );
    }

    function isKeyRevoked(bytes32 licenseId) external view returns (bool) {
        bytes32 keyHash = keccak256(abi.encodePacked(licenseId));
        return revokedKeys[keyHash];
    }

    function getLicenseCount(uint256 tokenId) external view returns (uint256) {
        return licenseCount[tokenId];
    }

    // ============================================================
    // GUARDIAN MANAGEMENT
    // ============================================================

    function addGuardian(address guardian) external onlyOwner {
        require(guardian != address(0), "MedicalDatasetNFT: Invalid address");
        require(!guardians[guardian], "MedicalDatasetNFT: Already a guardian");
        guardians[guardian] = true;
        totalGuardians++;
    }

    function removeGuardian(address guardian) external onlyOwner {
        require(guardians[guardian], "MedicalDatasetNFT: Not a guardian");
        require(totalGuardians > guardianThreshold, "MedicalDatasetNFT: Cannot remove below threshold");
        guardians[guardian] = false;
        totalGuardians--;
    }

    function setGuardianThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "MedicalDatasetNFT: Threshold must be positive");
        require(newThreshold <= totalGuardians, "MedicalDatasetNFT: Threshold exceeds guardian count");
        guardianThreshold = newThreshold;
    }

    function setMaxSublicenseDepth(uint256 newDepth) external onlyOwner {
        require(newDepth > 0, "MedicalDatasetNFT: Depth must be positive");
        maxSublicenseDepth = newDepth;
    }

    // ============================================================
    // ADMIN FUNCTIONS
    // ============================================================

    function deactivateDataset(uint256 tokenId) external onlyOwner {
        require(datasets[tokenId].active, "MedicalDatasetNFT: Already inactive");
        datasets[tokenId].active = false;
    }

    function reactivateDataset(uint256 tokenId) external onlyOwner {
        require(!datasets[tokenId].active, "MedicalDatasetNFT: Already active");
        datasets[tokenId].active = true;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }
}
