import { expect } from "chai";
import { ethers } from "hardhat";
import { DataManagement } from "../../typechain-types";

describe("DataManagement Contract", function () {
    let dataManagement: DataManagement;
    let owner: any;
    let doctor: any;
    let patient: any;
    let institution: any;

    beforeEach(async function () {
        const DataManagementFactory = await ethers.getContractFactory("DataManagement");
        [owner, doctor, patient, institution] = await ethers.getSigners();
        dataManagement = await DataManagementFactory.deploy();

        // Grant DATA_MANAGER_ROLE to owner
        await dataManagement.grantRole(await dataManagement.DATA_MANAGER_ROLE(), owner.address);
    });

    describe("Doctor Metrics", function () {
        it("Should update and retrieve a doctor's adherence rate", async function () {
            const adherenceRate = 80; // 80%
            await dataManagement.connect(owner).updateDoctorAdherence(doctor.address, adherenceRate);
            expect(await dataManagement.getDoctorAdherence(doctor.address)).to.equal(adherenceRate);
        });

        it("Should update and retrieve a doctor's outcome score", async function () {
            const outcomeScore = 90; // 90 points
            await dataManagement.connect(owner).updateDoctorOutcome(doctor.address, outcomeScore);
            expect(await dataManagement.getDoctorOutcome(doctor.address)).to.equal(outcomeScore);
        });

        it("Should update and retrieve a doctor's peer review score", async function () {
            const peerReviewScore = 75; // 75 points
            await dataManagement.connect(owner).updateDoctorPeerReview(doctor.address, peerReviewScore);
            expect(await dataManagement.getDoctorPeerReview(doctor.address)).to.equal(peerReviewScore);
        });
    });

    describe("Patient Metrics", function () {
        it("Should update and retrieve a patient's milestone progress", async function () {
            const milestones = 5; // 5 milestones
            await dataManagement.connect(owner).updatePatientMilestones(patient.address, milestones);
            expect(await dataManagement.getPatientMilestones(patient.address)).to.equal(milestones);
        });

        it("Should update and retrieve a patient's adherence rate", async function () {
            const adherenceRate = 95; // 95%
            await dataManagement.connect(owner).updatePatientAdherence(patient.address, adherenceRate);
            expect(await dataManagement.getPatientAdherence(patient.address)).to.equal(adherenceRate);
        });
    });

    describe("Institution Metrics", function () {
        it("Should update and retrieve an institution's performance score", async function () {
            const score = 85; // 85 points
            await dataManagement.connect(owner).updateInstitutionScore(institution.address, score);
            expect(await dataManagement.getInstitutionScore(institution.address)).to.equal(score);
        });
    });

    describe("Access Control", function () {
        it("Should fail if a non-data manager attempts to update metrics", async function () {
            const DATA_MANAGER_ROLE = await dataManagement.DATA_MANAGER_ROLE();

            // Test multiple functions to ensure access control is working
            await expect(
                dataManagement.connect(doctor).updateDoctorAdherence(doctor.address, 80)
            ).to.be.revertedWithCustomError(dataManagement, "AccessControlUnauthorizedAccount")
                .withArgs(doctor.address, DATA_MANAGER_ROLE);

            await expect(
                dataManagement.connect(doctor).updatePatientMilestones(patient.address, 5)
            ).to.be.revertedWithCustomError(dataManagement, "AccessControlUnauthorizedAccount")
                .withArgs(doctor.address, DATA_MANAGER_ROLE);

            await expect(
                dataManagement.connect(doctor).updateInstitutionScore(institution.address, 85)
            ).to.be.revertedWithCustomError(dataManagement, "AccessControlUnauthorizedAccount")
                .withArgs(doctor.address, DATA_MANAGER_ROLE);
        });
    });
});