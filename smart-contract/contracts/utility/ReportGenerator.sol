// // SPDX-License-Identifier: UNLICENSED

// pragma solidity ^0.8.28;

// // Uncomment this line to use console.log
// // import "hardhat/console.sol";

// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/utils/Pausable.sol";
// import "../monitoring/PatientMonitoring.sol";
// import "../profiles/DoctorProfile.sol";
// import "../profiles/PatientProfile.sol";
// import "../treatment/AnalyticsContract.sol";
// import "../rewards/DoctorRewards.sol";
// import "../rewards/PatientRewards.sol";

// // Add before the ReportGenerator contract
// interface IWearableData {
//     function getAggregatedData(
//         address patient,
//         uint256 startTime
//     ) external view returns (uint256, uint256, uint256);
// }

// contract ReportGenerator is AccessControl, Pausable {
//     bytes32 public constant REPORT_GENERATOR_ROLE =
//         keccak256("REPORT_GENERATOR_ROLE");
//     bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

//     // Contract dependencies
//     PatientMonitoring public patientMonitoring;
//     DoctorProfile public doctorProfile;
//     PatientProfile public patientProfile;
//     AnalyticsContract public analytics;
//     DoctorRewards public doctorRewards;
//     PatientRewards public patientRewards;

//     // Add wearableData contract variable
//     IWearableData public wearableData;

//     // Enhanced Report Types
//     enum ReportType {
//         PATIENT_PROGRESS,
//         DOCTOR_PERFORMANCE,
//         TREATMENT_EFFECTIVENESS,
//         PLATFORM_METRICS,
//         REWARD_DISTRIBUTION,
//         COMPLIANCE_AUDIT,
//         HEALTH_TRENDS, // New
//         FINANCIAL_METRICS, // New
//         TREATMENT_ANALYTICS, // New
//         ENGAGEMENT_METRICS, // New
//         SAFETY_COMPLIANCE, // New
//         OPERATIONAL_EFFICIENCY // New
//     }

//     // Report structures
//     struct Report {
//         uint256 reportId;
//         ReportType reportType;
//         string ipfsHash;
//         uint256 timestamp;
//         address requestedBy;
//         bool isConfidential;
//     }

//     struct PatientProgressReport {
//         address patient;
//         uint256 adherenceRate;
//         uint256 completedSessions;
//         uint256 totalRewards;
//         uint256[] healthMetricsHistory;
//         uint256 treatmentEffectiveness;
//     }

//     struct DoctorPerformanceReport {
//         address doctor;
//         uint256 patientCount;
//         uint256 averagePatientProgress;
//         uint256 treatmentSuccessRate;
//         uint256 totalRewardsEarned;
//         uint256 averageRating;
//     }

//     struct PlatformMetricsReport {
//         uint256 totalActivePatients;
//         uint256 totalActiveDoctors;
//         uint256 totalTreatmentPlans;
//         uint256 averageAdherenceRate;
//         uint256 totalRewardsDistributed;
//         uint256 systemUtilization;
//     }

//     // New specialized report structures
//     struct HealthTrendsReport {
//         uint256 timeframe;
//         uint256[] averageVitals;
//         uint256[] wearableMetrics;
//         uint256 overallHealthScore;
//         uint256 improvementRate;
//         EmergencyIncidents emergencyStats;
//     }

//     struct EmergencyIncidents {
//         uint256 totalIncidents;
//         uint256 criticalAlerts;
//         uint256 averageResponseTime;
//         uint256 resolutionRate;
//     }

//     struct FinancialMetricsReport {
//         uint256 totalRevenue;
//         uint256 rewardsDistributed;
//         TokenomicsMetrics tokenomics;
//         PaymentStats payments;
//         uint256 averageSessionCost;
//         uint256 platformFees;
//     }

//     struct TokenomicsMetrics {
//         uint256 tokenCirculation;
//         uint256 burnRate;
//         uint256 rewardPool;
//         uint256 stakingMetrics;
//     }

//     struct PaymentStats {
//         uint256 totalTransactions;
//         uint256 averageTransactionValue;
//         uint256 successRate;
//         uint256 disputeRate;
//     }

