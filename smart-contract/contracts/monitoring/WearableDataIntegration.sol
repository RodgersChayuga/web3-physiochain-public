// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract WearableDataIntegration is AccessControl {
    // Struct to store wearable data
    struct WearableData {
        uint256 steps;
        uint256 caloriesBurned;
        uint256 sleepDuration;
    }

    // Mapping to store wearable data for each user
    mapping(address => WearableData) public wearableData;

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Events
    event WearableDataUpdated(
        address indexed user,
        uint256 steps,
        uint256 caloriesBurned,
        uint256 sleepDuration
    );

    // Constructor
    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // Update wearable data for a user
    function updateWearableData(
        uint256 steps,
        uint256 caloriesBurned,
        uint256 sleepDuration
    ) public {
        wearableData[msg.sender] = WearableData({
            steps: steps,
            caloriesBurned: caloriesBurned,
            sleepDuration: sleepDuration
        });

        emit WearableDataUpdated(
            msg.sender,
            steps,
            caloriesBurned,
            sleepDuration
        );
    }

    // Get wearable data for a user
    function getWearableData(
        address user
    )
        public
        view
        returns (uint256 steps, uint256 caloriesBurned, uint256 sleepDuration)
    {
        WearableData memory data = wearableData[user];
        return (data.steps, data.caloriesBurned, data.sleepDuration);
    }
}
