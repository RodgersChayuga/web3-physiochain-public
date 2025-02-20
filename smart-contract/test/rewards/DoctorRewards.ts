import { expect } from "chai";
import { ethers } from "hardhat";
import { DoctorReward, PhysioToken, DataManagement } from "../../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("DoctorReward", function () {
    let doctorReward: DoctorReward;
    let physioToken: PhysioToken;
    let dataManagement: DataManagement;
    let owner: HardhatEthersSigner;
    let doctor: HardhatEthersSigner;
    let rewarder: HardhatEthersSigner;
    let dataManager: HardhatEthersSigner;

    beforeEach(async function () {
        [owner, doctor, rewarder, dataManager] = await ethers.getSigners();

        // Deploy PhysioToken
        const PhysioTokenFactory = await ethers.getContractFactory("PhysioToken");
        physioToken = await PhysioTokenFactory.deploy();

        // Deploy DataManagement
        const DataManagementFactory = await ethers.getContractFactory("DataManagement");
        dataManagement = await DataManagementFactory.deploy();

        // Deploy DoctorReward
        const DoctorRewardFactory = await ethers.getContractFactory("DoctorReward");
        doctorReward = await DoctorRewardFactory.deploy(
            await physioToken.getAddress(),
            await dataManagement.getAddress()
        );

        // Grant roles
        const MINTER_ROLE = await physioToken.MINTER_ROLE();
        await physioToken.grantRole(MINTER_ROLE, await doctorReward.getAddress());

        const DATA_MANAGER_ROLE = await dataManagement.DATA_MANAGER_ROLE();
        await dataManagement.grantRole(DATA_MANAGER_ROLE, dataManager.address);

        const REWARDER_ROLE = await doctorReward.REWARDER_ROLE();
        await doctorReward.grantRole(REWARDER_ROLE, rewarder.address);
    });

    describe("Rewards Calculation", function () {
        it("Should correctly reward doctor based on performance metrics", async function () {
            // Set performance metrics
            await dataManagement.connect(dataManager).updateProviderAdherenceRate(doctor.address, 80);  // 80%
            await dataManagement.connect(dataManager).updateProviderOutcomeScore(doctor.address, 90);   // 90 points
            await dataManagement.connect(dataManager).updateProviderPeerReviewScore(doctor.address, 75); // 75 points

            // Calculate expected performance score: (80 * 40 + 90 * 40 + 75 * 20) / 100 = 83
            // Expected reward: 83 * 10 = 830 tokens
            const expectedReward = ethers.parseEther("830");

            // Check initial balance
            const initialBalance = await physioToken.balanceOf(doctor.address);

            // Trigger reward
            await doctorReward.connect(rewarder).checkAndRewardDoctor(doctor.address);

            // Check final balance
            const finalBalance = await physioToken.balanceOf(doctor.address);
            expect(finalBalance - initialBalance).to.equal(expectedReward);
        });

        it("Should accumulate rewards in doctorRewards mapping", async function () {
            // Set performance metrics
            await dataManagement.connect(dataManager).updateProviderAdherenceRate(doctor.address, 100);  // 100%
            await dataManagement.connect(dataManager).updateProviderOutcomeScore(doctor.address, 100);   // 100 points
            await dataManagement.connect(dataManager).updateProviderPeerReviewScore(doctor.address, 100); // 100 points

            // Trigger reward
            await doctorReward.connect(rewarder).checkAndRewardDoctor(doctor.address);

            // Check accumulated rewards
            const accumulatedRewards = await doctorReward.doctorRewards(doctor.address);
            expect(accumulatedRewards).to.equal(ethers.parseEther("1000")); // (100 * 40 + 100 * 40 + 100 * 20) / 100 * 10
        });

        it("Should fail when non-rewarder tries to distribute rewards", async function () {
            await expect(
                doctorReward.connect(doctor).checkAndRewardDoctor(doctor.address)
            ).to.be.revertedWithCustomError(doctorReward, "AccessControlUnauthorizedAccount")
                .withArgs(doctor.address, await doctorReward.REWARDER_ROLE());
        });
    });

    describe("Performance Score Calculation", function () {
        it("Should handle zero metrics correctly", async function () {
            // Set all metrics to zero
            await dataManagement.connect(dataManager).updateProviderAdherenceRate(doctor.address, 0);
            await dataManagement.connect(dataManager).updateProviderOutcomeScore(doctor.address, 0);
            await dataManagement.connect(dataManager).updateProviderPeerReviewScore(doctor.address, 0);

            // Initial balance
            const initialBalance = await physioToken.balanceOf(doctor.address);

            // Trigger reward
            await doctorReward.connect(rewarder).checkAndRewardDoctor(doctor.address);

            // Check that no rewards were given
            const finalBalance = await physioToken.balanceOf(doctor.address);
            expect(finalBalance).to.equal(initialBalance);
        });

        it("Should handle maximum metrics correctly", async function () {
            // Set all metrics to maximum
            await dataManagement.connect(dataManager).updateProviderAdherenceRate(doctor.address, 100);
            await dataManagement.connect(dataManager).updateProviderOutcomeScore(doctor.address, 100);
            await dataManagement.connect(dataManager).updateProviderPeerReviewScore(doctor.address, 100);

            // Calculate expected reward: (100 * 40 + 100 * 40 + 100 * 20) / 100 * 10 = 1000 tokens
            const expectedReward = ethers.parseEther("1000");

            // Initial balance
            const initialBalance = await physioToken.balanceOf(doctor.address);

            // Trigger reward
            await doctorReward.connect(rewarder).checkAndRewardDoctor(doctor.address);

            // Check final balance
            const finalBalance = await physioToken.balanceOf(doctor.address);
            expect(finalBalance - initialBalance).to.equal(expectedReward);
        });
    });
});