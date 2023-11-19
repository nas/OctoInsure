// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
import "hardhat/console.sol";

/******************************************************************************\
* @title InsurancePolicyPools
* @author Nasir Jamal <nas@hashleap.io> (https://twitter.com/_nasj)
* @dev: Contract to create insurance policies
*
* High level functionality:
* 1. Anyone should be able to use and create insurance policies
* 2. The protocol should not limit how many policies someone can create
* 3. Every Policy will have a owner who created the policy and other partipants
* 4. Every Policy will have some parameters that will define what can be insured, for how long and what kind of money will be reimbursed.
* 5. When a paricipant submits a claim then everyone has to approve for the claimant to get the money
* 6. At the end of the duration they all will get the left over money back
/******************************************************************************/
import {IPolicy} from "./interfaces/IPolicy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract InsurancePolicy is IPolicy {
    // policyId => claims
    mapping(uint256 => Claim[]) private policyClaims;

    mapping(uint256 => Policy) private policyMap;
    Policy[] public policies;

    uint256 counter;

    modifier onlyOwner(uint256 _policyId) {
        require(
            msg.sender == policies[_policyId].owner,
            "Only the owner can perform this action"
        );
        _;
    }

    modifier payoutNotProcessed(uint256 _policyId) {
        require(
            !policies[_policyId].payoutProcessed,
            "Payout has already been processed"
        );
        _;
    }

    function payPremium(
        uint256 _policyId,
        address _tokenAddress
    ) public payable {
        require(
            block.timestamp < policyMap[_policyId].duration,
            "Policy duration has ended"
        );
        require(_tokenAddress != address(0), "Invalid token passed");

        IERC20 token = IERC20(_tokenAddress);

        uint256 minimumAmount = policyMap[_policyId].premium *
            policyMap[_policyId].monthlyInstallments;

        // Make sure the user has approved the amount before hitting this function
        // require allowance to be at least the amount being deposited
        // Set the allowance to existing allowance for this contract + amount for this transaction
        require(
            token.allowance(msg.sender, address(this)) >= minimumAmount,
            "Insufficient allowance"
        );

        // require users balance to be greater than or equal to the _amount
        require(
            token.balanceOf(msg.sender) >= minimumAmount,
            "Insufficient token balance"
        );

        // transfer the tokens to this address
        SafeERC20.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            policyMap[_policyId].premium
        );

        policyMap[_policyId].totalPremium += policyMap[_policyId].premium;
        // we shuld be tracking each premium payment

        emit PremiumPaid(_policyId, msg.sender, msg.value);
    }

    function createPolicy(
        string memory _name,
        uint256 _monthlyInstallments,
        string[] memory _tags,
        address _tokenAddress,
        uint256 _premium
    ) external {
        Policy memory newPolicy;
        newPolicy.id = counter++;
        newPolicy.owner = msg.sender;
        newPolicy.name = _name;
        newPolicy.monthlyInstallments = _monthlyInstallments;
        newPolicy.duration =
            block.timestamp +
            (_monthlyInstallments * 24 * 60 * 60 * 30);
        newPolicy.tags = _tags;
        newPolicy.premium = _premium;
        policyMap[newPolicy.id].participants = new address[](10);
        policyMap[newPolicy.id].participants[0] = msg.sender;
        policyMap[newPolicy.id] = newPolicy;

        payPremium(newPolicy.id, _tokenAddress);
        emit PolicyCreated(
            policies.length - 1,
            msg.sender,
            _name,
            _monthlyInstallments,
            0
        );
    }

    function submitClaim(uint256 _policyId, uint256 _amount) external {
        require(
            block.timestamp < policies[_policyId].duration,
            "Policy duration has ended"
        );
        require(
            _amount > 0 && _amount <= policies[_policyId].remainingPayout,
            "Invalid claim amount"
        );

        address[] memory noClaimant;
        Claim memory newClaim = Claim({
            claimant: msg.sender,
            amount: _amount,
            approved: false,
            approvalCount: 0,
            voters: noClaimant
        });

        policyClaims[_policyId].push(newClaim);

        emit ClaimSubmitted(_policyId, msg.sender, _amount);
    }

    function approveClaim(uint256 _policyId, uint256 _claimIndex) external {
        require(
            _claimIndex < policyClaims[_policyId].length,
            "Invalid claim index"
        );
        require(
            !policyClaims[_policyId][_claimIndex].approved,
            "Claim has already been approved"
        );

        for (
            uint256 i = 0;
            i < policyClaims[_policyId][_claimIndex].voters.length;
            i++
        ) {
            require(
                !(policyClaims[_policyId][_claimIndex].voters[i] == msg.sender),
                "You have already voted for this claim"
            );
        }

        policyClaims[_policyId][_claimIndex].voters.push(msg.sender);
        policyClaims[_policyId][_claimIndex].approvalCount++;

        if (
            policyClaims[_policyId][_claimIndex].approvalCount >
            (policyMap[_policyId].participants.length * 80) / 100
        ) {
            policyClaims[_policyId][_claimIndex].approved = true;
            emit ClaimApproved(
                _policyId,
                _claimIndex,
                msg.sender,
                policyClaims[_policyId][_claimIndex].claimant,
                policyClaims[_policyId][_claimIndex].amount
            );
            // payable(policyClaims[_policyId][_claimIndex].claimant).transfer(
            //     refundPerParticipant
            // );
            // emit PayoutProcessed(
            //     _policyId,
            //     policies[_policyId].participants[i],
            //     refundPerParticipant
            // );
        }
    }

    // function processPayout(
    //     uint256 _policyId
    // ) external onlyOwner(_policyId) payoutNotProcessed(_policyId) {
    //     require(
    //         block.timestamp >= policies[_policyId].duration,
    //         "Policy duration has not ended yet"
    //     );

    //     policies[_policyId].payoutProcessed = true;

    //     uint256 totalClaims;
    //     for (uint256 i = 0; i < policyClaims[_policyId].length; i++) {
    //         if (policyClaims[_policyId][i].approved) {
    //             totalClaims += policyClaims[_policyId][i].amount;
    //             emit PayoutProcessed(
    //                 _policyId,
    //                 policyClaims[_policyId][i].claimant,
    //                 policyClaims[_policyId][i].amount
    //             );
    //         }
    //     }

    //     uint256 refundPerParticipant = (policies[_policyId].totalPremium -
    //         totalClaims) / policies[_policyId].participants.length;

    //     for (uint256 i = 0; i < policies[_policyId].participants.length; i++) {
    //         if (!policyClaims[_policyId][i].approved) {
    //             payable(policyClaims[_policyId].participants[i]).transfer(
    //                 refundPerParticipant
    //             );
    //             emit PayoutProcessed(
    //                 _policyId,
    //                 policies[_policyId].participants[i],
    //                 refundPerParticipant
    //             );
    //         }
    //     }
    // }

    function searchPolicies(
        string memory _name,
        string memory _tag
    ) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](policies.length);
        uint256 count = 0;

        for (uint256 i = 0; i < policies.length; i++) {
            if (
                compareStrings(policies[i].name, _name) ||
                containsTag(policies[i].tags, _tag)
            ) {
                result[count] = i;
                count++;
            }
        }

        uint256[] memory finalResult = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalResult[i] = result[i];
        }

        return finalResult;
    }

    function compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function containsTag(
        string[] memory tags,
        string memory tag
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < tags.length; i++) {
            if (compareStrings(tags[i], tag)) {
                return true;
            }
        }
        return false;
    }
}
