import { expect } from "chai";
import { ethers } from "hardhat";
import { DoctorReward, DataManagement, PhysioToken } from "../../typechain-types";

describe("DoctorReward Contract", function () {
    let doctorReward: DoctorReward;
    let dataManagement: DataManagement;
    let physioToken: PhysioToken;
    let owner: any;
    let doctor: any;
    let rewarder: any;

    beforeEach(async function () {
        // Get signers
        [owner, doctor, rewarder] = await ethers.getSigners();

        // Deploy PhysioToken contract
        const PhysioTokenFactory = await ethers.getContractFactory("PhysioToken");
        physioToken = await PhysioTokenFactory.deploy();

        // Deploy DataManagement contract
        const DataManagementFactory = await ethers.getContractFactory("DataManagement");
        dataManagement = await DataManagementFactory.deploy();

        // Deploy DoctorReward contract
        const DoctorRewardFactory = await ethers.getContractFactory("DoctorReward");
        doctorReward = await DoctorRewardFactory.deploy(
            await physioToken.getAddress(),
            await dataManagement.getAddress()
        );

        // Grant necessary roles
        const MINTER_ROLE = await physioToken.MINTER_ROLE();
        const DATA_MANAGER_ROLE = await dataManagement.DATA_MANAGER_ROLE();
        const REWARDER_ROLE = await doctorReward.REWARDER_ROLE();

        // Grant roles to appropriate addresses
        await physioToken.connect(owner).grantRole(MINTER_ROLE, await doctorReward.getAddress());
        await dataManagement.connect(owner).grantRole(DATA_MANAGER_ROLE, owner.address);
        await doctorReward.connect(owner).grantRole(REWARDER_ROLE, rewarder.address);

        // Optional: Log contract addresses for debugging
        console.log("PhysioToken Address:", await physioToken.getAddress());
        console.log("DataManagement Address:", await dataManagement.getAddress());
        console.log("DoctorReward Address:", await doctorReward.getAddress());
    });

    it("Should correctly set up initial roles", async function () {
        const MINTER_ROLE = await physioToken.MINTER_ROLE();
        const hasRole = await physioToken.hasRole(MINTER_ROLE, await doctorReward.getAddress());
        expect(hasRole).to.be.true;
    });

    it("Should reward a doctor based on their performance metrics", async function () {
        // Update doctor's performance metrics in DataManagement
        const adherenceRate = 80; // 80%
        const outcomeScore = 90; // 90 points
        const peerReviewScore = 75; // 75 points

        // Update metrics using owner (who has DATA_MANAGER_ROLE)
        await dataManagement.connect(owner).updateDoctorAdherence(doctor.address, adherenceRate);
        await dataManagement.connect(owner).updateDoctorOutcome(doctor.address, outcomeScore);
        await dataManagement.connect(owner).updateDoctorPeerReview(doctor.address, peerReviewScore);

        // Get initial balance
        const initialBalance = await physioToken.balanceOf(doctor.address);

        // Reward the doctor using rewarder account
        await doctorReward.connect(rewarder).rewardDoctor(doctor.address);

        // Calculate expected reward
        const performanceScore = ((adherenceRate * 40) + (outcomeScore * 40) + (peerReviewScore * 20)) / 100;
        const expectedReward = performanceScore * 10; // 10 tokens per score point

        // Get final balance
        const finalBalance = await physioToken.balanceOf(doctor.address);

        // Verify the reward amount
        expect(finalBalance - initialBalance).to.equal(expectedReward);
    });

    it("Should fail when non-rewarder tries to reward doctor", async function () {
        // Attempt to reward doctor as a non-rewarder
        await expect(
            doctorReward.connect(doctor).rewardDoctor(doctor.address)
        ).to.be.revertedWithCustomError(doctorReward, "AccessControlUnauthorizedAccount")
            .withArgs(doctor.address, await doctorReward.REWARDER_ROLE());
    });
});