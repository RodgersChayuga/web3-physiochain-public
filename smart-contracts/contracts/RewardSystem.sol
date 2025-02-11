// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RewardToken is ERC20, AccessControl {
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");

    constructor() ERC20("PhysioToken", "PHYSIO") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Mint new tokens (only owner can call this)
    function mint(address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }

    // Distribute rewards to patients
    function distributeRewards(address patient, uint256 amount) external onlyRole(DOCTOR_ROLE) {
        _mint(patient, amount);
    }

    // Get balance of a specific patient
    function getBalance(address patient) external view returns (uint256) {
        return balanceOf(patient);
    }
}


// Purpose : Manages the $PHYSIO token rewards system.
// Key Features :
    // Mint and distribute tokens to patients.
    // Allow patients to check their token balances.