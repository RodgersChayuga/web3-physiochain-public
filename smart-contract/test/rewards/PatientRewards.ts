import { expect } from "chai";
import { ethers } from "hardhat";
import { PatientRewards, PhysioToken, DataManagement } from "../../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("PatientRewards", function () {
    let patientRewards: PatientRewards;
    let physioToken: PhysioToken;
    let dataManagement: DataManagement;
    let owner: HardhatEthersSigner;
    let patient: HardhatEthersSigner;
    let dataManager: HardhatEthersSigner;

    beforeEach(async function () {
        [owner, patient, dataManager] = await ethers.getSigners();

        // Deploy PhysioToken
        const PhysioTokenFactory = await ethers.getContractFactory("PhysioToken");
        physioToken = await PhysioTokenFactory.deploy();

        // Deploy DataManagement
        const DataManagementFactory = await ethers.getContractFactory("DataManagement");
        dataManagement = await DataManagementFactory.deploy();

        // Deploy PatientRewards
        const PatientRewardsFactory = await ethers.getContractFactory("PatientRewards");
        patientRewards = await PatientRewardsFactory.deploy(
            await physioToken.getAddress(),
            await dataManagement.getAddress()
        );

        // Grant roles
        const MINTER_ROLE = await physioToken.MINTER_ROLE();
        await physioToken.grantRole(MINTER_ROLE, await patientRewards.getAddress());

        const DATA_MANAGER_ROLE = await dataManagement.DATA_MANAGER_ROLE();
        await dataManagement.grantRole(DATA_MANAGER_ROLE, dataManager.address);
    });

    describe("Rewards", function () {
        it("Should reward patient for completing sessions", async function () {
            // Update patient milestones
            await dataManagement.connect(dataManager).updatePatientMilestoneCount(patient.address, 1);

            // Check initial balance
            const initialBalance = await physioToken.balanceOf(patient.address);

            // Trigger reward
            await patientRewards.checkAndRewardPatient(patient.address);

            // Check final balance
            const finalBalance = await physioToken.balanceOf(patient.address);
            expect(finalBalance - initialBalance).to.equal(ethers.parseEther("10")); // REWARD_PER_SESSION
        });

        it("Should reward patient for achieving milestone", async function () {
            // Update patient milestones to reach a milestone (10 sessions)
            await dataManagement.connect(dataManager).updatePatientMilestoneCount(patient.address, 10);

            // Check initial balance
            const initialBalance = await physioToken.balanceOf(patient.address);

            // Trigger reward
            await patientRewards.checkAndRewardPatient(patient.address);

            // Check final balance (milestone reward + session reward)
            const finalBalance = await physioToken.balanceOf(patient.address);
            expect(finalBalance - initialBalance).to.equal(
                ethers.parseEther("110") // MILESTONE_REWARD (100) + REWARD_PER_SESSION (10)
            );
        });

        it("Should reward patient for maintaining streak", async function () {
            // Update patient adherence to 100%
            await dataManagement.connect(dataManager).updatePatientAdherenceRate(patient.address, 100);

            // Trigger reward
            await patientRewards.checkAndRewardPatient(patient.address);

            // Move time forward past streak threshold
            await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // 7 days
            await ethers.provider.send("evm_mine", []);

            // Check initial balance
            const initialBalance = await physioToken.balanceOf(patient.address);

            // Trigger reward again
            await patientRewards.checkAndRewardPatient(patient.address);

            // Check final balance (streak reward + session reward)
            const finalBalance = await physioToken.balanceOf(patient.address);
            expect(finalBalance - initialBalance).to.equal(
                ethers.parseEther("110") // MILESTONE_REWARD (100) + REWARD_PER_SESSION (10)
            );
        });

        it("Should allow admin to update reward thresholds", async function () {
            const newSessionsPerMilestone = 15;
            const newStreakThreshold = 10;
            const newRewardPerSession = ethers.parseEther("20");
            const newMilestoneReward = ethers.parseEther("200");

            await patientRewards.updateRewardThresholds(
                newSessionsPerMilestone,
                newStreakThreshold,
                newRewardPerSession,
                newMilestoneReward
            );

            expect(await patientRewards.SESSIONS_PER_MILESTONE()).to.equal(newSessionsPerMilestone);
            expect(await patientRewards.STREAK_THRESHOLD()).to.equal(newStreakThreshold);
            expect(await patientRewards.REWARD_PER_SESSION()).to.equal(newRewardPerSession);
            expect(await patientRewards.MILESTONE_REWARD()).to.equal(newMilestoneReward);
        });
    });
});