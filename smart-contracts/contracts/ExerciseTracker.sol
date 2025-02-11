// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract ExerciseTracker is AccessControl {
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");

    struct ExerciseRecord {
        uint256 tokenId;
        uint256 timestamp;
        uint256 duration;
        bool isCorrectForm;
    }

    mapping(address => ExerciseRecord[]) private exerciseRecords;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Log exercise data for a specific patient and treatment plan
    function logExercise(
        address patient,
        uint256 tokenId,
        uint256 duration,
        bool isCorrectForm
    ) external onlyRole(PATIENT_ROLE) {
        exerciseRecords[patient].push(ExerciseRecord(tokenId, block.timestamp, duration, isCorrectForm));
    }

    // Retrieve exercise data for a specific patient and treatment plan
    function getExerciseData(address patient, uint256 tokenId) external view onlyRole(DOCTOR_ROLE) returns (ExerciseRecord[] memory) {
        ExerciseRecord[] memory records = new ExerciseRecord[](exerciseRecords[patient].length);
        uint256 count = 0;
        for (uint256 i = 0; i < exerciseRecords[patient].length; i++) {
            if (exerciseRecords[patient][i].tokenId == tokenId) {
                records[count] = exerciseRecords[patient][i];
                count++;
            }
        }
        // Resize the array to the correct length
        assembly {
            mstore(records, count)
        }
        return records;
    }

    // Retrieve all exercise data for a specific patient
    function getAllExerciseData(address patient) external view onlyRole(DOCTOR_ROLE) returns (ExerciseRecord[] memory) {
        return exerciseRecords[patient];
    }
}


// Purpose : Tracks exercises completed by patients.
// Key Features :
    // Log exercise data (duration, form correctness).
    // Retrieve exercise logs for patients and doctors.