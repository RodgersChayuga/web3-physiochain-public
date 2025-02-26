// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../profiles/DoctorProfile.sol";
import "../profiles/PatientProfile.sol";
import "../monitoring/PatientMonitoring.sol";
import "../treatment/TreatmentPlanNFT.sol";
import "../rewards/DoctorRewards.sol";

contract DoctorDashboard is AccessControl, Pausable {
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Contract dependencies
    DoctorProfile public doctorProfile;
    PatientProfile public patientProfile;
    PatientMonitoring public patientMonitoring;
    TreatmentPlanNFT public treatmentPlanNFT;
    DoctorRewards public doctorRewards;

    // Structs for aggregating data
    struct PatientSummary {
        address patientAddress;
        string ipfsHash;
        uint256 lastCheckup;
        uint256 activeAlertCount;
        uint256[] activeTreatmentPlans;
        bool isActive;
    }

    struct DoctorMetrics {
        uint256 totalPatients;
        uint256 activePatients;
        uint256 totalTreatmentPlans;
        uint256 totalRewards;
        uint256 averageRating;
        uint256 completedSessions;
    }

    // Events
    event PatientAdded(address indexed doctor, address indexed patient);
    event CheckupRecorded(address indexed doctor, address indexed patient);
    event MetricsUpdated(address indexed doctor);

    constructor(
        address _doctorProfileAddress,
        address _patientProfileAddress,
        address _patientMonitoringAddress,
        address _treatmentPlanNFTAddress,
        address _doctorRewardsAddress
    ) {
        doctorProfile = DoctorProfile(_doctorProfileAddress);
        patientProfile = PatientProfile(_patientProfileAddress);
        patientMonitoring = PatientMonitoring(_patientMonitoringAddress);
        treatmentPlanNFT = TreatmentPlanNFT(_treatmentPlanNFTAddress);
        doctorRewards = DoctorRewards(_doctorRewardsAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Dashboard View Functions
    function getPatientOverview(
        address patient
    ) external view onlyRole(DOCTOR_ROLE) returns (PatientSummary memory) {
        require(
            doctorProfile.patientAssociations(msg.sender, patient),
            "Not authorized for this patient"
        );

        (
            string memory ipfsHash,
            ,
            bool isActive,
            uint256 lastUpdated,
            ,
            uint256[] memory treatmentPlans,

        ) = patientProfile.getProfile(patient);

        uint256 alertCount = getActiveAlertCount(patient);

        return
            PatientSummary({
                patientAddress: patient,
                ipfsHash: ipfsHash,
                lastCheckup: lastUpdated,
                activeAlertCount: alertCount,
                activeTreatmentPlans: treatmentPlans,
                isActive: isActive
            });
    }

    function getDoctorMetrics()
        external
        view
        onlyRole(DOCTOR_ROLE)
        returns (DoctorMetrics memory)
    {
        (
            address[] memory activePatients,
            uint256[] memory treatmentPlans,

        ) = doctorProfile.getProfile(msg.sender);

        uint256 totalRewards = doctorRewards.doctorRewards(msg.sender);

        return
            DoctorMetrics({
                totalPatients: activePatients.length,
                activePatients: getActivePatientCount(activePatients),
                totalTreatmentPlans: treatmentPlans.length,
                totalRewards: totalRewards,
                averageRating: calculateAverageRating(treatmentPlans),
                completedSessions: getCompletedSessions()
            });
    }

    function getActiveAlerts()
        external
        view
        onlyRole(DOCTOR_ROLE)
        returns (
            address[] memory patients,
            PatientMonitoring.Alert[][] memory alerts
        )
    {
        (, , , address[] memory activePatients, , , , , , ) = doctorProfile
            .getProfile(msg.sender);

        patients = new address[](activePatients.length);
        alerts = new PatientMonitoring.Alert[][](activePatients.length);

        for (uint256 i = 0; i < activePatients.length; i++) {
            patients[i] = activePatients[i];
            alerts[i] = patientMonitoring.getActiveAlerts(activePatients[i]);
        }

        return (patients, alerts);
    }

    // Helper Functions
    function getActiveAlertCount(
        address patient
    ) internal view returns (uint256) {
        PatientMonitoring.Alert[] memory alerts = patientMonitoring
            .getActiveAlerts(patient);
        return alerts.length;
    }

    function getActivePatientCount(
        address[] memory patients
    ) internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < patients.length; i++) {
            if (patientProfile.profiles(patients[i]).isActive) {
                count++;
            }
        }
        return count;
    }

    function calculateAverageRating(
        uint256[] memory treatmentPlans
    ) internal view returns (uint256) {
        if (treatmentPlans.length == 0) return 0;

        uint256 totalRating = 0;
        uint256 ratedPlans = 0;

        for (uint256 i = 0; i < treatmentPlans.length; i++) {
            uint256 rating = treatmentPlanNFT.getPlanRating(treatmentPlans[i]);
            if (rating > 0) {
                totalRating += rating;
                ratedPlans++;
            }
        }

        return ratedPlans > 0 ? totalRating / ratedPlans : 0;
    }

    function getCompletedSessions() internal view returns (uint256) {
        // Implementation depends on how sessions are tracked
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
