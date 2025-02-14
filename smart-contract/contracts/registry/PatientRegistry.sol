// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../DIDRegistry.sol"; // Import the DIDRegistry contract;

contract PatientRegistry is DIDRegistry {
    constructor() DIDRegistry() {}

    // Struct to store patient information
    struct PatientInfo {
        string did; // Decentralized Identity
        string biologicalDetails; // Encrypted data
        string nationalID; // Scanned document hash
        string passportPhotoHash; // IPFS hash of passport photo
        address registeredBy; // Doctor who registered the patient
        bool isActive; // Active status
    }

    // Mappings
    mapping(address => PatientInfo) public patients;
    mapping(address => mapping(address => bool)) public doctorAccess; // Doctor -> Patient -> Access

    // Events
    event PatientRegistered(address indexed patient, address indexed doctor);
    event AccessGranted(
        address indexed patient,
        address indexed doctor,
        bool granted
    );

    modifier patientNotRegistered(address patient) {
        require(
            bytes(patients[patient].did).length == 0,
            "Patient already registered"
        );
        _;
    }

    // Grant/revoke access to a patient's record
    function grantAccess(address patient, bool granted) public onlyDoctor {
        require(
            patients[patient].registeredBy == msg.sender,
            "Only registering doctor can modify access"
        );
        doctorAccess[msg.sender][patient] = granted;
        emit AccessGranted(patient, msg.sender, granted);
    }
}
