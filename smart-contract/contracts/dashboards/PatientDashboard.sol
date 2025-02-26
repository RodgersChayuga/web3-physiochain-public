// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../profiles/PatientProfile.sol";
import "../monitoring/PatientMonitoring.sol";
import "../monitoring/WearableDataIntegration.sol";
import "../rewards/PatientRewards.sol";
import "../treatment/TreatmentPlanNFT.sol";

contract PatientDashboard is AccessControl, Pausable {
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Contract dependencies
    PatientProfile public patientProfile;
    PatientMonitoring public patientMonitoring;
    WearableDataIntegration public wearableData;
    PatientRewards public patientRewards;
    TreatmentPlanNFT public treatmentPlanNFT;

    // Structs for aggregating data
    struct HealthSummary {
        PatientMonitoring.HealthMetrics latestMetrics;
        WearableDataIntegration.WearableData wearableMetrics;
        uint256 activeAlertCount;
        uint256 lastCheckup;
        address[] authorizedDoctors;
    }

    struct TreatmentSummary {
        uint256[] activeTreatmentPlans;
        uint256 completedExercises;
        uint256 adherenceRate;
        uint256 totalRewards;
        uint256 currentStreak;
    }

    // Events
    event HealthDataUpdated(address indexed patient);
    event TreatmentProgressUpdated(address indexed patient);
    event RewardsEarned(address indexed patient, uint256 amount);

    constructor(
        address _patientProfileAddress,
        address _patientMonitoringAddress,
        address _wearableDataAddress,
        address _patientRewardsAddress,
        address _treatmentPlanNFTAddress
    ) {
        patientProfile = PatientProfile(_patientProfileAddress);
        patientMonitoring = PatientMonitoring(_patientMonitoringAddress);
        wearableData = WearableDataIntegration(_wearableDataAddress);
        patientRewards = PatientRewards(_patientRewardsAddress);
        treatmentPlanNFT = TreatmentPlanNFT(_treatmentPlanNFTAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Dashboard View Functions
    function getHealthSummary()
        external
        view
        onlyRole(PATIENT_ROLE)
        returns (HealthSummary memory)
    {
        PatientMonitoring.HealthMetrics memory latestMetrics = patientMonitoring
            .getLatestMetrics(msg.sender);
        (uint256 steps, uint256 calories, uint256 sleep) = wearableData
            .getWearableData(msg.sender);

        (
            ,
            address[] memory doctors,
            ,
            uint256 lastUpdated,
            ,
            ,

        ) = patientProfile.getProfile(msg.sender);

        return
            HealthSummary({
                latestMetrics: latestMetrics,
                wearableMetrics: WearableDataIntegration.WearableData({
                    steps: steps,
                    caloriesBurned: calories,
                    sleepDuration: sleep
                }),
                activeAlertCount: getActiveAlertCount(),
                lastCheckup: lastUpdated,
                authorizedDoctors: doctors
            });
    }

    function getTreatmentSummary()
        external
        view
        onlyRole(PATIENT_ROLE)
        returns (TreatmentSummary memory)
    {
        (, , , , , uint256[] memory treatmentPlans, ) = patientProfile
            .getProfile(msg.sender);

        return
            TreatmentSummary({
                activeTreatmentPlans: treatmentPlans,
                completedExercises: getCompletedExercises(),
                adherenceRate: calculateAdherenceRate(),
                totalRewards: patientRewards.getPatientRewards(msg.sender),
                currentStreak: patientRewards.getCurrentStreak(msg.sender)
            });
    }

    function getActiveAlerts()
        external
        view
        onlyRole(PATIENT_ROLE)
        returns (PatientMonitoring.Alert[] memory)
    {
        return patientMonitoring.getActiveAlerts(msg.sender);
    }

    // Helper Functions
    function getActiveAlertCount() internal view returns (uint256) {
        PatientMonitoring.Alert[] memory alerts = patientMonitoring
            .getActiveAlerts(msg.sender);
        return alerts.length;
    }

    function getCompletedExercises() internal view returns (uint256) {
        // Implementation depends on how exercises are tracked
        // Placeholder for actual implementation
        return 0;
    }

    function calculateAdherenceRate() internal view returns (uint256) {
        // Implementation depends on how adherence is tracked
        // Placeholder for actual implementation
        return 0;
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