//     struct TreatmentAnalyticsReport {
//         uint256 totalActiveTreatments;
//         TreatmentEffectiveness[] effectiveness;
//         PopularTreatments popularTreatments;
//         OutcomeMetrics outcomes;
//         uint256 averageDuration;
//         uint256 successRate;
//     }

//     struct TreatmentEffectiveness {
//         uint256 treatmentId;
//         uint256 successRate;
//         uint256 adherenceRate;
//         uint256 patientSatisfaction;
//     }

//     struct PopularTreatments {
//         uint256[] topTreatmentIds;
//         uint256[] usageCounts;
//         uint256[] satisfactionScores;
//     }

//     struct OutcomeMetrics {
//         uint256 shortTermSuccess;
//         uint256 longTermSuccess;
//         uint256 relapsePrevention;
//         uint256 patientProgress;
//     }

//     struct EngagementReport {
//         UserEngagement patientEngagement;
//         UserEngagement doctorEngagement;
//         CommunicationStats communication;
//         PlatformUsage usage;
//     }

//     struct UserEngagement {
//         uint256 activeUsers;
//         uint256 averageSessionDuration;
//         uint256 interactionFrequency;
//         uint256 retentionRate;
//     }

//     struct CommunicationStats {
//         uint256 totalInteractions;
//         uint256 responseRate;
//         uint256 averageResponseTime;
//         uint256 satisfactionScore;
//     }

//     struct PlatformUsage {
//         uint256 peakHours;
//         uint256 featureUtilization;
//         uint256 userSatisfaction;
//         uint256 technicalIssues;
//     }

//     struct SafetyComplianceReport {
//         DataPrivacyMetrics privacyMetrics;
//         SecurityIncidents security;
//         ComplianceStatus compliance;
//         RiskAssessment risk;
//     }

//     struct DataPrivacyMetrics {
//         uint256 dataBreaches;
//         uint256 accessAttempts;
//         uint256 authorizedAccess;
//         uint256 dataEncryption;
//     }

//     struct SecurityIncidents {
//         uint256 totalIncidents;
//         uint256 resolvedIncidents;
//         uint256 averageResolutionTime;
//         uint256 criticalEvents;
//     }

//     struct ComplianceStatus {
//         bool hipaaCompliant;
//         bool gdprCompliant;
//         uint256 lastAuditDate;
//         uint256 complianceScore;
//     }

//     struct RiskAssessment {
//         uint256 riskLevel;
//         uint256 mitigationRate;
//         uint256 vulnerabilities;
//         uint256 securityScore;
//     }

//     // Mappings
//     mapping(uint256 => Report) public reports;
//     mapping(address => mapping(ReportType => uint256[])) public userReports;
//     uint256 private reportCounter;

//     // New mapping for specialized reports
//     mapping(ReportType => mapping(uint256 => bytes))
//         public specializedReportData;

//     // Events
//     event ReportGenerated(
//         uint256 indexed reportId,
//         ReportType reportType,
//         address indexed requestedBy
//     );
//     event ReportUpdated(uint256 indexed reportId, string newIpfsHash);
//     event ConfidentialReportAccessed(
//         uint256 indexed reportId,
//         address indexed accessedBy
//     );

//     // New events for specialized reports
//     event HealthTrendsReportGenerated(
//         uint256 indexed reportId,
//         uint256 timeframe
//     );
//     event FinancialReportGenerated(
//         uint256 indexed reportId,
//         uint256 totalRevenue
//     );
//     event TreatmentAnalyticsGenerated(
//         uint256 indexed reportId,
//         uint256 totalTreatments
//     );
//     event EngagementReportGenerated(
//         uint256 indexed reportId,
//         uint256 activeUsers
//     );
//     event SafetyComplianceReportGenerated(
//         uint256 indexed reportId,
//         uint256 complianceScore
//     );

//     constructor(
//         address _patientMonitoringAddress,
//         address _doctorProfileAddress,
//         address _patientProfileAddress,
//         address _analyticsAddress,
//         address _doctorRewardsAddress,
//         address _patientRewardsAddress,
//         address _wearableDataAddress
//     ) {
//         patientMonitoring = PatientMonitoring(_patientMonitoringAddress);
//         doctorProfile = DoctorProfile(_doctorProfileAddress);
//         patientProfile = PatientProfile(_patientProfileAddress);
//         analytics = AnalyticsContract(_analyticsAddress);
//         doctorRewards = DoctorRewards(_doctorRewardsAddress);
//         patientRewards = PatientRewards(_patientRewardsAddress);
//         wearableData = IWearableData(_wearableDataAddress);

