import { expect } from 'chai';
import { ethers } from "hardhat"
import { InsurancePolicy, InsurancePolicy__factory, MyTestERC20 } from "../typechain-types";
import { Contract } from "ethers";

describe('InsurancePolicy', function () {
    let insurancePolicy: InsurancePolicy;
    let myTestERC20: MyTestERC20;
    let ownerAddress: string;
    let otherAccountAddress: string;

    beforeEach(async function () {
        const [owner, otherAccount] = await ethers.getSigners();
        ownerAddress = await owner.getAddress()
        otherAccountAddress = await otherAccount.getAddress()
        const myTestERC20Factory = await ethers.getContractFactory("MyTestERC20");
        myTestERC20 = await myTestERC20Factory.deploy();
        await myTestERC20.waitForDeployment();
        await myTestERC20.mint(owner.address, 1000000000000);
        await myTestERC20.transfer(otherAccountAddress, 100000);
        const insurancePolicyFactory = await ethers.getContractFactory('InsurancePolicy')

        insurancePolicy = await insurancePolicyFactory.deploy();
        await insurancePolicy.waitForDeployment();
        myTestERC20.connect(owner).approve(insurancePolicy.getAddress(), 1000000000000000);
    });

    it('should create a policy', async function () {
        await insurancePolicy.createPolicy('Policy 1', 24, ['tag1', 'tag2'], myTestERC20.getAddress(), 10);
        const policy = await insurancePolicy.policies(0);
        expect(policy.remainingPayout).to.equal(10);
        expect(policy.owner).to.equal(await(await ethers.provider.getSigner(0)).getAddress(), 'Policy owner should be the first account');
        expect(policy.name).to.equal('Policy 1', 'Policy name should match');

        const tags1 = (await insurancePolicy.policyTags(policy.id))[0];
        expect(tags1).to.equal('tag1', 'Policy should have tag1');

        const tags2 = (await insurancePolicy.policyTags(policy.id))[1];
        expect(tags2).to.equal('tag2', 'Policy should have tag1');


        const participants = (await insurancePolicy.policyParticipants(policy.id))[0]
        expect(participants).to.equal(ownerAddress, 'Policy should have owner set as first participant');
    });

    it('should pay premium and submit claim', async function () {
        await insurancePolicy.createPolicy('Policy 1', 24, ['tag1', 'tag2'], myTestERC20.getAddress(), 10000);
        let policy = await insurancePolicy.policies(0);
        expect(policy.remainingPayout).to.equal(10000);
        myTestERC20.connect((await ethers.getSigners())[1]).approve(insurancePolicy.getAddress(), 1000000000000000);

        await insurancePolicy.connect(await ethers.getSigner(otherAccountAddress)).payPremium(policy.id, myTestERC20.getAddress());
        policy = await insurancePolicy.policies(0);
        expect(policy.remainingPayout).to.equal(100000);

        expect(policy.owner).to.equal(await(await ethers.provider.getSigner(0)).getAddress(), 'Policy owner should be the first account');
        await insurancePolicy.connect(await ethers.getSigner(otherAccountAddress)).submitClaim(policy.id, 100);
        // await insurancePolicy.connect(await ethers.getSigner(otherAccount)).payPremium(0, { value: ethers.utils.parseEther('1') });

        // const policy = await insurancePolicy.policies(0);
        // console.info(policy)
        // expect(policy.participants.length).to.equal(1, 'Policy should have one participant');
        // expect(policy.totalPremium).to.equal(ethers.utils.parseEther('1'), 'Total premium should match');
        // expect(policy.claims.length).to.equal(1, 'Policy should have one claim');
        // expect(policy.claims[0].claimant).to.equal((await ethers.provider.getSigner(1)).getAddress(), 'Claimant should be the second account');
    });

    // it('should approve claim and process payout', async function () {
    //     await insurancePolicy.createPolicy('Policy 3', 3600, ['tag5', 'tag6']);
    //     await insurancePolicy.connect(await ethers.getSigner(1)).payPremium(0, { value: ethers.utils.parseEther('1') });
    //     await insurancePolicy.connect(await ethers.getSigner(1)).submitClaim(0, 100);
    //     await insurancePolicy.approveClaim(0, 0);
    //     await insurancePolicy.processPayout(0);

    //     const policy = await insurancePolicy.policies(0);
    //     expect(policy.payoutProcessed).to.equal(true, 'Payout should be processed');
    //     // Add more expectations based on your contract's logic
    // });
});
