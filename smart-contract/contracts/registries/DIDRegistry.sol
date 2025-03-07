// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DIDRegistry is ReentrancyGuard, AccessControl {
    // Enum to represent user types
    enum UserType {
        None,
        Patient,
        Doctor,
        Institution
    }

    // Structs
    struct UserInfo {
        string did; // Decentralized Identity
        UserType userType;
        bool isActive;
        uint256 deactivatedAt;
        uint256 reactivatedAt;
        string encryptedBiologicalDetails; // Encrypted sensitive data
        string nationalIDHash; // IPFS hash of national ID
        address createdByDoctor; // Address of the doctor who created this patient
    }

    struct DoctorRegistrationRequest {
        string did;
        string licenseNumber;
        string nationalIDHash; // IPFS hash of national ID
        bool isVerified;
    }

    // Mappings
    mapping(address => UserInfo) public users;
    mapping(string => bool) private usedDIDs;
    mapping(string => bool) private usedLicenseNumbers;
    mapping(address => mapping(address => bool)) public authorizedDoctors; // Patient -> Doctor -> Authorization
    mapping(address => DoctorRegistrationRequest) public doctorRequests;
    mapping(address => address[]) public patientDoctors; // Patient -> List of authorized doctors
    mapping(string => address) public patientKeys; // Patient key -> Doctor address (temporary)
    mapping(string => address) public keyToPatient; // Patient key -> Patient address (permanent)

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant INSTITUTION_ROLE = keccak256("INSTITUTION_ROLE");

    // Events
    event DIDRegistered(address indexed user, string did, UserType userType);
    event UserDeactivated(address indexed user);
    event UserReactivated(address indexed user);
    event DoctorAuthorized(
        address indexed patient,
        address indexed doctor,
        bool authorized
    );
    event AuthorizationLog(
        address indexed patient,
        address indexed doctor,
        bool authorized,
        uint256 timestamp
    );
    event DoctorRegistrationRequested(
        address indexed doctor,
        string licenseNumber
    );
    event PatientRegisteredByKey(
        address indexed patient,
        address indexed doctor,
        string patientKey
    );

    // Constructor
    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // Modifiers
    modifier onlyActiveUser(address user) {
        require(users[user].isActive, "User is inactive");
        _;
    }

    modifier onlyPatient() {
        require(
            isUserOfType(msg.sender, UserType.Patient),
            "Caller must be a patient"
        );
        _;
    }

    modifier onlyDoctor() {
        require(
            isUserOfType(msg.sender, UserType.Doctor),
            "Caller must be a doctor"
        );
        _;
    }

    modifier onlyInstitution() {
        require(
            hasRole(INSTITUTION_ROLE, msg.sender),
            "Caller must be an institution"
        );
        _;
    }

    modifier userNotRegistered(address user) {
        require(
            users[user].userType == UserType.None,
            "User already registered"
        );
        _;
    }

    modifier validDID(string memory did) {
        require(isValidDID(did), "Invalid DID format");
        require(!usedDIDs[did], "DID already in use");
        _;
    }

    // Register a new user (Admin-only for institutions)
    function registerUser(
        address user,
        string memory did,
        UserType userType
    ) internal onlyRole(ADMIN_ROLE) userNotRegistered(user) validDID(did) {
        require(userType != UserType.None, "Invalid user type");
        users[user] = UserInfo({
            did: did,
            userType: userType,
            isActive: true,
            deactivatedAt: 0,
            reactivatedAt: 0,
            encryptedBiologicalDetails: "",
            nationalIDHash: "",
            createdByDoctor: address(0)
        });
        usedDIDs[did] = true;
        emit DIDRegistered(user, did, userType);
    }

    // ------------------------------------------ DOCTOR REGISTRATION ------------------------------------------------

    // Oracle-related variables
    address public oracleAddress; // Address of the oracle contract
    mapping(bytes32 => address) public pendingDoctorRequests; // Request ID -> Doctor Address

    // Event for oracle response
    event DoctorVerificationRequest(
        bytes32 indexed requestId,
        address indexed doctor
    );

    // Set oracle address (Admin-only)
    function setOracleAddress(
        address _oracleAddress
    ) external onlyRole(ADMIN_ROLE) {
        oracleAddress = _oracleAddress;
    }

    // Doctor self-registration request
    function requestDoctorRegistration(
        string memory did,
        string memory licenseNumber,
        string memory nationalIDHash
    ) public userNotRegistered(msg.sender) validDID(did) {
        require(
            !usedLicenseNumbers[licenseNumber],
            "License number already in use"
        );

        // Store the request temporarily
        doctorRequests[msg.sender] = DoctorRegistrationRequest({
            did: did,
            licenseNumber: licenseNumber,
            nationalIDHash: nationalIDHash,
            isVerified: false
        });

        // Generate a unique request ID
        bytes32 requestId = keccak256(
            abi.encodePacked(msg.sender, block.timestamp)
        );

        // Store the pending request
        pendingDoctorRequests[requestId] = msg.sender;

        // Emit event for oracle to listen
        emit DoctorVerificationRequest(requestId, msg.sender);
    }

    // Callback function for oracle response
    function verifyDoctorRegistration(
        bytes32 requestId,
        bool isVerified,
        string memory name, // Additional data from government system
        string memory licenseStatus // Additional data from government system
    ) external {
        require(
            msg.sender == oracleAddress,
            "Only oracle can call this function"
        );
        address doctor = pendingDoctorRequests[requestId];
        require(doctor != address(0), "Invalid request ID");

        if (isVerified) {
            // Register the doctor
            users[doctor] = UserInfo({
                did: doctorRequests[doctor].did,
                userType: UserType.Doctor,
                isActive: true,
                deactivatedAt: 0,
                reactivatedAt: 0,
                encryptedBiologicalDetails: "",
                nationalIDHash: doctorRequests[doctor].nationalIDHash,
                createdByDoctor: address(0)
            });
            usedDIDs[doctorRequests[doctor].did] = true;
            usedLicenseNumbers[doctorRequests[doctor].licenseNumber] = true;
            emit DIDRegistered(
                doctor,
                doctorRequests[doctor].did,
                UserType.Doctor
            );

            // Clean up the pending request
            delete pendingDoctorRequests[requestId];
            delete doctorRequests[doctor];
        } else {
            // Clean up the pending request even if verification fails
            delete pendingDoctorRequests[requestId];
            delete doctorRequests[doctor];
        }
    }

    // ------------------------------------------ END DOCTOR REGISTRATION ------------------------------------------------

    // Generate a unique key for creating a Patient
    function generatePatientKey(string memory key) public onlyDoctor {
        require(bytes(key).length == 4, "Key must be 4 characters long");
        require(patientKeys[key] == address(0), "Key already exists");
        patientKeys[key] = msg.sender;
    }

    // Patient self-registration with a patient key
    function registerPatientWithKey(
        string memory did,
        string memory patientKey
    ) public userNotRegistered(msg.sender) validDID(did) {
        address doctor = patientKeys[patientKey];
        require(doctor != address(0), "Invalid patient key");
        require(
            isUserOfType(doctor, UserType.Doctor),
            "Key must be generated by a verified doctor"
        );
        require(
            keyToPatient[patientKey] == address(0),
            "Key already used for another patient"
        );

        // Register the patient
        users[msg.sender] = UserInfo({
            did: did,
            userType: UserType.Patient,
            isActive: true,
            deactivatedAt: 0,
            reactivatedAt: 0,
            encryptedBiologicalDetails: "",
            nationalIDHash: "",
            createdByDoctor: doctor
        });

        // Link the key to the patient permanently
        keyToPatient[patientKey] = msg.sender;

        // Delete the key from patientKeys to save storage
        delete patientKeys[patientKey];

        usedDIDs[did] = true;
        emit DIDRegistered(msg.sender, did, UserType.Patient);
        emit PatientRegisteredByKey(msg.sender, doctor, patientKey);
    }

    // Get patient and doctor by key
    function getPatientByKey(
        string memory patientKey
    ) public view returns (address patient, address doctor) {
        address patientAddress = keyToPatient[patientKey];
        require(
            patientAddress != address(0),
            "Key not associated with any patient"
        );
        UserInfo memory info = users[patientAddress];
        require(
            info.userType == UserType.Patient,
            "Key does not correspond to a patient"
        );
        return (patientAddress, info.createdByDoctor);
    }

    // Deactivate a user (Admin-only)
    function deactivateUser(address user) public onlyRole(ADMIN_ROLE) {
        require(users[user].isActive, "User already inactive");
        users[user].isActive = false;
        users[user].deactivatedAt = block.timestamp;
        emit UserDeactivated(user);
    }

    // Reactivate a user (Admin-only)
    function reactivateUser(address user) public onlyRole(ADMIN_ROLE) {
        require(!users[user].isActive, "User already active");
        users[user].isActive = true;
        users[user].reactivatedAt = block.timestamp;
        emit UserReactivated(user);
    }

    // Authorize a doctor to access patient records
    function authorizeDoctor(
        address doctorAddress
    ) public onlyPatient nonReentrant {
        require(
            isUserOfType(doctorAddress, UserType.Doctor),
            "Invalid doctor address"
        );
        authorizedDoctors[msg.sender][doctorAddress] = true;
        patientDoctors[msg.sender].push(doctorAddress);
        emit DoctorAuthorized(msg.sender, doctorAddress, true);
        emit AuthorizationLog(msg.sender, doctorAddress, true, block.timestamp);
    }

    // Revoke authorization for a specific doctor
    function revokeDoctorAuthorization(
        address doctorAddress
    ) public onlyPatient nonReentrant {
        require(
            isUserOfType(doctorAddress, UserType.Doctor),
            "Invalid doctor address"
        );
        authorizedDoctors[msg.sender][doctorAddress] = false;
        emit DoctorAuthorized(msg.sender, doctorAddress, false);
        emit AuthorizationLog(
            msg.sender,
            doctorAddress,
            false,
            block.timestamp
        );
    }

    // Check if a user belongs to a specific type
    function isUserOfType(
        address user,
        UserType userType
    ) public view returns (bool) {
        return users[user].userType == userType && users[user].isActive;
    }

    // Validate DID formats
    function isValidDID(string memory did) internal pure returns (bool) {
        bytes memory didBytes = bytes(did);
        return
            didBytes.length > 0 &&
            keccak256(abi.encodePacked(didBytes[0])) == keccak256("d") &&
            didBytes.length >= 15; // Minimum length for "did:example:1234"
    }

    // Get user information
    function getUserInfo(
        address user
    )
        public
        view
        returns (
            string memory did,
            UserType userType,
            bool isActive,
            address createdByDoctor
        )
    {
        UserInfo memory info = users[user];
        return (info.did, info.userType, info.isActive, info.createdByDoctor);
    }
}