//         _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
//         _grantRole(REPORT_GENERATOR_ROLE, msg.sender);
//     }

//     function generatePatientProgressReport(
//         address patient
//     ) external onlyRole(REPORT_GENERATOR_ROLE) whenNotPaused returns (uint256) {
//         require(patientProfile.isActivePatient(patient), "Patient not active");

//         PatientProgressReport memory progressReport = PatientProgressReport({
//             patient: patient,
//             adherenceRate: calculatePatientAdherence(patient),
//             completedSessions: getCompletedSessions(patient),
//             totalRewards: patientRewards.getPatientRewards(patient),
//             healthMetricsHistory: getHealthMetricsHistory(patient),
//             treatmentEffectiveness: calculateTreatmentEffectiveness(patient)
//         });

//         return _createReport(ReportType.PATIENT_PROGRESS, progressReport);
//     }

//     function generateDoctorPerformanceReport(
//         address doctor
//     ) external onlyRole(REPORT_GENERATOR_ROLE) whenNotPaused returns (uint256) {
//         require(doctorProfile.profiles(doctor).isActive, "Doctor not active");

//         DoctorPerformanceReport
//             memory performanceReport = DoctorPerformanceReport({
//                 doctor: doctor,
//                 patientCount: getActivePatientCount(doctor),
//                 averagePatientProgress: calculateAveragePatientProgress(doctor),
//                 treatmentSuccessRate: calculateTreatmentSuccessRate(doctor),
//                 totalRewardsEarned: doctorRewards.doctorRewards(doctor),
//                 averageRating: calculateAverageRating(doctor)
//             });

//         return _createReport(ReportType.DOCTOR_PERFORMANCE, performanceReport);
//     }

//     function generatePlatformMetricsReport()
//         external
//         onlyRole(REPORT_GENERATOR_ROLE)
//         whenNotPaused
//         returns (uint256)
//     {
//         PlatformMetricsReport memory platformReport = PlatformMetricsReport({
//             totalActivePatients: getTotalActivePatients(),
//             totalActiveDoctors: getTotalActiveDoctors(),
//             totalTreatmentPlans: getTotalTreatmentPlans(),
//             averageAdherenceRate: calculatePlatformAdherenceRate(),
//             totalRewardsDistributed: calculateTotalRewardsDistributed(),
//             systemUtilization: calculateSystemUtilization()
//         });

//         return _createReport(ReportType.PLATFORM_METRICS, platformReport);
//     }

//     // New report generation functions
//     function generateHealthTrendsReport(
//         uint256 timeframe
//     ) external onlyRole(REPORT_GENERATOR_ROLE) whenNotPaused returns (uint256) {
//         HealthTrendsReport memory healthReport = HealthTrendsReport({
//             timeframe: timeframe,
//             averageVitals: calculateAverageVitals(timeframe),
//             wearableMetrics: aggregateWearableData(timeframe),
//             overallHealthScore: calculateOverallHealthScore(),
//             improvementRate: calculateImprovementRate(timeframe),
//             emergencyStats: getEmergencyStatistics(timeframe)
//         });

//         uint256 reportId = _createReport(
//             ReportType.HEALTH_TRENDS,
//             abi.encode(healthReport)
//         );
//         emit HealthTrendsReportGenerated(reportId, timeframe);
//         return reportId;
//     }

//     function generateFinancialReport()
//         external
//         onlyRole(REPORT_GENERATOR_ROLE)
//         whenNotPaused
//         returns (uint256)
//     {
//         FinancialMetricsReport memory financialReport = FinancialMetricsReport({
//             totalRevenue: calculateTotalRevenue(),
//             rewardsDistributed: calculateTotalRewardsDistributed(),
//             tokenomics: getTokenomicsMetrics(),
//             payments: getPaymentStatistics(),
//             averageSessionCost: calculateAverageSessionCost(),
//             platformFees: calculatePlatformFees()
//         });

