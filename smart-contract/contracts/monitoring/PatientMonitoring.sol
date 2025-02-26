// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./WearableDataIntegration.sol";
import "../profiles/PatientProfile.sol";
import "../profiles/DoctorProfile.sol";

contract PatientMonitoring is AccessControl, Pausable {
    bytes32 public constant MONITOR_ROLE = keccak256("MONITOR_ROLE");
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct HealthMetrics {
        uint256 heartRate;
        uint256 bloodPressureSystolic;
        uint256 bloodPressureDiastolic;
        uint256 bodyTemperature;
        uint256 oxygenSaturation;
        uint256 respiratoryRate;
        uint256 timestamp;
    }

    struct Alert {
        string alertType;
        string description;
        uint256 severity; // 1-5, with 5 being most severe
        uint256 timestamp;
        bool isActive;
        bool isAcknowledged;
    }

    struct MonitoringThresholds {
        uint256 minHeartRate;
        uint256 maxHeartRate;
        uint256 minBPSystolic;
        uint256 maxBPSystolic;
        uint256 minBPDiastolic;
        uint256 maxBPDiastolic;
        uint256 minTemperature;
        uint256 maxTemperature;
        uint256 minOxygenSaturation;
        uint256 minRespiratoryRate;
        uint256 maxRespiratoryRate;
    }

    // Contract dependencies
    WearableDataIntegration public wearableData;
    PatientProfile public patientProfile;
    DoctorProfile public doctorProfile;

    // Mappings
    mapping(address => HealthMetrics[]) public patientHealthHistory;
    mapping(address => Alert[]) public patientAlerts;
    mapping(address => MonitoringThresholds) public patientThresholds;
    mapping(address => mapping(address => bool))
        public monitoringAuthorizations;
    mapping(address => uint256) public lastUpdateTimestamp;

    // Events
    event HealthMetricsUpdated(address indexed patient, uint256 timestamp);
    event AlertCreated(
        address indexed patient,
        string alertType,
        uint256 severity
    );
    event AlertAcknowledged(address indexed patient, uint256 alertIndex);
    event ThresholdsUpdated(address indexed patient);
    event MonitoringAuthorizationGranted(
        address indexed patient,
        address indexed monitor
    );
    event MonitoringAuthorizationRevoked(
        address indexed patient,
        address indexed monitor
    );

    constructor(
        address _wearableDataAddress,
        address _patientProfileAddress,
        address _doctorProfileAddress
    ) {
        wearableData = WearableDataIntegration(_wearableDataAddress);
        patientProfile = PatientProfile(_patientProfileAddress);
        doctorProfile = DoctorProfile(_doctorProfileAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function updateHealthMetrics(
        address patient,
        HealthMetrics memory metrics
    ) external onlyRole(MONITOR_ROLE) whenNotPaused {
        require(
            monitoringAuthorizations[patient][msg.sender] ||
                hasRole(DOCTOR_ROLE, msg.sender),
            "Not authorized to update metrics"
        );

        patientHealthHistory[patient].push(metrics);
        lastUpdateTimestamp[patient] = block.timestamp;

        // Check thresholds and create alerts if necessary
        checkThresholdsAndCreateAlerts(patient, metrics);

        emit HealthMetricsUpdated(patient, metrics.timestamp);
    }

    function checkThresholdsAndCreateAlerts(
        address patient,
        HealthMetrics memory metrics
    ) internal {
        MonitoringThresholds storage thresholds = patientThresholds[patient];

        if (
            metrics.heartRate < thresholds.minHeartRate ||
            metrics.heartRate > thresholds.maxHeartRate
        ) {
            createAlert(
                patient,
                "Heart Rate Alert",
                "Abnormal heart rate detected",
                4
            );
        }

        if (metrics.bloodPressureSystolic > thresholds.maxBPSystolic) {
            createAlert(
                patient,
                "Blood Pressure Alert",
                "High blood pressure detected",
                4
            );
        }

        if (metrics.oxygenSaturation < thresholds.minOxygenSaturation) {
            createAlert(
                patient,
                "Oxygen Alert",
                "Low oxygen saturation detected",
                5
            );
        }

        // Additional threshold checks can be added here
    }

    function createAlert(
        address patient,
        string memory alertType,
        string memory description,
        uint256 severity
    ) internal {
        Alert memory newAlert = Alert({
            alertType: alertType,
            description: description,
            severity: severity,
            timestamp: block.timestamp,
            isActive: true,
            isAcknowledged: false
        });

        patientAlerts[patient].push(newAlert);
        emit AlertCreated(patient, alertType, severity);
    }

    function acknowledgeAlert(
        address patient,
        uint256 alertIndex
    ) external onlyRole(DOCTOR_ROLE) whenNotPaused {
        require(
            alertIndex < patientAlerts[patient].length,
            "Invalid alert index"
        );
        require(
            patientAlerts[patient][alertIndex].isActive,
            "Alert already inactive"
        );

        patientAlerts[patient][alertIndex].isAcknowledged = true;
        patientAlerts[patient][alertIndex].isActive = false;

        emit AlertAcknowledged(patient, alertIndex);
    }

    function setMonitoringThresholds(
        address patient,
        MonitoringThresholds memory newThresholds
    ) external onlyRole(DOCTOR_ROLE) whenNotPaused {
        patientThresholds[patient] = newThresholds;
        emit ThresholdsUpdated(patient);
    }

    function authorizeMonitor(address monitor) external whenNotPaused {
        require(
            !monitoringAuthorizations[msg.sender][monitor],
            "Monitor already authorized"
        );
        monitoringAuthorizations[msg.sender][monitor] = true;
        emit MonitoringAuthorizationGranted(msg.sender, monitor);
    }

    function revokeMonitorAuthorization(
        address monitor
    ) external whenNotPaused {
        require(
            monitoringAuthorizations[msg.sender][monitor],
            "Monitor not authorized"
        );
        monitoringAuthorizations[msg.sender][monitor] = false;
        emit MonitoringAuthorizationRevoked(msg.sender, monitor);
    }

    // View functions
    function getLatestMetrics(
        address patient
    ) external view returns (HealthMetrics memory) {
        require(
            patientHealthHistory[patient].length > 0,
            "No metrics available"
        );
        return
            patientHealthHistory[patient][
                patientHealthHistory[patient].length - 1
            ];
    }

    function getActiveAlerts(
        address patient
    ) external view returns (Alert[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < patientAlerts[patient].length; i++) {
            if (patientAlerts[patient][i].isActive) {
                activeCount++;
            }
        }

        Alert[] memory activeAlerts = new Alert[](activeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < patientAlerts[patient].length; i++) {
            if (patientAlerts[patient][i].isActive) {
                activeAlerts[currentIndex] = patientAlerts[patient][i];
                currentIndex++;
            }
        }

        return activeAlerts;
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
