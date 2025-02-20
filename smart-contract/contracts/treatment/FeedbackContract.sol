// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract FeedbackContract is AccessControl {
    struct Review {
        address reviewer;
        uint256 rating;
        string comment;
    }

    mapping(uint256 => Review[]) public reviews; // Token ID -> List of reviews

    bytes32 public constant REVIEWER_ROLE = keccak256("REVIEWER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Submit a review for a treatment plan
    function submitReview(
        uint256 tokenId,
        uint256 rating,
        string memory comment
    ) external {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        reviews[tokenId].push(
            Review({reviewer: msg.sender, rating: rating, comment: comment})
        );
    }

    // Get average rating for a treatment plan
    function getAverageRating(uint256 tokenId) external view returns (uint256) {
        uint256 totalRatings = 0;
        uint256 count = reviews[tokenId].length;
        for (uint256 i = 0; i < count; i++) {
            totalRatings += reviews[tokenId][i].rating;
        }
        return count > 0 ? totalRatings / count : 0;
    }
}