//         uint256 reportId = _createReport(
//             ReportType.FINANCIAL_METRICS,
//             abi.encode(financialReport)
//         );
//         emit FinancialReportGenerated(reportId, financialReport.totalRevenue);
//         return reportId;
//     }

//     // Internal helper functions
//     function _createReport(
//         ReportType reportType,
//         bytes memory reportData
//     ) internal returns (uint256) {
//         reportCounter++;

//         // Generate IPFS hash from report data
//         string memory ipfsHash = generateIPFSHash(reportData);

//         reports[reportCounter] = Report({
//             reportId: reportCounter,
//             reportType: reportType,
//             ipfsHash: ipfsHash,
//             timestamp: block.timestamp,
//             requestedBy: msg.sender,
//             isConfidential: isConfidentialReport(reportType)
//         });

//         userReports[msg.sender][reportType].push(reportCounter);

//         emit ReportGenerated(reportCounter, reportType, msg.sender);
//         return reportCounter;
//     }

//     // Enhanced helper functions with actual implementations
//     function calculatePatientAdherence(
//         address patient
//     ) internal view returns (uint256) {
//         uint256 totalSessions = getCompletedSessions(patient);
//         uint256 scheduledSessions = getScheduledSessions(patient);

//         if (scheduledSessions == 0) return 0;
//         return (totalSessions * 100) / scheduledSessions;
//     }

//     function getCompletedSessions(
//         address patient
//     ) internal view returns (uint256) {
//         uint256[] memory treatmentPlans = patientProfile
//             .getActiveTreatmentPlans(patient);
//         uint256 totalCompleted = 0;

//         for (uint256 i = 0; i < treatmentPlans.length; i++) {
//             totalCompleted += analytics.getCompletedSessionsForPlan(
//                 treatmentPlans[i]
//             );
//         }

//         return totalCompleted;
//     }

//     function getScheduledSessions(
//         address patient
//     ) internal view returns (uint256) {
//         uint256[] memory treatmentPlans = patientProfile
//             .getActiveTreatmentPlans(patient);
//         uint256 totalScheduled = 0;

//         for (uint256 i = 0; i < treatmentPlans.length; i++) {
//             totalScheduled += analytics.getScheduledSessionsForPlan(
//                 treatmentPlans[i]
//             );
//         }

//         return totalScheduled;
//     }

//     function getHealthMetricsHistory(
//         address patient
//     ) internal view returns (uint256[] memory) {
//         PatientMonitoring.HealthMetrics[] memory metrics = patientMonitoring
//             .getHealthMetricsHistory(patient);
//         uint256[] memory history = new uint256[](metrics.length * 6); // 6 metrics per record

//         for (uint256 i = 0; i < metrics.length; i++) {
//             uint256 baseIndex = i * 6;
//             history[baseIndex] = metrics[i].heartRate;
//             history[baseIndex + 1] = metrics[i].bloodPressureSystolic;
//             history[baseIndex + 2] = metrics[i].bloodPressureDiastolic;
//             history[baseIndex + 3] = metrics[i].bodyTemperature;
//             history[baseIndex + 4] = metrics[i].oxygenSaturation;
//             history[baseIndex + 5] = metrics[i].respiratoryRate;
//         }

//         return history;
//     }

//     function calculateTreatmentEffectiveness(
//         address patient
//     ) internal view returns (uint256) {
//         uint256[] memory treatmentPlans = patientProfile
//             .getActiveTreatmentPlans(patient);
//         if (treatmentPlans.length == 0) return 0;

//         uint256 totalEffectiveness = 0;
//         for (uint256 i = 0; i < treatmentPlans.length; i++) {
//             totalEffectiveness += analytics.getTreatmentEffectiveness(
//                 treatmentPlans[i]
//             );
//         }

//         return totalEffectiveness / treatmentPlans.length;
//     }

//     function getActivePatientCount(
//         address doctor
//     ) internal view returns (uint256) {
//         address[] memory patients = doctorProfile.getProfile(doctor);
//         uint256 activeCount = 0;

//         for (uint256 i = 0; i < patients.length; i++) {
//             if (patientProfile.isActivePatient(patients[i])) {
//                 activeCount++;
//             }
//         }

