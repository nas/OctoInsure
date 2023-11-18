// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPolicy {
    struct Claim {
        address claimant;
        uint256 amount;
        bool approved;
        uint256 approvalCount;
        address[] voters;
    }

    struct Policy {
        uint256 id;
        address owner;
        uint256 duration;
        uint256 monthlyInstallments;
        uint256 totalPremium;
        uint256 premium;
        uint256 remainingPayout;
        bool payoutProcessed;
        string name;
        address[] participants;
        string[] tags;
    }

    event PolicyCreated(
        uint256 indexed policyId,
        address indexed owner,
        string name,
        uint256 duration,
        uint256 totalPremium
    );
    event PremiumPaid(
        uint256 indexed policyId,
        address indexed participant,
        uint256 amount
    );
    event ClaimSubmitted(
        uint256 indexed policyId,
        address indexed claimant,
        uint256 amount
    );
    event ClaimApproved(
        uint256 indexed policyId,
        uint256 indexed claimIndex,
        address indexed approver,
        address claimant,
        uint256 amount
    );
    event PayoutProcessed(
        uint256 indexed policyId,
        address indexed participant,
        uint256 amount
    );
}
