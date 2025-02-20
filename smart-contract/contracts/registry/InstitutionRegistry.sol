// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract InstitutionRegistry {
    // Struct to store institution information
    struct Institution {
        string name;
        address owner; // Admin or DAO owner
        uint256 subscriptionFee; // Fee in $PHYSIO tokens
        bool isActive;
    }

    // Mappings
    mapping(address => Institution) public institutions;
    mapping(address => address[]) public institutionDoctors; // Institution -> List of doctors

    // Events
    event InstitutionCreated(address indexed institution, string name);
    event DoctorAddedToInstitution(
        address indexed institution,
        address indexed doctor
    );

    // Modifiers
    modifier onlyDAOOwner() {
        require(msg.sender == daoOwner, "Caller is not the DAO owner");
        _;
    }

    // Constructor
    address public daoOwner;

    constructor() {
        daoOwner = msg.sender;
    }

    // Create a new institution (DAO owner only)
    function createInstitution(
        address institutionAddress,
        string memory name,
        uint256 subscriptionFee
    ) public onlyDAOOwner {
        institutions[institutionAddress] = Institution({
            name: name,
            owner: msg.sender,
            subscriptionFee: subscriptionFee,
            isActive: true
        });

        emit InstitutionCreated(institutionAddress, name);
    }

    // Add a doctor to an institution
    function addDoctorToInstitution(
        address institution,
        address doctor
    ) public {
        require(
            institutions[institution].owner == msg.sender,
            "Caller is not the institution owner"
        );
        institutionDoctors[institution].push(doctor);
        emit DoctorAddedToInstitution(institution, doctor);
    }
}
