// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PhysioToken is ERC20, Ownable, AccessControl {
    // Define roles for minting and burning
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Total supply of tokens
    uint256 public constant INITIAL_SUPPLY = 1000000000 * 10 ** 18; // 1 billion tokens with 18 decimals

    // Constructor to initialize the token
    constructor() ERC20("PhysioToken", "PHY") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY); // Mint initial supply to the contract deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Set the contract owner as the default admin
    }

    /**
     * @dev Function to mint new tokens (only callable by addresses with the MINTER_ROLE)
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Function to burn tokens (only callable by addresses with the BURNER_ROLE)
     * @param from The address whose tokens will be burned
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    /**
     * @dev Function to grant the MINTER_ROLE to a contract (e.g., DoctorReward, PatientReward, InstitutionReward)
     * @param minter The address to grant the MINTER_ROLE
     */
    function grantMinterRole(address minter) external onlyOwner {
        grantRole(MINTER_ROLE, minter);
    }

    /**
     * @dev Function to revoke the MINTER_ROLE from a contract
     * @param minter The address to revoke the MINTER_ROLE
     */
    function revokeMinterRole(address minter) external onlyOwner {
        revokeRole(MINTER_ROLE, minter);
    }

    /**
     * @dev Function to grant the BURNER_ROLE to a contract (e.g., Payment and Redemption Contract)
     * @param burner The address to grant the BURNER_ROLE
     */
    function grantBurnerRole(address burner) external onlyOwner {
        grantRole(BURNER_ROLE, burner);
    }

    /**
     * @dev Function to revoke the BURNER_ROLE from a contract
     * @param burner The address to revoke the BURNER_ROLE
     */
    function revokeBurnerRole(address burner) external onlyOwner {
        revokeRole(BURNER_ROLE, burner);
    }
}
