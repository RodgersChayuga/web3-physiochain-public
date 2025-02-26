// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../treatment/TreatmentPlanNFT.sol";

contract DoctorProfile is AccessControl, Pausable {
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    struct Profile {
        string ipfsHash; // IPFS hash containing detailed profile data
        Credentials credentials;
        Specialization[] specializations;
        address[] activePatients;
        uint256[] createdTreatmentPlans;
        bool isVerified;
        bool isActive;
        uint256 lastUpdated;
        WorkingHours workingHours;
        uint256 consultationFee;
    }

    struct Credentials {
        string licenseNumber;
        string issuingAuthority;
        uint256 issueDate;
        uint256 expiryDate;
        bool isVerified;
    }

    struct Specialization {
        string name;
        string certification;
        bool isVerified;
    }

    struct WorkingHours {
        uint8[7] startHours; // 0-23 for each day of week
        uint8[7] endHours; // 0-23 for each day of week
        bool[7] workingDays; // true if working on that day
    }

    mapping(address => Profile) public profiles;
    mapping(address => mapping(address => bool)) public patientAssociations;

    TreatmentPlanNFT public treatmentPlanContract;

    event ProfileCreated(address indexed doctor, string ipfsHash);
    event ProfileUpdated(address indexed doctor, string newIpfsHash);
    event CredentialsVerified(address indexed doctor, string licenseNumber);
    event SpecializationAdded(
        address indexed doctor,
        string specializationName
    );
    event PatientAssociated(address indexed doctor, address indexed patient);
    event PatientDissociated(address indexed doctor, address indexed patient);
    event WorkingHoursUpdated(address indexed doctor);
    event ConsultationFeeUpdated(address indexed doctor, uint256 newFee);

    constructor(address _treatmentPlanAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        treatmentPlanContract = TreatmentPlanNFT(_treatmentPlanAddress);
    }

    function createProfile(
        string memory _ipfsHash,
        Credentials memory _credentials,
        WorkingHours memory _workingHours,
        uint256 _consultationFee
    ) external {
        require(!profiles[msg.sender].isActive, "Profile already exists");

        profiles[msg.sender] = Profile({
            ipfsHash: _ipfsHash,
            credentials: _credentials,
            specializations: new Specialization[](0),
            activePatients: new address[](0),
            createdTreatmentPlans: new uint256[](0),
            isVerified: false,
            isActive: true,
            lastUpdated: block.timestamp,
            workingHours: _workingHours,
            consultationFee: _consultationFee
        });

        _grantRole(DOCTOR_ROLE, msg.sender);
        emit ProfileCreated(msg.sender, _ipfsHash);
    }

    function updateProfile(
        string memory _newIpfsHash
    ) external onlyRole(DOCTOR_ROLE) whenNotPaused {
        require(profiles[msg.sender].isActive, "Profile not found");
        profiles[msg.sender].ipfsHash = _newIpfsHash;
        profiles[msg.sender].lastUpdated = block.timestamp;
        emit ProfileUpdated(msg.sender, _newIpfsHash);
    }

    function addSpecialization(
        Specialization memory _specialization
    ) external onlyRole(DOCTOR_ROLE) whenNotPaused {
        profiles[msg.sender].specializations.push(_specialization);
        emit SpecializationAdded(msg.sender, _specialization.name);
    }

    function verifyCredentials(
        address doctor,
        bool verified
    ) external onlyRole(VERIFIER_ROLE) whenNotPaused {
        profiles[doctor].credentials.isVerified = verified;
        profiles[doctor].isVerified = verified;
        emit CredentialsVerified(
            doctor,
            profiles[doctor].credentials.licenseNumber
        );
    }

    function updateWorkingHours(
        WorkingHours memory _newHours
    ) external onlyRole(DOCTOR_ROLE) whenNotPaused {
        profiles[msg.sender].workingHours = _newHours;
        emit WorkingHoursUpdated(msg.sender);
    }

    function updateConsultationFee(
        uint256 _newFee
    ) external onlyRole(DOCTOR_ROLE) whenNotPaused {
        profiles[msg.sender].consultationFee = _newFee;
        emit ConsultationFeeUpdated(msg.sender, _newFee);
    }

    function associatePatient(
        address patient
    ) external onlyRole(DOCTOR_ROLE) whenNotPaused {
        require(
            !patientAssociations[msg.sender][patient],
            "Patient already associated"
        );
        patientAssociations[msg.sender][patient] = true;
        profiles[msg.sender].activePatients.push(patient);
        emit PatientAssociated(msg.sender, patient);
    }

    function dissociatePatient(
        address patient
    ) external onlyRole(DOCTOR_ROLE) whenNotPaused {
        require(
            patientAssociations[msg.sender][patient],
            "Patient not associated"
        );
        patientAssociations[msg.sender][patient] = false;

        Profile storage profile = profiles[msg.sender];
        for (uint i = 0; i < profile.activePatients.length; i++) {
            if (profile.activePatients[i] == patient) {
                profile.activePatients[i] = profile.activePatients[
                    profile.activePatients.length - 1
                ];
                profile.activePatients.pop();
                break;
            }
        }
        emit PatientDissociated(msg.sender, patient);
    }

    function addTreatmentPlan(
        uint256 planId
    ) external onlyRole(DOCTOR_ROLE) whenNotPaused {
        require(
            treatmentPlanContract.ownerOf(planId) == msg.sender,
            "Not plan owner"
        );
        profiles[msg.sender].createdTreatmentPlans.push(planId);
    }

    function getProfile(
        address doctor
    )
        external
        view
        returns (
            string memory ipfsHash,
            Credentials memory credentials,
            Specialization[] memory specializations,
            address[] memory activePatients,
            uint256[] memory createdTreatmentPlans,
            bool isVerified,
            bool isActive,
            uint256 lastUpdated,
            WorkingHours memory workingHours,
            uint256 consultationFee
        )
    {
        Profile storage profile = profiles[doctor];
        return (
            profile.ipfsHash,
            profile.credentials,
            profile.specializations,
            profile.activePatients,
            profile.createdTreatmentPlans,
            profile.isVerified,
            profile.isActive,
            profile.lastUpdated,
            profile.workingHours,
            profile.consultationFee
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
