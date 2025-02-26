// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IFrontendIntegration {
    // Common data structures
    struct DashboardData {
        uint256 timestamp;
        bool isActive;
        string ipfsProfileData;
        uint256[] metrics;
    }

    struct NotificationData {
        uint256 id;
        string notificationType;
        string message;
        uint256 timestamp;
        bool isRead;
    }

    struct SessionData {
        uint256 sessionId;
        uint256 timestamp;
        address doctor;
        address patient;
        string sessionType;
        string status;
    }
}
