// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // Updated to latest stable Solidity version

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {DIDRegistry} from "../registries/DIDRegistry.sol";

contract TreatmentPlanNFT is ERC721, ERC721Enumerable, AccessControl {
    // Custom errors for gas optimization
    error PlanNotActive();
    error UnauthorizedCreator();
    error TokenDoesNotExist();
    error PlanAlreadyActive();
    error NotVerifiedDoctor();
    error NotVerifiedPatient();
    error NotPlanCreator();

    // Reference to the DIDRegistry contract
    DIDRegistry public immutable didRegistry;

    // Struct to represent a treatment plan
    struct TreatmentPlan {
        string ipfsHash;
        string creatorDID;
        uint256 createdAt;
        bool isActive;
        uint256 usageCount;
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");

    uint256 public nextTokenId = 1;
    mapping(uint256 tokenId => TreatmentPlan) public treatmentPlans;

    // Events
    event TreatmentPlanCreated(
        uint256 indexed tokenId,
        address indexed creator,
        string ipfsHash
    );
    event TreatmentPlanUsed(uint256 indexed tokenId, address indexed user);
    event TreatmentPlanDeactivated(uint256 indexed tokenId);
    event TreatmentPlanReactivated(uint256 indexed tokenId);

    constructor(
        address _didRegistryAddress
    ) ERC721("TreatmentPlanNFT", "TPNFT") {
        if (_didRegistryAddress == address(0))
            revert("Invalid DID registry address");
        didRegistry = DIDRegistry(_didRegistryAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // Modifiers
    modifier onlyVerifiedDoctor() {
        if (
            !didRegistry.isUserOfType(msg.sender, DIDRegistry.UserType.Doctor)
        ) {
            revert NotVerifiedDoctor();
        }
        _;
    }

    modifier onlyVerifiedPatient() {
        if (
            !didRegistry.isUserOfType(msg.sender, DIDRegistry.UserType.Patient)
        ) {
            revert NotVerifiedPatient();
        }
        _;
    }

    modifier onlyActivePlan(uint256 tokenId) {
        if (!treatmentPlans[tokenId].isActive) revert PlanNotActive();
        _;
    }

    function createTreatmentPlan(
        string memory _ipfsHash
    ) external returns (uint256) {
        // Check if sender is a verified doctor
        (
            string memory did,
            DIDRegistry.UserType userType,
            bool isActive
        ) = didRegistry.getUserInfo(msg.sender);
        require(
            userType == DIDRegistry.UserType.Doctor,
            "Only verified doctors can create plans"
        );
        require(isActive, "Doctor account must be active");

        uint256 tokenId = nextTokenId++;
        _safeMint(msg.sender, tokenId);

        treatmentPlans[tokenId] = TreatmentPlan({
            ipfsHash: _ipfsHash,
            creatorDID: did,
            createdAt: block.timestamp,
            isActive: true,
            usageCount: 0
        });

        emit TreatmentPlanCreated(tokenId, msg.sender, _ipfsHash);
        return tokenId;
    }

    function getTreatmentPlan(
        uint256 tokenId
    )
        external
        view
        returns (
            string memory ipfsHash,
            string memory creatorDID,
            uint256 createdAt,
            bool isActive,
            uint256 usageCount
        )
    {
        if (_ownerOf(tokenId) == address(0)) revert TokenDoesNotExist();

        TreatmentPlan storage plan = treatmentPlans[tokenId];
        return (
            plan.ipfsHash,
            plan.creatorDID,
            plan.createdAt,
            plan.isActive,
            plan.usageCount
        );
    }

    function useTreatmentPlan(
        uint256 tokenId
    ) external onlyVerifiedPatient onlyActivePlan(tokenId) {
        unchecked {
            treatmentPlans[tokenId].usageCount++;
        }
        emit TreatmentPlanUsed(tokenId, msg.sender);
    }

    function deactivateTreatmentPlan(
        uint256 tokenId
    ) external onlyActivePlan(tokenId) {
        (string memory did, , ) = didRegistry.getUserInfo(msg.sender);

        if (
            keccak256(abi.encodePacked(treatmentPlans[tokenId].creatorDID)) !=
            keccak256(abi.encodePacked(did)) &&
            !hasRole(ADMIN_ROLE, msg.sender)
        ) {
            revert UnauthorizedCreator();
        }

        treatmentPlans[tokenId].isActive = false;
        emit TreatmentPlanDeactivated(tokenId);
    }

    function reactivateTreatmentPlan(uint256 tokenId) external {
        if (_ownerOf(tokenId) == address(0)) revert TokenDoesNotExist();
        if (treatmentPlans[tokenId].isActive) revert PlanAlreadyActive();

        (string memory did, , ) = didRegistry.getUserInfo(msg.sender);

        if (
            keccak256(abi.encodePacked(treatmentPlans[tokenId].creatorDID)) !=
            keccak256(abi.encodePacked(did)) &&
            !hasRole(ADMIN_ROLE, msg.sender)
        ) {
            revert UnauthorizedCreator();
        }

        treatmentPlans[tokenId].isActive = true;
        emit TreatmentPlanReactivated(tokenId);
    }

    // Required overrides
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
