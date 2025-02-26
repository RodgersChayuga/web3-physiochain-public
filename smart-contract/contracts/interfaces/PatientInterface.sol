// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IFrontendIntegration.sol";
import "../integration/SystemIntegrator.sol";

contract PatientInterface is IFrontendIntegration {
    SystemIntegrator private systemIntegrator;

    struct PatientDashboardData {
        DashboardData basic;
        TreatmentProgress treatment;
        HealthMetrics health;
        AppointmentData appointments;
        RewardsData rewards;
    }

    struct TreatmentProgress {
        uint256 adherenceRate;
        uint256 completedSessions;
        uint256 upcomingSessions;
        string[] activeExercises;
    }

    struct HealthMetrics {
        uint256[] vitalSigns;
        uint256[] wearableData;
        uint256 overallScore;
        string[] recommendations;
    }

    struct AppointmentData {
        SessionData[] upcoming;
        SessionData[] past;
        uint256[] availableSlots;
    }

    struct RewardsData {
        uint256 totalEarned;
        uint256 currentStreak;
        uint256 nextMilestone;
        Achievement[] achievements;
    }

    struct Achievement {
        string name;
        string description;
        bool achieved;
        uint256 progress;
    }

    // Web Dashboard specific functions
    function getPatientDashboardData(
        address patient
    ) external view returns (PatientDashboardData memory) {
        return _aggregatePatientData(patient);
    }

    function getHealthReport(
        address patient
    ) external view returns (HealthMetrics memory) {
        return _getDetailedHealthMetrics(patient);
    }

    // Mobile App specific functions
    function getPatientMobileData(
        address patient
    )
        external
        view
        returns (
            TreatmentProgress memory progress,
            NotificationData[] memory notifications,
            SessionData next
        )
    {
        return _getMobileOptimizedData(patient);
    }

    function submitExerciseCompletion(
        address patient,
        uint256 exerciseId,
        uint256[] memory metrics
    ) external returns (bool) {
        return _recordExerciseCompletion(patient, exerciseId, metrics);
    }
}
