// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../profiles/DoctorProfile.sol";
import "../profiles/PatientProfile.sol";
import "../monitoring/PatientMonitoring.sol";
import "../treatment/TreatmentPlanNFT.sol";
import "../rewards/DoctorRewards.sol";
import "../rewards/PatientRewards.sol";
import "../utility/ReportGenerator.sol";

contract SystemIntegrator is AccessControl, Pausable {
    bytes32 public constant INTEGRATOR_ROLE = keccak256("INTEGRATOR_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    // Contract references
    DoctorProfile public doctorProfile;
    PatientProfile public patientProfile;
    PatientMonitoring public patientMonitoring;
    TreatmentPlanNFT public treatmentPlanNFT;
    DoctorRewards public doctorRewards;
    PatientRewards public patientRewards;
    ReportGenerator public reportGenerator;

    // Integration events
    event SystemStateUpdated(SystemState newState);
    event EmergencyTriggered(address indexed triggeredBy, string reason);
    event IntegrationError(string component, string message);
    event CrossContractActionExecuted(string action, bool success);

    // System state tracking
    struct SystemState {
        uint256 lastUpdateTimestamp;
        uint256 activeUsers;
        uint256 pendingActions;
        bool emergencyMode;
        mapping(string => bool) componentStatus;
    }

    SystemState public systemState;

    // Action queue for cross-contract operations
    struct CrossContractAction {
        string actionType;
        address[] involvedAddresses;
        bytes[] functionCalls;
        bool executed;
        uint256 timestamp;
    }

    CrossContractAction[] public actionQueue;
    mapping(bytes32 => bool) public processedActions;

    constructor(
        address _doctorProfile,
        address _patientProfile,
        address _patientMonitoring,
        address _treatmentPlanNFT,
        address _doctorRewards,
        address _patientRewards,
        address _reportGenerator
    ) {
        doctorProfile = DoctorProfile(_doctorProfile);
        patientProfile = PatientProfile(_patientProfile);
        patientMonitoring = PatientMonitoring(_patientMonitoring);
        treatmentPlanNFT = TreatmentPlanNFT(_treatmentPlanNFT);
        doctorRewards = DoctorRewards(_doctorRewards);
        patientRewards = PatientRewards(_patientRewards);
        reportGenerator = ReportGenerator(_reportGenerator);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(INTEGRATOR_ROLE, msg.sender);
    }

    // Integrated Actions

    function initiateTreatmentPlan(
        address doctor,
        address patient,
        string memory ipfsHash
    ) external onlyRole(INTEGRATOR_ROLE) whenNotPaused {
        require(doctorProfile.isVerifiedDoctor(doctor), "Doctor not verified");
        require(patientProfile.isActivePatient(patient), "Patient not active");

        // Create treatment plan NFT
        uint256 tokenId = treatmentPlanNFT.createTreatmentPlan(
            doctor,
            ipfsHash
        );

        // Update profiles
        doctorProfile.addTreatmentPlan(doctor, tokenId);
        patientProfile.assignTreatmentPlan(patient, tokenId);

        // Initialize monitoring
        patientMonitoring.initializeMonitoring(patient, tokenId);

        emit CrossContractActionExecuted("InitiateTreatmentPlan", true);
    }

    function completeTreatmentSession(
        address doctor,
        address patient,
        uint256 tokenId
    ) external onlyRole(INTEGRATOR_ROLE) whenNotPaused {
        // Verify session completion
        require(
            treatmentPlanNFT.verifySession(tokenId, doctor, patient),
            "Session verification failed"
        );

        // Update treatment progress
        treatmentPlanNFT.recordSession(tokenId);

        // Process rewards
        _processSessionRewards(doctor, patient);

        // Update monitoring data
        patientMonitoring.updateSessionMetrics(patient, tokenId);

        emit CrossContractActionExecuted("CompleteTreatmentSession", true);
    }

    function handleEmergencyAlert(
        address patient,
        string memory alertType
    ) external onlyRole(EMERGENCY_ROLE) {
        systemState.emergencyMode = true;

        // Notify monitoring system
        patientMonitoring.triggerEmergencyProtocol(patient, alertType);

        // Alert associated doctor
        address doctor = patientProfile.getPrimaryDoctor(patient);
        if (doctor != address(0)) {
            doctorProfile.notifyEmergency(doctor, patient, alertType);
        }

        emit EmergencyTriggered(patient, alertType);
    }

    // Cross-contract data aggregation
    function aggregatePatientData(
        address patient
    )
        external
        view
        returns (
            PatientProfile.Profile memory profile,
            PatientMonitoring.HealthMetrics memory health,
            uint256[] memory activeTreatments,
            uint256 rewardBalance
        )
    {
        profile = patientProfile.getProfile(patient);
        health = patientMonitoring.getLatestMetrics(patient);
        activeTreatments = treatmentPlanNFT.getActiveTreatmentPlans(patient);
        rewardBalance = patientRewards.getPatientRewards(patient);
    }

    function aggregateDoctorData(
        address doctor
    )
        external
        view
        returns (
            DoctorProfile.Profile memory profile,
            uint256[] memory patients,
            uint256 rewardBalance,
            uint256 performanceScore
        )
    {
        profile = doctorProfile.getProfile(doctor);
        patients = doctorProfile.getActivePatients(doctor);
        rewardBalance = doctorRewards.doctorRewards(doctor);
        performanceScore = doctorRewards.calculatePerformanceScore(doctor);
    }

    // System health monitoring
    function checkSystemHealth() external view returns (bool[] memory status) {
        status = new bool[](7);
        status[0] = !doctorProfile.paused();
        status[1] = !patientProfile.paused();
        status[2] = !patientMonitoring.paused();
        status[3] = !treatmentPlanNFT.paused();
        status[4] = !doctorRewards.paused();
        status[5] = !patientRewards.paused();
        status[6] = !reportGenerator.paused();
    }

    // Internal helper functions
    function _processSessionRewards(address doctor, address patient) internal {
        // Calculate and distribute rewards
        uint256 doctorReward = doctorRewards.calculateSessionReward(doctor);
        uint256 patientReward = patientRewards.calculateSessionReward(patient);

        doctorRewards.distributeReward(doctor, doctorReward);
        patientRewards.distributeReward(patient, patientReward);
    }

    // Queue management for cross-contract actions
    function queueCrossContractAction(
        string memory actionType,
        address[] memory addresses,
        bytes[] memory functionCalls
    ) external onlyRole(INTEGRATOR_ROLE) {
        actionQueue.push(
            CrossContractAction({
                actionType: actionType,
                involvedAddresses: addresses,
                functionCalls: functionCalls,
                executed: false,
                timestamp: block.timestamp
            })
        );
    }

    function processPendingActions() external onlyRole(INTEGRATOR_ROLE) {
        for (uint256 i = 0; i < actionQueue.length; i++) {
            if (!actionQueue[i].executed) {
                _executeCrossContractAction(i);
            }
        }
    }

    function _executeCrossContractAction(uint256 index) internal {
        CrossContractAction storage action = actionQueue[index];
        bytes32 actionHash = keccak256(
            abi.encodePacked(
                action.actionType,
                action.timestamp,
                action.involvedAddresses
            )
        );

        if (!processedActions[actionHash]) {
            try this.executeAction(action.functionCalls) {
                action.executed = true;
                processedActions[actionHash] = true;
                emit CrossContractActionExecuted(action.actionType, true);
            } catch Error(string memory reason) {
                emit IntegrationError(action.actionType, reason);
            }
        }
    }

    function executeAction(bytes[] memory functionCalls) external {
        require(msg.sender == address(this), "Only internal calls");
        for (uint256 i = 0; i < functionCalls.length; i++) {
            (bool success, ) = address(this).call(functionCalls[i]);
            require(success, "Action execution failed");
        }
    }
}
