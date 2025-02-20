// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract DoctorRegistry is AccessControl {
    // Define ADMIN_ROLE constant
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Struct to store doctor information
    struct DoctorInfo {
        string did; // Decentralized Identity
        string licenseNumber; // Academic credential
        string nationalID; // Scanned document hash
        string passportPhotoHash; // IPFS hash of passport photo
        bool isVerified; // Verification status
        bool isActive; // Active status
        uint256 deactivatedAt; // Timestamp of deactivation
    }

    // Mappings
    mapping(address => DoctorInfo) public doctors;
    mapping(string => bool) private usedLicenseNumbers;

    // Events
    event DoctorRegistered(
        address indexed doctor,
        string did,
        string licenseNumber
    );
    event DoctorVerified(address indexed doctor, bool isVerified);
    event DoctorDeactivated(address indexed doctor);

    // Modifiers
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    modifier doctorNotRegistered(address doctor) {
        require(
            bytes(doctors[doctor].licenseNumber).length == 0,
            "Doctor already registered"
        );
        _;
    }

    // Constructor
    constructor() {
        // Grant the deployer the ADMIN_ROLE
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // Register a new doctor
    function registerDoctor(
        address doctor,
        string memory did,
        string memory licenseNumber,
        string memory nationalID,
        string memory passportPhotoHash
    ) public doctorNotRegistered(doctor) {
        require(
            !usedLicenseNumbers[licenseNumber],
            "License number already in use"
        );

        doctors[doctor] = DoctorInfo({
            did: did,
            licenseNumber: licenseNumber,
            nationalID: nationalID,
            passportPhotoHash: passportPhotoHash,
            isVerified: false,
            isActive: true,
            deactivatedAt: 0
        });

        usedLicenseNumbers[licenseNumber] = true;
        emit DoctorRegistered(doctor, did, licenseNumber);
    }

    // Verify a doctor (admin-only)
    function verifyDoctor(address doctor, bool isVerified) public onlyAdmin {
        doctors[doctor].isVerified = isVerified;
        emit DoctorVerified(doctor, isVerified);
    }

    // Deactivate a doctor (admin-only)
    function deactivateDoctor(address doctor) public onlyAdmin {
        require(doctors[doctor].isActive, "Doctor already inactive");
        doctors[doctor].isActive = false;
        doctors[doctor].deactivatedAt = block.timestamp;
        emit DoctorDeactivated(doctor);
    }
}
