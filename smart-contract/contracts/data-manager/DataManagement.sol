// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract DataManagement is AccessControl {
    bytes32 public constant DATA_MANAGER_ROLE = keccak256("DATA_MANAGER_ROLE");

    // Provider Metrics
    mapping(address => uint256) public providerAdherenceRate; // Adherence rate to clinical guidelines (e.g., percentage)
    mapping(address => uint256) public providerOutcomeScore; // Outcome score (e.g., average patient improvement)
    mapping(address => uint256) public providerPeerReviewScore; // Peer review score (e.g., feedback from other providers)

    // Patient Metrics
    mapping(address => uint256) public patientMilestoneCount; // Number of milestones achieved
    mapping(address => uint256) public patientAdherenceRate; // Treatment adherence rate (e.g., percentage)

    // Institution Metrics
    mapping(address => uint256) public institutionPerformanceScore; // Overall performance score (e.g., aggregated staff scores)

    // Treatment Plan Completion Metrics
    mapping(uint256 => mapping(address => uint256))
        public treatmentPlanCompletionRate; // Token ID -> Patient -> Completion Percentage

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Function to update a provider's adherence rate to clinical guidelines
     * @param provider The address of the healthcare provider
     * @param adherenceRate The adherence rate (e.g., percentage)
     */
    function updateProviderAdherenceRate(
        address provider,
        uint256 adherenceRate
    ) external onlyRole(DATA_MANAGER_ROLE) {
        require(adherenceRate <= 100, "Adherence rate cannot exceed 100%");
        providerAdherenceRate[provider] = adherenceRate;
    }

    /**
     * @dev Function to update a provider's outcome score
     * @param provider The address of the healthcare provider
     * @param outcomeScore The outcome score (e.g., average patient improvement)
     */
    function updateProviderOutcomeScore(
        address provider,
        uint256 outcomeScore
    ) external onlyRole(DATA_MANAGER_ROLE) {
        providerOutcomeScore[provider] = outcomeScore;
    }

    /**
     * @dev Function to update a provider's peer review score
     * @param provider The address of the healthcare provider
     * @param peerReviewScore The peer review score (e.g., feedback from other providers)
     */
    function updateProviderPeerReviewScore(
        address provider,
        uint256 peerReviewScore
    ) external onlyRole(DATA_MANAGER_ROLE) {
        providerPeerReviewScore[provider] = peerReviewScore;
    }

    /**
     * @dev Function to update a patient's milestone progress
     * @param patient The address of the patient
     * @param milestones The number of milestones achieved
     */
    function updatePatientMilestoneCount(
        address patient,
        uint256 milestones
    ) external onlyRole(DATA_MANAGER_ROLE) {
        patientMilestoneCount[patient] += milestones;
    }

    /**
     * @dev Function to update a patient's adherence rate
     * @param patient The address of the patient
     * @param adherenceRate The adherence rate (e.g., percentage)
     */
    function updatePatientAdherenceRate(
        address patient,
        uint256 adherenceRate
    ) external onlyRole(DATA_MANAGER_ROLE) {
        require(adherenceRate <= 100, "Adherence rate cannot exceed 100%");
        patientAdherenceRate[patient] = adherenceRate;
    }

    /**
     * @dev Function to update an institution's performance score
     * @param institution The address of the institution
     * @param score The overall performance score (e.g., aggregated staff scores)
     */
    function updateInstitutionPerformanceScore(
        address institution,
        uint256 score
    ) external onlyRole(DATA_MANAGER_ROLE) {
        institutionPerformanceScore[institution] = score;
    }

    /**
     * @dev Function to update treatment plan completion percentage
     * @param tokenId The ID of the treatment plan token
     * @param patient The address of the patient
     * @param completionPercentage The percentage of completion
     */
    function updateTreatmentPlanCompletionRate(
        uint256 tokenId,
        address patient,
        uint256 completionPercentage
    ) external onlyRole(DATA_MANAGER_ROLE) {
        require(
            completionPercentage <= 100,
            "Completion percentage cannot exceed 100%"
        );
        treatmentPlanCompletionRate[tokenId][patient] = completionPercentage;
    }

    /**
     * @dev Function to get a provider's adherence rate
     * @param provider The address of the healthcare provider
     * @return The adherence rate
     */
    function getDoctorAdherence(
        address provider
    ) external view returns (uint256) {
        return providerAdherenceRate[provider];
    }

    /**
     * @dev Function to get a provider's outcome score
     * @param provider The address of the healthcare provider
     * @return The outcome score
     */
    function getDoctorOutcome(
        address provider
    ) external view returns (uint256) {
        return providerOutcomeScore[provider];
    }

    /**
     * @dev Function to get a provider's peer review score
     * @param provider The address of the healthcare provider
     * @return The peer review score
     */
    function getDoctorPeerReview(
        address provider
    ) external view returns (uint256) {
        return providerPeerReviewScore[provider];
    }

    /**
     * @dev Function to get a patient's milestone progress
     * @param patient The address of the patient
     * @return The number of milestones achieved
     */
    function getPatientMilestones(
        address patient
    ) external view returns (uint256) {
        return patientMilestoneCount[patient];
    }

    /**
     * @dev Function to get a patient's adherence rate
     * @param patient The address of the patient
     * @return The adherence rate
     */
    function getPatientAdherence(
        address patient
    ) external view returns (uint256) {
        return patientAdherenceRate[patient];
    }

    /**
     * @dev Function to get an institution's performance score
     * @param institution The address of the institution
     * @return The performance score
     */
    function getInstitutionPerformanceScore(
        address institution
    ) external view returns (uint256) {
        return institutionPerformanceScore[institution];
    }

    /**
     * @dev Function to get treatment plan completion percentage
     * @param tokenId The ID of the treatment plan token
     * @param patient The address of the patient
     * @return The completion percentage
     */
    function getTreatmentPlanCompletionRate(
        uint256 tokenId,
        address patient
    ) external view returns (uint256) {
        return treatmentPlanCompletionRate[tokenId][patient];
    }
}
