import { expect } from "chai";
import { ethers } from "hardhat";
import { TreatmentPlanNFT, DIDRegistry } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("TreatmentPlanNFT", function () {
    let treatmentPlanNFT: TreatmentPlanNFT;
    let didRegistry: DIDRegistry;
    let owner: HardhatEthersSigner;
    let doctor: HardhatEthersSigner;
    let patient: HardhatEthersSigner;
    const validDID = "did:example:123";
    const ipfsHash = "QmTest123";

    beforeEach(async function () {
        // Get signers
        [owner, doctor, patient] = await ethers.getSigners();

        // Deploy DIDRegistry
        const DIDRegistryFactory = await ethers.getContractFactory("DIDRegistry");
        didRegistry = await DIDRegistryFactory.deploy();

        // Deploy TreatmentPlanNFT
        const TreatmentPlanNFTFactory = await ethers.getContractFactory("TreatmentPlanNFT");
        treatmentPlanNFT = await TreatmentPlanNFTFactory.deploy(await didRegistry.getAddress());

        // Register doctor in DIDRegistry
        await didRegistry.registerUser(doctor.address, validDID, 2); // UserType.Doctor = 2
    });

    describe("Treatment Plan Creation", function () {
        it("Should allow verified doctor to create a treatment plan", async function () {
            await expect(treatmentPlanNFT.connect(doctor).createTreatmentPlan(ipfsHash))
                .to.emit(treatmentPlanNFT, "TreatmentPlanCreated")
                .withArgs(1, doctor.address, ipfsHash);

            expect(await treatmentPlanNFT.ownerOf(1)).to.equal(doctor.address);
        });

        it("Should not allow non-doctors to create treatment plans", async function () {
            await expect(
                treatmentPlanNFT.connect(patient).createTreatmentPlan(ipfsHash)
            ).to.be.revertedWith("Only verified doctors can create plans");
        });

        it("Should not allow inactive doctors to create treatment plans", async function () {
            await didRegistry.deactivateUser(doctor.address);
            await expect(
                treatmentPlanNFT.connect(doctor).createTreatmentPlan(ipfsHash)
            ).to.be.revertedWith("Doctor account must be active");
        });
    });

    describe("Treatment Plan Usage", function () {
        beforeEach(async function () {
            // Create a treatment plan first
            await treatmentPlanNFT.connect(doctor).createTreatmentPlan(ipfsHash);
        });

        it("Should allow viewing treatment plan details", async function () {
            const plan = await treatmentPlanNFT.getTreatmentPlan(1);
            expect(plan.ipfsHash).to.equal(ipfsHash);
            expect(plan.creatorDID).to.equal(validDID);
            expect(plan.isActive).to.be.true;
            expect(plan.usageCount).to.equal(0);
        });

        it("Should allow deactivating treatment plan by creator", async function () {
            await treatmentPlanNFT.connect(doctor).deactivateTreatmentPlan(1);
            const plan = await treatmentPlanNFT.getTreatmentPlan(1);
            expect(plan.isActive).to.be.false;
        });

        it("Should not allow non-creator to deactivate treatment plan", async function () {
            await expect(
                treatmentPlanNFT.connect(patient).deactivateTreatmentPlan(1)
            ).to.be.revertedWithCustomError(treatmentPlanNFT, "UnauthorizedCreator");
        });
    });
});