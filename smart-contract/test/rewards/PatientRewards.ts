import { expect } from "chai";
import { ethers } from "hardhat";
import { PatientRewards } from "../../typechain-types";
import { DataManagement } from "../../typechain-types";
import { PhysioToken } from "../../typechain-types";

describe("PatientRewards Contract", function () {
    let patientRewards: PatientRewards;
    let dataManagement: DataManagement;
    let physioToken: PhysioToken;
    let owner: any;
    let patient: any;

    beforeEach(async function () {
        [owner, patient] = await ethers.getSigners();

        // Deploy PhysioToken contract first
        const PhysioTokenFactory = await ethers.getContractFactory("PhysioToken");
        physioToken = await PhysioTokenFactory.deploy();

        // Grant DEFAULT_ADMIN_ROLE to owner if needed
        const DEFAULT_ADMIN_ROLE = await physioToken.DEFAULT_ADMIN_ROLE();
        if (!await physioToken.hasRole(DEFAULT_ADMIN_ROLE, owner.address)) {
            await physioToken.connect(owner).grantRole(DEFAULT_ADMIN_ROLE, owner.address);
        }

        // Deploy DataManagement contract
        const DataManagementFactory = await ethers.getContractFactory("DataManagement");
        dataManagement = await DataManagementFactory.deploy();

        // Deploy PatientRewards contract
        const PatientRewardsFactory = await ethers.getContractFactory("PatientRewards");
        patientRewards = await PatientRewardsFactory.deploy(
            await physioToken.getAddress(),
            await dataManagement.getAddress()
        );

        // Grant MINTER_ROLE to PatientRewards contract from owner
        const MINTER_ROLE = await physioToken.MINTER_ROLE();
        await physioToken.connect(owner).grantRole(MINTER_ROLE, await patientRewards.getAddress());

        const DATA_MANAGER_ROLE = await dataManagement.DATA_MANAGER_ROLE();
        await dataManagement.connect(owner).grantRole(DATA_MANAGER_ROLE, owner.address);
    });

    it("Should reward a patient for completing milestones", async function () {
        // Update patient's milestones in DataManagement
        const sessionsCompleted = 20; // 2 milestones
        await dataManagement.connect(owner).updatePatientMilestones(patient.address, sessionsCompleted);

        // Check and reward the patient
        await patientRewards.checkAndRewardPatient(patient.address);

        // Verify the reward amount
        const expectedReward = ethers.parseEther("210"); // (sessionsCompleted / 10) * 100 + 10
        const patientBalance = await physioToken.balanceOf(patient.address);
        expect(patientBalance).to.equal(expectedReward);
    });

    it("Should reward a patient for maintaining a streak", async function () {
        // Update patient's adherence rate in DataManagement
        const adherenceRate = 100; // Perfect adherence
        await dataManagement.connect(owner).updatePatientAdherence(patient.address, adherenceRate);

        // Check and reward the patient
        await patientRewards.checkAndRewardPatient(patient.address);

        // Verify the reward amount
        const expectedReward = ethers.parseEther("110"); // Streak reward + session reward
        const patientBalance = await physioToken.balanceOf(patient.address);
        expect(patientBalance).to.equal(expectedReward);
    });
});