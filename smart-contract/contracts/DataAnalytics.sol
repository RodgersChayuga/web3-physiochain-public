// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract DataAnalytics is AccessControl {
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");

    struct WeeklyProgress {
        uint256 weekNumber;
        uint256 progressPercentage;
        uint256 previousWeekProgress;
    }

    struct PerformanceMetric {
        uint256 form;
        uint256 endurance;
        uint256 strength;
        uint256 range;
        uint256 consistency;
    }

    struct BodyPartProgress {
        string bodyPart;
        uint256 progressPercentage;
    }

    mapping(address => WeeklyProgress[]) private weeklyProgress;
    mapping(address => PerformanceMetric) private performanceMetrics;
    mapping(address => BodyPartProgress[]) private bodyPartProgress;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Log weekly progress for a specific patient
    function logWeeklyProgress(
        address patient,
        uint256 weekNumber,
        uint256 progressPercentage,
        uint256 previousWeekProgress
    ) external onlyRole(DOCTOR_ROLE) {
        weeklyProgress[patient].push(
            WeeklyProgress(weekNumber, progressPercentage, previousWeekProgress)
        );
    }

    // Retrieve weekly progress for a specific patient
    function getWeeklyProgress(
        address patient
    ) external view onlyRole(DOCTOR_ROLE) returns (WeeklyProgress[] memory) {
        return weeklyProgress[patient];
    }

    // Log performance metrics for a specific patient
    function logPerformanceMetric(
        address patient,
        uint256 form,
        uint256 endurance,
        uint256 strength,
        uint256 range,
        uint256 consistency
    ) external onlyRole(DOCTOR_ROLE) {
        performanceMetrics[patient] = PerformanceMetric(
            form,
            endurance,
            strength,
            range,
            consistency
        );
    }

    // Retrieve performance metrics for a specific patient
    function getPerformanceMetric(
        address patient
    ) external view onlyRole(DOCTOR_ROLE) returns (PerformanceMetric memory) {
        return performanceMetrics[patient];
    }

    // Log body part progress for a specific patient
    function logBodyPartProgress(
        address patient,
        string memory bodyPart,
        uint256 progressPercentage
    ) external onlyRole(DOCTOR_ROLE) {
        bodyPartProgress[patient].push(
            BodyPartProgress(bodyPart, progressPercentage)
        );
    }

    // Retrieve body part progress for a specific patient
    function getBodyPartProgress(
        address patient
    ) external view onlyRole(DOCTOR_ROLE) returns (BodyPartProgress[] memory) {
        return bodyPartProgress[patient];
    }
}

// Purpose : Aggregates and analyzes data for charts and insights.
// Key Features :
// Log weekly progress, performance metrics, and body part progress.
// Retrieve analytics data for patients and doctors.
