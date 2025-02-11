// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TreatmentPlan is ERC721, AccessControl {
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");

    uint256 public totalPlans;
    mapping(uint256 => string) public treatmentPlanMetadata;

    constructor() ERC721("TreatmentPlan", "TP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Mint a new treatment plan as an NFT
    function createTreatmentPlan(address patient, string memory ipfsHash) external onlyRole(DOCTOR_ROLE) {
        _mint(patient, totalPlans);
        treatmentPlanMetadata[totalPlans] = ipfsHash;
        totalPlans++;
    }

    // Retrieve metadata for a specific treatment plan
    function getPlanMetadata(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        return treatmentPlanMetadata[tokenId];
    }

    // Retrieve all treatment plans for a specific patient
    function getPatientPlans(address patient) external view returns (uint256[] memory) {
        uint256[] memory planIds = new uint256[](balanceOf(patient));
        for (uint256 i = 0; i < balanceOf(patient); i++) {
            planIds[i] = tokenOfOwnerByIndex(patient, i);
        }
        return planIds;
    }
}

// Purpose : Manages treatment plans stored as NFTs.
// Key Features :
    // Mint treatment plans as NFTs.
    // Store metadata (e.g., exercise details) on IPFS.
    // Retrieve treatment plans for patients and doctors.