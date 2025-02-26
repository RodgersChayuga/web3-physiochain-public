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
        string passportPhotoHash; // IPFS hash of passport photo
    }

    struct DoctorRegistrationRequest {
        string did;
        string licenseNumber;
        string nationalIDHash; // IPFS hash of national ID
        string passportPhotoHash; // IPFS hash of passport photo
        bool isVerified;
    }

    // Mappings
    mapping(address => UserInfo) public users;
    mapping(string => bool) private usedDIDs;
    mapping(string => bool) private usedLicenseNumbers;
    mapping(address => mapping(address => bool)) public authorizedDoctors; // Patient -> Doctor -> Authorization
    mapping(address => DoctorRegistrationRequest) public doctorRequests;
    mapping(address => address[]) public patientDoctors; // Patient -> List of authorized doctors

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
    ) public onlyRole(ADMIN_ROLE) userNotRegistered(user) validDID(did) {
        require(userType != UserType.None, "Invalid user type");
        users[user] = UserInfo({
            did: did,
            userType: userType,
            isActive: true,
            deactivatedAt: 0,
            reactivatedAt: 0,
            encryptedBiologicalDetails: "",
            nationalIDHash: "",
            passportPhotoHash: ""
        });
        usedDIDs[did] = true;
        emit DIDRegistered(user, did, userType);
    }

    // Doctor self-registration request
    function requestDoctorRegistration(
        string memory did,
        string memory licenseNumber,
        string memory nationalIDHash,
        string memory passportPhotoHash
    ) public userNotRegistered(msg.sender) validDID(did) {
        require(
            !usedLicenseNumbers[licenseNumber],
            "License number already in use"
        );
        doctorRequests[msg.sender] = DoctorRegistrationRequest({
            did: did,
            licenseNumber: licenseNumber,
            nationalIDHash: nationalIDHash,
            passportPhotoHash: passportPhotoHash,
            isVerified: false
        });
        usedLicenseNumbers[licenseNumber] = true;
        emit DoctorRegistrationRequested(msg.sender, licenseNumber);
    }

    // Verify doctor registration request (Admin-only)
    function verifyDoctor(
        address doctor,
        bool isVerified
    ) public onlyRole(ADMIN_ROLE) {
        require(
            bytes(doctorRequests[doctor].licenseNumber).length > 0,
            "No pending request"
        );
        if (isVerified) {
            registerUser(doctor, doctorRequests[doctor].did, UserType.Doctor);
        }
        doctorRequests[doctor].isVerified = isVerified;
    }

    // Patient registration by verified doctors
    function registerPatient(
        address patient,
        string memory did,
        string memory biologicalDetails,
        string memory nationalIDHash,
        string memory passportPhotoHash
    ) public onlyDoctor userNotRegistered(patient) validDID(did) {
        users[patient] = UserInfo({
            did: did,
            userType: UserType.Patient,
            isActive: true,
            deactivatedAt: 0,
            reactivatedAt: 0,
            encryptedBiologicalDetails: biologicalDetails,
            nationalIDHash: nationalIDHash,
            passportPhotoHash: passportPhotoHash
        });
        usedDIDs[did] = true;
        emit DIDRegistered(patient, did, UserType.Patient);
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
        returns (string memory did, UserType userType, bool isActive)
    {
        UserInfo memory info = users[user];
        return (info.did, info.userType, info.isActive);
    }
}
