import { expect } from "chai";
import { ethers } from "hardhat";
import { DataManagement } from "../../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("DataManagement Contract", function () {
    let dataManagement: DataManagement;
    let owner: HardhatEthersSigner;
    let dataManager: HardhatEthersSigner;
    let doctor: HardhatEthersSigner;
    let patient: HardhatEthersSigner;
    let institution: HardhatEthersSigner;

    beforeEach(async function () {
        [owner, dataManager, doctor, patient, institution] = await ethers.getSigners();

        const DataManagementFactory = await ethers.getContractFactory("DataManagement");
        dataManagement = await DataManagementFactory.deploy();

        const DATA_MANAGER_ROLE = await dataManagement.DATA_MANAGER_ROLE();
        await dataManagement.grantRole(DATA_MANAGER_ROLE, dataManager.address);
    });

    describe("Doctor Metrics", function () {
        it("Should update and retrieve a doctor's adherence rate", async function () {
            await dataManagement.connect(dataManager).updateProviderAdherenceRate(doctor.address, 90);
            expect(await dataManagement.getDoctorAdherence(doctor.address)).to.equal(90);
        });

        it("Should update and retrieve a doctor's outcome score", async function () {
            await dataManagement.connect(dataManager).updateProviderOutcomeScore(doctor.address, 85);
            expect(await dataManagement.getDoctorOutcome(doctor.address)).to.equal(85);
        });

        it("Should update and retrieve a doctor's peer review score", async function () {
            await dataManagement.connect(dataManager).updateProviderPeerReviewScore(doctor.address, 95);
            expect(await dataManagement.getDoctorPeerReview(doctor.address)).to.equal(95);
        });
    });

    describe("Patient Metrics", function () {
        it("Should update and retrieve a patient's milestone progress", async function () {
            await dataManagement.connect(dataManager).updatePatientMilestoneCount(patient.address, 5);
            expect(await dataManagement.getPatientMilestones(patient.address)).to.equal(5);
        });

        it("Should update and retrieve a patient's adherence rate", async function () {
            await dataManagement.connect(dataManager).updatePatientAdherenceRate(patient.address, 80);
            expect(await dataManagement.getPatientAdherence(patient.address)).to.equal(80);
        });
    });

    describe("Institution Metrics", function () {
        it("Should update and retrieve an institution's performance score", async function () {
            await dataManagement.connect(dataManager).updateInstitutionPerformanceScore(institution.address, 88);
            expect(await dataManagement.getInstitutionPerformanceScore(institution.address)).to.equal(88);
        });
    });

    describe("Access Control", function () {
        it("Should fail if a non-data manager attempts to update metrics", async function () {
            await expect(
                dataManagement.connect(doctor).updateProviderAdherenceRate(doctor.address, 90)
            ).to.be.revertedWithCustomError(dataManagement, "AccessControlUnauthorizedAccount")
                .withArgs(doctor.address, await dataManagement.DATA_MANAGER_ROLE());
        });
    });
});