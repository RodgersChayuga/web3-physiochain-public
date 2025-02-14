// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PatientRewards {
    // Token contract
    IERC20 public physioToken;

    // Struct to track patient progress
    struct PatientProgress {
        uint256 totalSessionsCompleted;
        uint256 currentStreak; // Days of consecutive adherence
        uint256 lastExerciseTimestamp;
        uint256 milestonesAchieved;
    }

    // Mapping to store patient progress
    mapping(address => PatientProgress) public patientProgress;

    // Milestone thresholds
    uint256 public constant SESSIONS_PER_MILESTONE = 10;
    uint256 public constant STREAK_THRESHOLD = 7; // Days
    uint256 public constant REWARD_PER_SESSION = 10 ether; // Example reward
    uint256 public constant MILESTONE_REWARD = 100 ether; // Example reward

    // Events
    event ExerciseCompleted(address indexed patient, uint256 sessionsCompleted);
    event MilestoneAchieved(
        address indexed patient,
        uint256 milestonesAchieved
    );
    event StreakAchieved(address indexed patient, uint256 currentStreak);

    // Constructor
    constructor(address physioTokenAddress) {
        physioToken = IERC20(physioTokenAddress);
    }

    // Function to log exercise completion
    function logExerciseCompletion() public {
        PatientProgress storage progress = patientProgress[msg.sender];

        // Increment session count
        progress.totalSessionsCompleted += 1;

        // Update streak
        if (block.timestamp - progress.lastExerciseTimestamp <= 1 days) {
            progress.currentStreak += 1;
        } else {
            progress.currentStreak = 1; // Reset streak
        }
        progress.lastExerciseTimestamp = block.timestamp;

        // Check for milestones
        if (progress.totalSessionsCompleted % SESSIONS_PER_MILESTONE == 0) {
            progress.milestonesAchieved += 1;
            _rewardPatient(msg.sender, MILESTONE_REWARD);
            emit MilestoneAchieved(msg.sender, progress.milestonesAchieved);
        }

        // Check for streak achievement
        if (progress.currentStreak >= STREAK_THRESHOLD) {
            _rewardPatient(msg.sender, MILESTONE_REWARD); // Reward for streak
            emit StreakAchieved(msg.sender, progress.currentStreak);
        }

        // Reward for completing a session
        _rewardPatient(msg.sender, REWARD_PER_SESSION);

        emit ExerciseCompleted(msg.sender, progress.totalSessionsCompleted);
    }

    // Internal function to reward patients
    function _rewardPatient(address patient, uint256 amount) internal {
        require(physioToken.transfer(patient, amount), "Token transfer failed");
    }
}
