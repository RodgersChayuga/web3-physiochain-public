// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/ChainlinkRequestInterface.sol";
import "./DIDRegistry.sol";

contract GovernmentOracle is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    address public didRegistryAddress;
    uint256 public fee;
    bytes32 public jobId;
    address public oracle;

    // Event to log Chainlink requests
    event RequestVerification(
        bytes32 indexed requestId,
        string nationalID,
        string licenseNumber
    );
    event Fulfillment(
        bytes32 indexed requestId,
        bool isVerified,
        string name,
        string licenseStatus
    );

    constructor(
        address _didRegistryAddress,
        address _linkTokenAddress,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) {
        _setChainlinkToken(_linkTokenAddress);
        _setChainlinkOracle(_oracle);
        didRegistryAddress = _didRegistryAddress;
        jobId = _jobId;
        fee = _fee;
        oracle = _oracle;
    }

    /**
     * @notice Requests verification of a doctor's credentials from an external API via Chainlink
     * @param requestId The ID of the request (from DIDRegistry)
     * @param nationalID The national ID of the doctor
     * @param licenseNumber The medical license number of the doctor
     */
    function requestVerification(
        bytes32 requestId,
        string memory nationalID,
        string memory licenseNumber
    ) public {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Add request-specific parameters
        req.add("nationalID", nationalID);
        req.add("licenseNumber", licenseNumber);
        req.addBytes("requestId", abi.encodePacked(requestId)); // Pass the requestId as bytes

        // Send the Chainlink request
        _sendChainlinkRequestTo(oracle, req, fee);

        emit RequestVerification(requestId, nationalID, licenseNumber);
    }

    /**
     * @notice Callback function used by the Chainlink oracle to return verification results
     * @param _requestId The Chainlink request ID
     * @param _isVerified Whether the doctor's credentials are verified
     * @param _name The doctor's name (from external API)
     * @param _licenseStatus The status of the doctor's license
     */
    function fulfill(
        bytes32 _requestId,
        bool _isVerified,
        string memory _name,
        string memory _licenseStatus
    ) public recordChainlinkFulfillment(_requestId) {
        // Decode the original requestId passed in the request
        // For simplicity, we assume the oracle returns the requestId as part of the response
        // In a real implementation, you'd need to map _requestId to the original requestId

        // Call the DIDRegistry's verifyDoctorRegistration function
        DIDRegistry(didRegistryAddress).verifyDoctorRegistration(
            _requestId, // Using _requestId as a placeholder; in practice, map this appropriately
            _isVerified,
            _name,
            _licenseStatus
        );

        emit Fulfillment(_requestId, _isVerified, _name, _licenseStatus);
    }

    /**
     * @notice Update the Chainlink oracle address (optional, for admin use)
     * @param _oracle The new oracle address
     */
    function updateOracle(address _oracle) public {
        // In a real implementation, add access control (e.g., onlyOwner)
        setChainlinkOracle(_oracle);
        oracle = _oracle;
    }

    /**
     * @notice Update the Chainlink job ID (optional, for admin use)
     * @param _jobId The new job ID
     */
    function updateJobId(bytes32 _jobId) public {
        // In a real implementation, add access control
        jobId = _jobId;
    }

    /**
     * @notice Update the Chainlink request fee (optional, for admin use)
     * @param _fee The new fee
     */
    function updateFee(uint256 _fee) public {
        // In a real implementation, add access control
        fee = _fee;
    }

    /**
     * @notice Withdraw LINK tokens from the contract (optional, for admin use)
     */
    function withdrawLink() public {
        // In a real implementation, add access control
        LinkTokenInterface link = LinkTokenInterface(_chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
