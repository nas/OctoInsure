// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPolicy {
    // A Claim will store the information about a participant
    // on a particular policy.
    struct Claim {
        address claimant;
        uint256 amount;
        bool approved;
        uint256 approvalCount;
        address[] voters;
    }

    // A policy is created by an owner with the right parameters.
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

    // emit this event when ever a policy is created
    event PolicyCreated(
        uint256 indexed policyId,
        address indexed owner,
        string name,
        uint256 duration,
        uint256 totalPremium
    );

    // Emit this event whenever a premium is paid by a participant
    event PremiumPaid(
        uint256 indexed policyId,
        address indexed participant,
        uint256 amount
    );

    // Emit this event when a claim is submitted by a participant on a policy
    event ClaimSubmitted(
        uint256 indexed policyId,
        address indexed claimant,
        uint256 amount
    );

    // Emit this event when a claim is approved
    event ClaimApproved(
        uint256 indexed policyId,
        uint256 indexed claimIndex,
        address indexed approver,
        address claimant,
        uint256 amount
    );

    // Emit this event when a payout is process for a participant or claimant
    event PayoutProcessed(
        uint256 indexed policyId,
        address indexed participant,
        uint256 amount
    );
}