//         return activeCount;
//     }

//     function calculateAveragePatientProgress(
//         address doctor
//     ) internal view returns (uint256) {
//         address[] memory patients = doctorProfile.getProfile(doctor);
//         if (patients.length == 0) return 0;

//         uint256 totalProgress = 0;
//         uint256 activePatients = 0;

//         for (uint256 i = 0; i < patients.length; i++) {
//             if (patientProfile.isActivePatient(patients[i])) {
//                 totalProgress += calculatePatientProgress(patients[i]);
//                 activePatients++;
//             }
//         }

//         return activePatients > 0 ? totalProgress / activePatients : 0;
//     }

//     function calculatePatientProgress(
//         address patient
//     ) internal view returns (uint256) {
//         uint256 adherence = calculatePatientAdherence(patient);
//         uint256 effectiveness = calculateTreatmentEffectiveness(patient);
//         uint256 healthImprovement = calculateHealthImprovement(patient);

//         // Weighted average: 40% adherence, 30% effectiveness, 30% health improvement
//         return
//             (adherence * 40 + effectiveness * 30 + healthImprovement * 30) /
//             100;
//     }

//     function calculateHealthImprovement(
//         address patient
//     ) internal view returns (uint256) {
//         PatientMonitoring.HealthMetrics[] memory metrics = patientMonitoring
//             .getHealthMetricsHistory(patient);
//         if (metrics.length < 2) return 0;

//         // Compare latest metrics with baseline (first metrics)
//         uint256 improvement = compareHealthMetrics(
//             metrics[metrics.length - 1],
//             metrics[0]
//         );
//         return improvement;
//     }

//     function compareHealthMetrics(
//         PatientMonitoring.HealthMetrics memory current,
//         PatientMonitoring.HealthMetrics memory baseline
//     ) internal pure returns (uint256) {
//         // Calculate improvement percentage for each metric
//         uint256 heartRateImprovement = calculateMetricImprovement(
//             current.heartRate,
//             baseline.heartRate
//         );
//         uint256 bpImprovement = calculateMetricImprovement(
//             current.bloodPressureSystolic + current.bloodPressureDiastolic,
//             baseline.bloodPressureSystolic + baseline.bloodPressureDiastolic
//         );
//         uint256 oxygenImprovement = calculateMetricImprovement(
//             current.oxygenSaturation,
//             baseline.oxygenSaturation
//         );

//         // Return weighted average of improvements
//         return (heartRateImprovement + bpImprovement + oxygenImprovement) / 3;
//     }

//     function calculateMetricImprovement(
//         uint256 current,
//         uint256 baseline
//     ) internal pure returns (uint256) {
//         if (baseline == 0) return 0;
//         uint256 difference = current > baseline
//             ? current - baseline
//             : baseline - current;
//         return (difference * 100) / baseline;
//     }

//     function calculateTreatmentSuccessRate(
//         address doctor
//     ) internal view returns (uint256) {
//         address[] memory patients = doctorProfile.getProfile(doctor);
//         if (patients.length == 0) return 0;

//         uint256 successfulTreatments = 0;
//         uint256 totalCompletedTreatments = 0;

//         for (uint256 i = 0; i < patients.length; i++) {
//             (uint256 successful, uint256 total) = getPatientTreatmentOutcomes(
//                 patients[i]
//             );
//             successfulTreatments += successful;
//             totalCompletedTreatments += total;
//         }

//         return
//             totalCompletedTreatments > 0
//                 ? (successfulTreatments * 100) / totalCompletedTreatments
//                 : 0;
//     }

//     function getPatientTreatmentOutcomes(
//         address patient
//     ) internal view returns (uint256 successful, uint256 total) {
//         uint256[] memory completedPlans = patientProfile
//             .getCompletedTreatmentPlans(patient);
//         total = completedPlans.length;

//         for (uint256 i = 0; i < completedPlans.length; i++) {
//             if (analytics.isTreatmentSuccessful(completedPlans[i])) {
//                 successful++;
//             }
//         }
//     }

//     // Platform-wide metrics calculations
//     function getTotalActivePatients() internal view returns (uint256) {
//         return analytics.getTotalActivePatients();
//     }

