// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DoctorRewards is AccessControl {
    // Token contract
    IERC20 public physioToken;

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Events
    event DoctorRewarded(address indexed doctor, uint256 rewardAmount);

    // Reward formula weights (future proposal: configurable via frontend)
    uint256 public feedbackWeight = 10; // Weight for patient feedback score
    uint256 public usageWeight = 5; // Weight for usage count
    uint256 public aiWeight = 20; // Weight for AI rating

    // Cumulative rewards tracking (future proposal: leaderboard integration via frontend)
    mapping(address => uint256) public cumulativeRewards;

    // Constructor
    constructor(address physioTokenAddress) {
        _grantRole(ADMIN_ROLE, msg.sender); // Assign ADMIN_ROLE to the deployer
        physioToken = IERC20(physioTokenAddress);
    }

    // Internal function to calculate doctor rewards
    function calculateDoctorReward(
        uint256 patientFeedbackScore,
        uint256 usageCount,
        uint256 aiRating
    ) internal view returns (uint256) {
        uint256 baseReward = (patientFeedbackScore * feedbackWeight) +
            (usageCount * usageWeight) +
            (aiRating * aiWeight);

        // Convert to token decimals (18)
        return baseReward * 1e18;
    }

    // Reward doctors based on performance metrics
    function rewardDoctor(
        address doctor,
        uint256 patientFeedbackScore,
        uint256 usageCount,
        uint256 aiRating
    ) public onlyRole(ADMIN_ROLE) {
        uint256 rewardAmount = calculateDoctorReward(
            patientFeedbackScore,
            usageCount,
            aiRating
        );

        require(
            physioToken.transfer(doctor, rewardAmount),
            "Token transfer failed"
        );

        cumulativeRewards[doctor] += rewardAmount;

        emit DoctorRewarded(doctor, rewardAmount);
    }

    // Update reward formula weights (future proposal: allow admins to configure via frontend)
    function updateWeights(
        uint256 newFeedbackWeight,
        uint256 newUsageWeight,
        uint256 newAiWeight
    ) public onlyRole(ADMIN_ROLE) {
        feedbackWeight = newFeedbackWeight;
        usageWeight = newUsageWeight;
        aiWeight = newAiWeight;
    }

    // Batch reward distribution for multiple doctors (future proposal: optimize frontend for bulk actions)
    function rewardDoctorsBatch(
        address[] calldata doctors,
        uint256[] calldata patientFeedbackScores,
        uint256[] calldata usageCounts,
        uint256[] calldata aiRatings
    ) public onlyRole(ADMIN_ROLE) {
        require(
            doctors.length == patientFeedbackScores.length &&
                doctors.length == usageCounts.length &&
                doctors.length == aiRatings.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < doctors.length; i++) {
            uint256 rewardAmount = calculateDoctorReward(
                patientFeedbackScores[i],
                usageCounts[i],
                aiRatings[i]
            );

            require(
                physioToken.transfer(doctors[i], rewardAmount),
                "Token transfer failed"
            );
            cumulativeRewards[doctors[i]] += rewardAmount;
            emit DoctorRewarded(doctors[i], rewardAmount);
        }
    }

    // Get cumulative rewards for a doctor (future proposal: display on frontend dashboard)
    function getCumulativeRewards(
        address doctor
    ) public view returns (uint256) {
        return cumulativeRewards[doctor];
    }
}
