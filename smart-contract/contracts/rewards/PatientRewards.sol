// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./PhysioToken.sol";
import "../data-manager/DataManagement.sol";

contract PatientRewards is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Token contract
    PhysioToken public physioToken;
    DataManagement public dataManagement;

    // Milestone thresholds
    uint256 public SESSIONS_PER_MILESTONE = 10; // Sessions per milestone
    uint256 public STREAK_THRESHOLD = 7; // Days of consecutive adherence
    uint256 public REWARD_PER_SESSION = 10 ether; // Reward per session
    uint256 public MILESTONE_REWARD = 100 ether; // Reward per milestone

    // Mapping to track last rewarded timestamp for streaks
    mapping(address => uint256) public lastRewardedTimestamp;

    // Events
    event ExerciseCompleted(address indexed patient, uint256 sessionsCompleted);
    event MilestoneAchieved(
        address indexed patient,
        uint256 milestonesAchieved
    );
    event StreakAchieved(address indexed patient, uint256 currentStreak);

    // Constructor
    constructor(address _physioTokenAddress, address _dataManagementAddress) {
        physioToken = PhysioToken(_physioTokenAddress);
        dataManagement = DataManagement(_dataManagementAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Function to check and reward a patient based on their progress
     * @param patient The address of the patient
     */
    function checkAndRewardPatient(address patient) external {
        // Fetch metrics using clearer function names
        uint256 sessionsCompleted = dataManagement.getPatientMilestones(
            patient
        );
        uint256 adherenceRate = dataManagement.getPatientAdherence(patient);

        // Check for milestones
        uint256 milestonesAchieved = sessionsCompleted / SESSIONS_PER_MILESTONE;
        if (milestonesAchieved > 0) {
            _rewardPatient(patient, milestonesAchieved * MILESTONE_REWARD);
            emit MilestoneAchieved(patient, milestonesAchieved);
        }

        // Check for streaks
        if (
            adherenceRate >= 100 &&
            block.timestamp - lastRewardedTimestamp[patient] >=
            STREAK_THRESHOLD * 1 days
        ) {
            _rewardPatient(patient, MILESTONE_REWARD); // Reward for streak
            lastRewardedTimestamp[patient] = block.timestamp;
            emit StreakAchieved(patient, STREAK_THRESHOLD);
        }

        // Reward for completing a session
        _rewardPatient(patient, REWARD_PER_SESSION);
        emit ExerciseCompleted(patient, sessionsCompleted);
    }

    /**
     * @dev Internal function to reward patients
     * @param patient The address of the patient
     * @param amount The reward amount
     */
    function _rewardPatient(address patient, uint256 amount) internal {
        physioToken.mint(patient, amount);
    }

    /**
     * @dev Function to update reward thresholds
     * @param newSessionsPerMilestone The new sessions per milestone threshold
     * @param newStreakThreshold The new streak threshold
     * @param newRewardPerSession The new reward per session
     * @param newMilestoneReward The new milestone reward
     */
    function updateRewardThresholds(
        uint256 newSessionsPerMilestone,
        uint256 newStreakThreshold,
        uint256 newRewardPerSession,
        uint256 newMilestoneReward
    ) external onlyRole(ADMIN_ROLE) {
        SESSIONS_PER_MILESTONE = newSessionsPerMilestone;
        STREAK_THRESHOLD = newStreakThreshold;
        REWARD_PER_SESSION = newRewardPerSession;
        MILESTONE_REWARD = newMilestoneReward;

        emit RewardThresholdsUpdated(
            newSessionsPerMilestone,
            newStreakThreshold,
            newRewardPerSession,
            newMilestoneReward
        );
    }

    /**
     * @dev Event emitted when reward thresholds are updated
     */
    event RewardThresholdsUpdated(
        uint256 newSessionsPerMilestone,
        uint256 newStreakThreshold,
        uint256 newRewardPerSession,
        uint256 newMilestoneReward
    );
}
