import { expect } from 'chai';
import { ethers } from "hardhat"
import { InsurancePolicy, InsurancePolicy__factory } from "../typechain-types";
import { Contract } from "ethers";

describe('InsurancePolicy', function () {
    let insurancePolicy: InsurancePolicy;
    let myTestERC20: Contract;

    beforeEach(async function () {
        const [owner, otherAccount] = await ethers.getSigners();
        const myTestERC20Factory = await ethers.getContractFactory("MyTestERC20");
        myTestERC20 = await myTestERC20Factory.deploy();
        await myTestERC20.waitForDeployment();
        await myTestERC20.mint(owner.address, 10000000);
        const insurancePolicyFactory = await ethers.getContractFactory('InsurancePolicy')

        insurancePolicy = await insurancePolicyFactory.deploy();
        await insurancePolicy.waitForDeployment();
    });

    it('should create a policy', async function () {
        const createdPolicy = await insurancePolicy.createPolicy('Policy 1', 24, ['tag1', 'tag2'], myTestERC20.getAddress(), 10);
        console.info('dddddd',createdPolicy)
        const policy = await insurancePolicy.policies(0);
        console.info('dddddd',policy)
        expect(policy.owner).to.equal(await(await ethers.provider.getSigner(0)).getAddress(), 'Policy owner should be the first account');
        expect(policy.name).to.equal('Policy 1', 'Policy name should match');
        // expect(policy.tags.length).to.equal(2, 'Policy should have two tags');
    });

    it('should pay premium and submit claim', async function () {
        await insurancePolicy.createPolicy('Policy 2', 3600, ['tag3', 'tag4']);
        await insurancePolicy.connect(await ethers.getSigner(1)).payPremium(0, { value: ethers.utils.parseEther('1') });
        await insurancePolicy.connect(await ethers.getSigner(1)).submitClaim(0, 100);

        const policy = await insurancePolicy.policies(0);
        expect(policy.participants.length).to.equal(1, 'Policy should have one participant');
        expect(policy.totalPremium).to.equal(ethers.utils.parseEther('1'), 'Total premium should match');
        expect(policy.claims.length).to.equal(1, 'Policy should have one claim');
        expect(policy.claims[0].claimant).to.equal((await ethers.provider.getSigner(1)).getAddress(), 'Claimant should be the second account');
    });

    it('should approve claim and process payout', async function () {
        await insurancePolicy.createPolicy('Policy 3', 3600, ['tag5', 'tag6']);
        await insurancePolicy.connect(await ethers.getSigner(1)).payPremium(0, { value: ethers.utils.parseEther('1') });
        await insurancePolicy.connect(await ethers.getSigner(1)).submitClaim(0, 100);
        await insurancePolicy.approveClaim(0, 0);
        await insurancePolicy.processPayout(0);

        const policy = await insurancePolicy.policies(0);
        expect(policy.payoutProcessed).to.equal(true, 'Payout should be processed');
        // Add more expectations based on your contract's logic
    });
});
