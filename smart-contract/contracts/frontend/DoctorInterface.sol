// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IFrontendIntegration.sol";
import "../integration/SystemIntegrator.sol";

contract DoctorInterface is IFrontendIntegration {
    SystemIntegrator private systemIntegrator;

    struct DoctorDashboardData {
        DashboardData basic;
        PatientSummary[] activePatients;
        ScheduleData schedule;
        PerformanceMetrics performance;
        RewardsSummary rewards;
    }

    struct PatientSummary {
        address patientAddress;
        string name;
        string condition;
        uint256 lastVisit;
        uint256 nextAppointment;
        uint256 adherenceRate;
    }

    struct ScheduleData {
        SessionData[] upcomingSessions;
        SessionData[] completedSessions;
        uint256[] availableSlots;
    }

    struct PerformanceMetrics {
        uint256 patientSatisfaction;
        uint256 treatmentSuccess;
        uint256 attendanceRate;
        uint256 responseTime;
    }

    struct RewardsSummary {
        uint256 totalEarned;
        uint256 pendingRewards;
        uint256 lastPayout;
        uint256 performanceBonus;
    }

    // Web Dashboard specific functions
    function getDoctorDashboardData(
        address doctor
    ) external view returns (DoctorDashboardData memory) {
        return _aggregateDoctorData(doctor);
    }

    function getPatientList(
        address doctor
    ) external view returns (PatientSummary[] memory) {
        return _getActivePatients(doctor);
    }

    function getSchedule(
        address doctor
    ) external view returns (ScheduleData memory) {
        return _getDoctorSchedule(doctor);
    }

    // Mobile App specific functions
    function getDoctorMobileData(
        address doctor
    )
        external
        view
        returns (
            PatientSummary[] memory urgentCases,
            NotificationData[] memory notifications,
            SessionData[] memory todaySessions
        )
    {
        return _getMobileOptimizedData(doctor);
    }

    function recordSessionMobile(
        uint256 sessionId,
        address patient,
        string memory notes
    ) external returns (bool) {
        return _recordSessionData(sessionId, patient, notes);
    }
}
