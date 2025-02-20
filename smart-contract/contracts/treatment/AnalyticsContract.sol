// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AnalyticsContract is AccessControl {
    struct LeaderboardEntry {
        address user;
        uint256 score;
    }

    mapping(uint256 => uint256) public usageCounts; // Token ID -> Usage Count
    LeaderboardEntry[] public doctorLeaderboard;
    LeaderboardEntry[] public patientLeaderboard;

    bytes32 public constant ANALYTICS_MANAGER_ROLE =
        keccak256("ANALYTICS_MANAGER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Increment usage count for a treatment plan
    function incrementUsage(
        uint256 tokenId
    ) external onlyRole(ANALYTICS_MANAGER_ROLE) {
        usageCounts[tokenId]++;
    }

    // Update doctor leaderboard
    function updateDoctorLeaderboard(
        address doctor,
        uint256 score
    ) external onlyRole(ANALYTICS_MANAGER_ROLE) {
        doctorLeaderboard.push(LeaderboardEntry({user: doctor, score: score}));
    }

    // Update patient leaderboard
    function updatePatientLeaderboard(
        address patient,
        uint256 score
    ) external onlyRole(ANALYTICS_MANAGER_ROLE) {
        patientLeaderboard.push(
            LeaderboardEntry({user: patient, score: score})
        );
    }

    // Get usage count for a treatment plan
    function getUsageCount(uint256 tokenId) external view returns (uint256) {
        return usageCounts[tokenId];
    }

    // Get doctor leaderboard
    function getDoctorLeaderboard()
        external
        view
        returns (LeaderboardEntry[] memory)
    {
        return doctorLeaderboard;
    }

    // Get patient leaderboard
    function getPatientLeaderboard()
        external
        view
        returns (LeaderboardEntry[] memory)
    {
        return patientLeaderboard;
    }
}
