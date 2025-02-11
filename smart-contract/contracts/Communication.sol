// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Communication is AccessControl {
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");
    bytes32 public constant THERAPIST_ROLE = keccak256("THERAPIST_ROLE");

    struct ActivityLog {
        uint256 timestamp;
        string description;
    }

    struct RiskAlert {
        uint256 timestamp;
        string alertMessage;
        string action;
    }

    mapping(address => ActivityLog[]) private activityLogs;
    mapping(address => RiskAlert[]) private riskAlerts;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Add an activity log for a specific patient
    function addActivityLog(
        address patient,
        string memory description
    ) external onlyRole(THERAPIST_ROLE) {
        activityLogs[patient].push(ActivityLog(block.timestamp, description));
    }

    // Retrieve activity logs for a specific patient
    function getActivityLogs(
        address patient
    ) external view onlyRole(PATIENT_ROLE) returns (ActivityLog[] memory) {
        return activityLogs[patient];
    }

    // Log a risk alert for a specific patient
    function logRiskAlert(
        address patient,
        string memory alertMessage,
        string memory action
    ) external onlyRole(DOCTOR_ROLE) {
        riskAlerts[patient].push(
            RiskAlert(block.timestamp, alertMessage, action)
        );
    }

    // Retrieve risk alerts for a specific patient
    function getRiskAlerts(
        address patient
    ) external view onlyRole(DOCTOR_ROLE) returns (RiskAlert[] memory) {
        return riskAlerts[patient];
    }
}

// Purpose : Handles messaging and feedback between patients and therapists.
// Key Features :
// Log activity logs and risk alerts.
// Retrieve logs and alerts for patients and doctors.
