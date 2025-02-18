// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract DataManagement is AccessControl {
    bytes32 public constant DATA_MANAGER_ROLE = keccak256("DATA_MANAGER_ROLE");

    // Doctor Metrics
    mapping(address => uint256) public doctorAdherence; // Adherence rate (e.g., percentage)
    mapping(address => uint256) public doctorOutcomes; // Outcome score (e.g., average patient improvement)
    mapping(address => uint256) public doctorPeerReviews; // Peer review score (e.g., feedback from other doctors)

    // Patient Metrics
    mapping(address => uint256) public patientMilestones; // Number of milestones achieved
    mapping(address => uint256) public patientAdherence; // Adherence rate (e.g., percentage)

    // Institution Metrics
    mapping(address => uint256) public institutionScores; // Overall performance score (e.g., aggregated employee scores)

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Function to update a doctor's adherence rate
     * @param doctor The address of the doctor
     * @param adherenceRate The adherence rate (e.g., percentage)
     */
    function updateDoctorAdherence(
        address doctor,
        uint256 adherenceRate
    ) external onlyRole(DATA_MANAGER_ROLE) {
        require(adherenceRate <= 100, "Adherence rate cannot exceed 100%");
        doctorAdherence[doctor] = adherenceRate;
    }

    /**
     * @dev Function to update a doctor's outcome score
     * @param doctor The address of the doctor
     * @param outcomeScore The outcome score (e.g., average patient improvement)
     */
    function updateDoctorOutcome(
        address doctor,
        uint256 outcomeScore
    ) external onlyRole(DATA_MANAGER_ROLE) {
        doctorOutcomes[doctor] = outcomeScore;
    }

    /**
     * @dev Function to update a doctor's peer review score
     * @param doctor The address of the doctor
     * @param peerReviewScore The peer review score (e.g., feedback from other doctors)
     */
    function updateDoctorPeerReview(
        address doctor,
        uint256 peerReviewScore
    ) external onlyRole(DATA_MANAGER_ROLE) {
        doctorPeerReviews[doctor] = peerReviewScore;
    }

    /**
     * @dev Function to update a patient's milestone progress
     * @param patient The address of the patient
     * @param milestones The number of milestones achieved
     */
    function updatePatientMilestones(
        address patient,
        uint256 milestones
    ) external onlyRole(DATA_MANAGER_ROLE) {
        patientMilestones[patient] += milestones;
    }

    /**
     * @dev Function to update a patient's adherence rate
     * @param patient The address of the patient
     * @param adherenceRate The adherence rate (e.g., percentage)
     */
    function updatePatientAdherence(
        address patient,
        uint256 adherenceRate
    ) external onlyRole(DATA_MANAGER_ROLE) {
        require(adherenceRate <= 100, "Adherence rate cannot exceed 100%");
        patientAdherence[patient] = adherenceRate;
    }

    /**
     * @dev Function to update an institution's performance score
     * @param institution The address of the institution
     * @param score The overall performance score (e.g., aggregated employee scores)
     */
    function updateInstitutionScore(
        address institution,
        uint256 score
    ) external onlyRole(DATA_MANAGER_ROLE) {
        institutionScores[institution] = score;
    }

    /**
     * @dev Function to get a doctor's adherence rate
     * @param doctor The address of the doctor
     * @return The adherence rate
     */
    function getDoctorAdherence(
        address doctor
    ) external view returns (uint256) {
        return doctorAdherence[doctor];
    }

    /**
     * @dev Function to get a doctor's outcome score
     * @param doctor The address of the doctor
     * @return The outcome score
     */
    function getDoctorOutcome(address doctor) external view returns (uint256) {
        return doctorOutcomes[doctor];
    }

    /**
     * @dev Function to get a doctor's peer review score
     * @param doctor The address of the doctor
     * @return The peer review score
     */
    function getDoctorPeerReview(
        address doctor
    ) external view returns (uint256) {
        return doctorPeerReviews[doctor];
    }

    /**
     * @dev Function to get a patient's milestone progress
     * @param patient The address of the patient
     * @return The number of milestones achieved
     */
    function getPatientMilestones(
        address patient
    ) external view returns (uint256) {
        return patientMilestones[patient];
    }

    /**
     * @dev Function to get a patient's adherence rate
     * @param patient The address of the patient
     * @return The adherence rate
     */
    function getPatientAdherence(
        address patient
    ) external view returns (uint256) {
        return patientAdherence[patient];
    }

    /**
     * @dev Function to get an institution's performance score
     * @param institution The address of the institution
     * @return The performance score
     */
    function getInstitutionScore(
        address institution
    ) external view returns (uint256) {
        return institutionScores[institution];
    }
}
