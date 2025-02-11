// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Chat is AccessControl {
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");
    bytes32 public constant THERAPIST_ROLE = keccak256("THERAPIST_ROLE");

    struct Message {
        uint256 timestamp;
        address sender;
        string content;
    }

    struct ChatSession {
        uint256 lastMessageId;
        mapping(uint256 => Message) messages;
    }

    mapping(address => mapping(address => ChatSession)) private chatSessions;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Initiate or continue a chat session between a patient and therapist.
     */
    function sendMessage(address recipient, string memory content) external {
        require(
            hasRole(PATIENT_ROLE, msg.sender) ||
                hasRole(THERAPIST_ROLE, msg.sender),
            "Sender must be a patient or therapist"
        );
        require(
            hasRole(PATIENT_ROLE, recipient) ||
                hasRole(THERAPIST_ROLE, recipient),
            "Recipient must be a patient or therapist"
        );

        ChatSession storage session = chatSessions[msg.sender][recipient];
        uint256 messageId = session.lastMessageId + 1;
        session.messages[messageId] = Message(
            block.timestamp,
            msg.sender,
            content
        );
        session.lastMessageId = messageId;
    }

    /**
     * @dev Retrieve all messages in a chat session.
     */
    function getMessages(
        address recipient
    ) external view returns (Message[] memory) {
        require(
            hasRole(PATIENT_ROLE, msg.sender) ||
                hasRole(THERAPIST_ROLE, msg.sender),
            "Sender must be a patient or therapist"
        );
        require(
            hasRole(PATIENT_ROLE, recipient) ||
                hasRole(THERAPIST_ROLE, recipient),
            "Recipient must be a patient or therapist"
        );

        ChatSession storage session = chatSessions[msg.sender][recipient];
        Message[] memory messages = new Message[](session.lastMessageId);
        for (uint256 i = 1; i <= session.lastMessageId; i++) {
            messages[i - 1] = session.messages[i];
        }
        return messages;
    }
}

// 1. Purpose of Chat.sol
// The Chat.sol smart contract serves the following purposes:

// Secure Messaging : Allow patients and therapists to send and receive messages securely.
// Message Storage : Store messages on-chain for transparency and accountability.
// Access Control : Ensure only authorized users can access chat data.