//     function getTotalActiveDoctors() internal view returns (uint256) {
//         return analytics.getTotalActiveDoctors();
//     }

//     function getTotalTreatmentPlans() internal view returns (uint256) {
//         return analytics.getTotalTreatmentPlans();
//     }

//     function calculatePlatformAdherenceRate() internal view returns (uint256) {
//         uint256 totalPatients = getTotalActivePatients();
//         if (totalPatients == 0) return 0;

//         uint256 totalAdherence = 0;
//         address[] memory allPatients = analytics.getAllActivePatients();

//         for (uint256 i = 0; i < allPatients.length; i++) {
//             totalAdherence += calculatePatientAdherence(allPatients[i]);
//         }

//         return totalAdherence / totalPatients;
//     }

//     function calculateTotalRewardsDistributed()
//         internal
//         view
//         returns (uint256)
//     {
//         return
//             doctorRewards.getTotalRewardsDistributed() +
//             patientRewards.getTotalRewardsDistributed();
//     }

//     function calculateSystemUtilization() internal view returns (uint256) {
//         uint256 totalCapacity = getTotalActiveDoctors() * 100; // Assuming 100 patients per doctor capacity
//         uint256 currentPatients = getTotalActivePatients();

//         return totalCapacity > 0 ? (currentPatients * 100) / totalCapacity : 0;
//     }

//     // Enhanced IPFS hash generation
//     function generateIPFSHash(
//         bytes memory data
//     ) internal pure returns (string memory) {
//         // This would typically integrate with IPFS
//         // For now, return a hash of the data
//         bytes32 hash = keccak256(data);
//         return bytes32ToHexString(hash);
//     }

//     function bytes32ToHexString(
//         bytes32 data
//     ) internal pure returns (string memory) {
//         bytes memory hexChars = "0123456789abcdef";
//         bytes memory result = new bytes(66);
//         result[0] = "0";
//         result[1] = "x";

//         for (uint256 i = 0; i < 32; i++) {
//             result[2 + i * 2] = hexChars[uint8(data[i] >> 4)];
//             result[3 + i * 2] = hexChars[uint8(data[i] & 0x0f)];
//         }

//         return string(result);
//     }

//     // Utility functions
//     function isConfidentialReport(
//         ReportType reportType
//     ) internal pure returns (bool) {
//         // Determine if report type should be confidential
//         return
//             reportType == ReportType.PATIENT_PROGRESS ||
//             reportType == ReportType.DOCTOR_PERFORMANCE;
//     }

//     // Admin functions
//     function pause() external onlyRole(ADMIN_ROLE) {
//         _pause();
//     }

//     function unpause() external onlyRole(ADMIN_ROLE) {
//         _unpause();
//     }

//     // Override required function
//     function supportsInterface(
//         bytes4 interfaceId
//     ) public view override(AccessControl) returns (bool) {
//         return super.supportsInterface(interfaceId);
//     }

//     // Helper functions for new reports
//     function calculateAverageVitals(
//         uint256 timeframe
//     ) internal view returns (uint256[] memory) {
//         uint256[] memory averages = new uint256[](6); // 6 vital metrics
//         uint256 startTime = block.timestamp - timeframe;

//         address[] memory allPatients = analytics.getAllActivePatients();
//         for (uint256 i = 0; i < allPatients.length; i++) {
//             PatientMonitoring.HealthMetrics[] memory metrics = patientMonitoring
//                 .getHealthMetricsInTimeframe(allPatients[i], startTime);

//             for (uint256 j = 0; j < metrics.length; j++) {
//                 averages[0] += metrics[j].heartRate;
//                 averages[1] += metrics[j].bloodPressureSystolic;
//                 averages[2] += metrics[j].bloodPressureDiastolic;
//                 averages[3] += metrics[j].bodyTemperature;
//                 averages[4] += metrics[j].oxygenSaturation;
//                 averages[5] += metrics[j].respiratoryRate;
//             }
//         }

//         uint256 totalPatients = allPatients.length;
//         if (totalPatients > 0) {
//             for (uint256 i = 0; i < averages.length; i++) {
//                 averages[i] = averages[i] / totalPatients;
//             }
//         }

