// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../monitoring/WearableDataIntegration.sol";

contract PatientProfile is AccessControl, Pausable {
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Profile {
        string ipfsHash; // IPFS hash containing detailed profile data
        address[] authorizedDoctors;
        bool isActive;
        uint256 lastUpdated;
        EmergencyContact emergencyContact;
        uint256[] activeTreatmentPlans;
        address wearableDataSource;
    }

    struct EmergencyContact {
        string name;
        string contactInfo;
        string relationship;
    }

    mapping(address => Profile) public profiles;
    mapping(address => mapping(address => bool)) public doctorAuthorizations;

    WearableDataIntegration public wearableData;

    event ProfileCreated(address indexed patient, string ipfsHash);
    event ProfileUpdated(address indexed patient, string newIpfsHash);
    event DoctorAuthorized(address indexed patient, address indexed doctor);
    event DoctorDeauthorized(address indexed patient, address indexed doctor);
    event EmergencyContactUpdated(address indexed patient);
    event WearableDataSourceUpdated(
        address indexed patient,
        address dataSource
    );

    constructor(address _wearableDataAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        wearableData = WearableDataIntegration(_wearableDataAddress);
    }

    function createProfile(
        string memory _ipfsHash,
        EmergencyContact memory _emergencyContact
    ) external {
        require(!profiles[msg.sender].isActive, "Profile already exists");

        profiles[msg.sender] = Profile({
            ipfsHash: _ipfsHash,
            authorizedDoctors: new address[](0),
            isActive: true,
            lastUpdated: block.timestamp,
            emergencyContact: _emergencyContact,
            activeTreatmentPlans: new uint256[](0),
            wearableDataSource: address(0)
        });

        _grantRole(PATIENT_ROLE, msg.sender);
        emit ProfileCreated(msg.sender, _ipfsHash);
    }

    function updateProfile(
        string memory _newIpfsHash
    ) external onlyRole(PATIENT_ROLE) whenNotPaused {
        require(profiles[msg.sender].isActive, "Profile not found");
        profiles[msg.sender].ipfsHash = _newIpfsHash;
        profiles[msg.sender].lastUpdated = block.timestamp;
        emit ProfileUpdated(msg.sender, _newIpfsHash);
    }

    function authorizeDoctor(
        address doctor
    ) external onlyRole(PATIENT_ROLE) whenNotPaused {
        require(hasRole(DOCTOR_ROLE, doctor), "Address is not a doctor");
        require(
            !doctorAuthorizations[msg.sender][doctor],
            "Doctor already authorized"
        );

        doctorAuthorizations[msg.sender][doctor] = true;
        profiles[msg.sender].authorizedDoctors.push(doctor);
        emit DoctorAuthorized(msg.sender, doctor);
    }

    function deauthorizeDoctor(
        address doctor
    ) external onlyRole(PATIENT_ROLE) whenNotPaused {
        require(
            doctorAuthorizations[msg.sender][doctor],
            "Doctor not authorized"
        );

        doctorAuthorizations[msg.sender][doctor] = false;
        // Remove doctor from authorizedDoctors array
        Profile storage profile = profiles[msg.sender];
        for (uint i = 0; i < profile.authorizedDoctors.length; i++) {
            if (profile.authorizedDoctors[i] == doctor) {
                profile.authorizedDoctors[i] = profile.authorizedDoctors[
                    profile.authorizedDoctors.length - 1
                ];
                profile.authorizedDoctors.pop();
                break;
            }
        }
        emit DoctorDeauthorized(msg.sender, doctor);
    }

    function updateEmergencyContact(
        EmergencyContact memory _newContact
    ) external onlyRole(PATIENT_ROLE) whenNotPaused {
        profiles[msg.sender].emergencyContact = _newContact;
        emit EmergencyContactUpdated(msg.sender);
    }

    function setWearableDataSource(
        address _dataSource
    ) external onlyRole(PATIENT_ROLE) whenNotPaused {
        profiles[msg.sender].wearableDataSource = _dataSource;
        emit WearableDataSourceUpdated(msg.sender, _dataSource);
    }

    function addTreatmentPlan(
        uint256 planId
    ) external onlyRole(DOCTOR_ROLE) whenNotPaused {
        require(
            doctorAuthorizations[msg.sender][tx.origin],
            "Doctor not authorized"
        );
        profiles[msg.sender].activeTreatmentPlans.push(planId);
    }

    function getProfile(
        address patient
    )
        external
        view
        returns (
            string memory ipfsHash,
            address[] memory authorizedDoctors,
            bool isActive,
            uint256 lastUpdated,
            EmergencyContact memory emergencyContact,
            uint256[] memory activeTreatmentPlans,
            address wearableDataSource
        )
    {
        require(
            msg.sender == patient ||
                doctorAuthorizations[patient][msg.sender] ||
                hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized to view profile"
        );

        Profile storage profile = profiles[patient];
        return (
            profile.ipfsHash,
            profile.authorizedDoctors,
            profile.isActive,
            profile.lastUpdated,
            profile.emergencyContact,
            profile.activeTreatmentPlans,
            profile.wearableDataSource
        );
    }

    // Admin functions
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Override required function
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
