// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./PhysioToken.sol";
import "../data-manager/DataManagement.sol";

contract DoctorReward is AccessControl {
    bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");

    PhysioToken public physioToken;
    DataManagement public dataManagement;

    // Mapping to track doctor rewards
    mapping(address => uint256) public doctorRewards;

    constructor(address _physioTokenAddress, address _dataManagementAddress) {
        physioToken = PhysioToken(_physioTokenAddress);
        dataManagement = DataManagement(_dataManagementAddress);

        // Grant MINTER_ROLE to this contract
        // physioToken.grantRole(physioToken.MINTER_ROLE(), address(this));

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Function to calculate and distribute rewards to a doctor
     * @param doctor The address of the doctor
     */
    function checkAndRewardDoctor(
        address doctor
    ) external onlyRole(REWARDER_ROLE) {
        // Fetch metrics using consistent function names
        uint256 adherenceRate = dataManagement.getDoctorAdherence(doctor);
        uint256 outcomeScore = dataManagement.getDoctorOutcome(doctor);
        uint256 peerReviewScore = dataManagement.getDoctorPeerReview(doctor);

        // Combine metrics into a single performance score
        uint256 performanceScore = calculatePerformanceScore(
            adherenceRate,
            outcomeScore,
            peerReviewScore
        );

        // Calculate reward based on performance score
        uint256 rewardAmount = calculateReward(performanceScore);

        // Mint tokens for the doctor
        physioToken.mint(doctor, rewardAmount);

        // Update rewards mapping
        doctorRewards[doctor] += rewardAmount;

        emit DoctorRewarded(doctor, rewardAmount);
    }

    /**
     * @dev Internal function to calculate a doctor's performance score
     * @param adherenceRate The adherence rate (e.g., percentage)
     * @param outcomeScore The outcome score (e.g., average patient improvement)
     * @param peerReviewScore The peer review score (e.g., feedback from other doctors)
     * @return The combined performance score
     */
    function calculatePerformanceScore(
        uint256 adherenceRate,
        uint256 outcomeScore,
        uint256 peerReviewScore
    ) internal pure returns (uint256) {
        // Example formula: Weighted sum of metrics
        return
            (adherenceRate * 40 + outcomeScore * 40 + peerReviewScore * 20) /
            100;
    }

    /**
     * @dev Internal function to calculate rewards based on performance score
     * @param score The performance score of the doctor
     * @return The reward amount in tokens
     */
    function calculateReward(uint256 score) internal pure returns (uint256) {
        // Convert score to tokens with 18 decimals
        return score * 10 * 1e18; // 10 tokens per score point, with 18 decimals
    }

    /**
     * @dev Event emitted when a doctor is rewarded
     */
    event DoctorRewarded(address indexed doctor, uint256 rewardAmount);
}