//         return averages;
//     }

//     function aggregateWearableData(
//         uint256 timeframe
//     ) internal view returns (uint256[] memory) {
//         uint256[] memory wearableMetrics = new uint256[](3); // steps, calories, sleep
//         uint256 startTime = block.timestamp - timeframe;

//         address[] memory allPatients = analytics.getAllActivePatients();
//         for (uint256 i = 0; i < allPatients.length; i++) {
//             (uint256 steps, uint256 calories, uint256 sleep) = wearableData
//                 .getAggregatedData(allPatients[i], startTime);

//             wearableMetrics[0] += steps;
//             wearableMetrics[1] += calories;
//             wearableMetrics[2] += sleep;
//         }

//         uint256 totalPatients = allPatients.length;
//         if (totalPatients > 0) {
//             for (uint256 i = 0; i < wearableMetrics.length; i++) {
//                 wearableMetrics[i] = wearableMetrics[i] / totalPatients;
//             }
//         }

//         return wearableMetrics;
//     }

//     function calculateOverallHealthScore() internal view returns (uint256) {
//         address[] memory allPatients = analytics.getAllActivePatients();
//         if (allPatients.length == 0) return 0;

//         uint256 totalScore = 0;
//         for (uint256 i = 0; i < allPatients.length; i++) {
//             totalScore += calculatePatientHealthScore(allPatients[i]);
//         }

//         return totalScore / allPatients.length;
//     }

//     function calculatePatientHealthScore(
//         address patient
//     ) internal view returns (uint256) {
//         uint256 vitalScore = calculateVitalScore(patient);
//         uint256 adherenceScore = calculatePatientAdherence(patient);
//         uint256 progressScore = calculatePatientProgress(patient);

//         // Weighted average: vitals (40%), adherence (30%), progress (30%)
//         return
//             (vitalScore * 40 + adherenceScore * 30 + progressScore * 30) / 100;
//     }

//     function calculateVitalScore(
//         address patient
//     ) internal view returns (uint256) {
//         PatientMonitoring.HealthMetrics memory latest = patientMonitoring
//             .getLatestMetrics(patient);

//         uint256 score = 0;
//         // Heart rate within normal range (60-100)
//         if (latest.heartRate >= 60 && latest.heartRate <= 100) score += 20;
//         // Blood pressure within normal range (systolic: 90-120, diastolic: 60-80)
//         if (
//             latest.bloodPressureSystolic >= 90 &&
//             latest.bloodPressureSystolic <= 120
//         ) score += 20;
//         if (
//             latest.bloodPressureDiastolic >= 60 &&
//             latest.bloodPressureDiastolic <= 80
//         ) score += 20;
//         // Oxygen saturation above 95%
//         if (latest.oxygenSaturation >= 95) score += 20;
//         // Respiratory rate within normal range (12-20)
//         if (latest.respiratoryRate >= 12 && latest.respiratoryRate <= 20)
//             score += 20;

//         return score;
//     }

//     function calculateImprovementRate(
//         uint256 timeframe
//     ) internal view returns (uint256) {
//         // Implementation
//     }

//     function getEmergencyStatistics(
//         uint256 timeframe
//     ) internal view returns (EmergencyIncidents memory) {
//         // Implementation
//     }

//     function calculateAverageSessionCost() internal view returns (uint256) {
//         // Implementation
//     }

//     function calculatePlatformFees() internal view returns (uint256) {
//         // Implementation
//     }

//     function calculateTotalRevenue() internal view returns (uint256) {
//         // Implementation
//     }

//     function getTokenomicsMetrics()
//         internal
//         view
//         returns (TokenomicsMetrics memory)
//     {
//         // Implementation
//     }

//     function getPaymentStatistics()
//         internal
//         view
//         returns (PaymentStats memory)
//     {
//         // Implementation
//     }

//     function calculateAverageRating(
//         address doctor
//     ) internal view returns (uint256) {
//         // Get ratings from doctor profile or analytics contract
//         uint256 totalRatings = doctorProfile.getTotalRatings(doctor);
//         uint256 ratingSum = doctorProfile.getRatingSum(doctor);

//         return totalRatings > 0 ? ratingSum / totalRatings : 0;
//     }
// }
