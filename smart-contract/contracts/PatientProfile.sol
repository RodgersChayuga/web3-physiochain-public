// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract PatientProfile is AccessControl {
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");
    bytes32 public constant THERAPIST_ROLE = keccak256("THERAPIST_ROLE");

    struct Goal {
        string description;
        bool achieved;
    }

    mapping(address => Goal[]) private goals;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Set a new goal for the patient
    function setGoal(
        string memory description
    ) external onlyRole(PATIENT_ROLE) {
        goals[msg.sender].push(Goal(description, false));
    }

    // Mark a goal as achieved
    function achieveGoal(uint256 goalIndex) external onlyRole(PATIENT_ROLE) {
        require(
            !goals[msg.sender][goalIndex].achieved,
            "Goal already achieved"
        );
        goals[msg.sender][goalIndex].achieved = true;
    }

    // Get all goals for a specific patient
    function getGoals(
        address patient
    )
        external
        view
        onlyRole(THERAPIST_ROLE)
        returns (string[] memory, bool[] memory)
    {
        Goal[] storage patientGoals = goals[patient];
        string[] memory descriptions = new string[](patientGoals.length);
        bool[] memory achieved = new bool[](patientGoals.length);
        for (uint256 i = 0; i < patientGoals.length; i++) {
            descriptions[i] = patientGoals[i].description;
            achieved[i] = patientGoals[i].achieved;
        }
        return (descriptions, achieved);
    }
}
