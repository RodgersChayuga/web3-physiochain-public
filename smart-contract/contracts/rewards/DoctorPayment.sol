// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./PhysioToken.sol";

contract DoctorPayment is AccessControl {
    bytes32 public constant PAYMENT_MANAGER_ROLE =
        keccak256("PAYMENT_MANAGER_ROLE");

    PhysioToken public physioToken;

    // Platform owner address
    address public platformOwner;

    // Service fee percentage (stored as basis points: 1 bp = 0.01%)
    uint256 public serviceFeePercentage; // e.g., 5 for 0.05%

    // Struct to represent an agreement
    struct Agreement {
        address doctor;
        address patient;
        uint256 feePerSession; // Fee per session (negotiated once)
        bool isActive; // Whether the agreement is active
    }

    // Mapping to track agreements by unique IDs
    mapping(uint256 => Agreement) public agreements;

    // Counter for generating unique agreement IDs
    uint256 public agreementCounter;

    constructor(
        address _physioTokenAddress,
        address _platformOwner,
        uint256 _serviceFeePercentage
    ) {
        physioToken = PhysioToken(_physioTokenAddress);
        platformOwner = _platformOwner;
        serviceFeePercentage = _serviceFeePercentage; // e.g., 5 for 0.05%
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Function for a doctor to propose a fee for sessions
     * @param patient The address of the patient
     * @param feePerSession The proposed fee per session
     */
    function proposeAgreement(address patient, uint256 feePerSession) external {
        require(patient != address(0), "Invalid patient address");
        uint256 agreementId = ++agreementCounter;

        agreements[agreementId] = Agreement({
            doctor: msg.sender,
            patient: patient,
            feePerSession: feePerSession,
            isActive: false
        });

        emit AgreementProposed(agreementId, msg.sender, patient, feePerSession);
    }

    /**
     * @dev Function for a patient to approve an agreement
     * @param agreementId The ID of the agreement
     */
    function approveAgreement(uint256 agreementId) external {
        Agreement storage agreement = agreements[agreementId];
        require(agreement.doctor != address(0), "Invalid agreement ID");
        require(
            agreement.patient == msg.sender,
            "Only the patient can approve the agreement"
        );
        require(!agreement.isActive, "Agreement already active");

        agreement.isActive = true;

        emit AgreementApproved(agreementId, agreement.doctor, msg.sender);
    }

    /**
     * @dev Function for a patient to confirm session completion and pay the doctor
     * @param agreementId The ID of the agreement
     */
    function confirmSessionCompletion(uint256 agreementId) external {
        Agreement storage agreement = agreements[agreementId];
        require(agreement.isActive, "Agreement not active");
        require(
            agreement.patient == msg.sender,
            "Only the patient can confirm session completion"
        );

        // Calculate service fee
        uint256 serviceFee = (agreement.feePerSession * serviceFeePercentage) /
            10000; // Basis points calculation
        uint256 doctorPayment = agreement.feePerSession - serviceFee;

        // Ensure the patient has enough tokens
        require(
            physioToken.balanceOf(msg.sender) >= agreement.feePerSession,
            "Insufficient balance"
        );

        // Transfer service fee to platform owner
        physioToken.transferFrom(msg.sender, platformOwner, serviceFee);

        // Transfer the remaining amount to the doctor
        physioToken.transferFrom(msg.sender, agreement.doctor, doctorPayment);

        emit SessionCompleted(
            agreementId,
            agreement.doctor,
            msg.sender,
            doctorPayment,
            serviceFee
        );
    }

    /**
     * @dev Function for renegotiating the fee per session
     * @param agreementId The ID of the agreement
     * @param newFeePerSession The new proposed fee per session
     */
    function renegotiateFee(
        uint256 agreementId,
        uint256 newFeePerSession
    ) external {
        Agreement storage agreement = agreements[agreementId];
        require(agreement.doctor != address(0), "Invalid agreement ID");
        require(
            agreement.doctor == msg.sender || agreement.patient == msg.sender,
            "Only the doctor or patient can renegotiate"
        );

        // Update the fee per session
        agreement.feePerSession = newFeePerSession;

        emit FeeRenegotiated(agreementId, newFeePerSession);
    }

    /**
     * @dev Function to update the service fee percentage
     * @param newServiceFeePercentage The new service fee percentage (in basis points)
     */
    function updateServiceFeePercentage(
        uint256 newServiceFeePercentage
    ) external onlyRole(PAYMENT_MANAGER_ROLE) {
        require(
            newServiceFeePercentage <= 10000,
            "Service fee percentage cannot exceed 100%"
        );
        serviceFeePercentage = newServiceFeePercentage;

        emit ServiceFeePercentageUpdated(newServiceFeePercentage);
    }

    /**
     * @dev Event emitted when an agreement is proposed
     */
    event AgreementProposed(
        uint256 indexed agreementId,
        address indexed doctor,
        address indexed patient,
        uint256 feePerSession
    );

    /**
     * @dev Event emitted when an agreement is approved
     */
    event AgreementApproved(
        uint256 indexed agreementId,
        address indexed doctor,
        address indexed patient
    );

    /**
     * @dev Event emitted when a session is completed and payment is made
     */
    event SessionCompleted(
        uint256 indexed agreementId,
        address indexed doctor,
        address indexed patient,
        uint256 doctorPayment,
        uint256 serviceFee
    );

    /**
     * @dev Event emitted when the fee per session is renegotiated
     */
    event FeeRenegotiated(
        uint256 indexed agreementId,
        uint256 newFeePerSession
    );

    /**
     * @dev Event emitted when the service fee percentage is updated
     */
    event ServiceFeePercentageUpdated(uint256 newServiceFeePercentage);
}
