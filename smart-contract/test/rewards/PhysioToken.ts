import { expect } from "chai";
import { ethers } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { PhysioToken } from "../../typechain-types";

describe("PhysioToken Contract", function () {
    let physioToken: PhysioToken;
    let owner: HardhatEthersSigner;
    let doctor: HardhatEthersSigner;
    let patient: HardhatEthersSigner;
    let institution: HardhatEthersSigner;
    let doctorRewardContract: HardhatEthersSigner;
    let patientRewardContract: HardhatEthersSigner;
    let paymentRedemptionContract: HardhatEthersSigner;

    const INITIAL_SUPPLY = ethers.parseEther("1000000000"); // 1 billion tokens

    beforeEach(async function () {
        // Deploy the PhysioToken contract
        const PhysioTokenFactory = await ethers.getContractFactory("PhysioToken");
        physioToken = (await PhysioTokenFactory.deploy()) as PhysioToken;

        // Get signers (accounts)
        [owner, doctor, patient, institution, doctorRewardContract, patientRewardContract, paymentRedemptionContract] =
            await ethers.getSigners();

        // Grant roles to respective contracts
        await physioToken.grantMinterRole(doctorRewardContract.address);
        await physioToken.grantMinterRole(patientRewardContract.address);
        await physioToken.grantBurnerRole(paymentRedemptionContract.address);
    });

    describe("Deployment", function () {
        it("Should assign the total supply of tokens to the owner", async function () {
            const ownerBalance = await physioToken.balanceOf(owner.address);
            expect(await physioToken.totalSupply()).to.equal(ownerBalance);
            expect(await physioToken.totalSupply()).to.equal(INITIAL_SUPPLY);
        });
    });

    describe("Minting Tokens", function () {
        it("Should allow DoctorReward Contract to mint tokens for a doctor", async function () {
            const amount = ethers.parseEther("100"); // 100 tokens
            await physioToken.connect(doctorRewardContract).mint(doctor.address, amount);

            const doctorBalance = await physioToken.balanceOf(doctor.address);
            expect(doctorBalance).to.equal(amount);
        });

        it("Should allow PatientReward Contract to mint tokens for a patient", async function () {
            const amount = ethers.parseEther("50"); // 50 tokens
            await physioToken.connect(patientRewardContract).mint(patient.address, amount);

            const patientBalance = await physioToken.balanceOf(patient.address);
            expect(patientBalance).to.equal(amount);
        });

        it("Should not allow unauthorized accounts to mint tokens", async function () {
            const amount = ethers.parseEther("100");
            await expect(
                physioToken.connect(institution).mint(institution.address, amount)
            ).to.be.revertedWithCustomError(physioToken, "AccessControlUnauthorizedAccount");
        });
    });

    describe("Burning Tokens", function () {
        it("Should allow Payment and Redemption Contract to burn tokens", async function () {
            const amount = ethers.parseEther("50");

            // Get initial supply
            const initialSupply = await physioToken.totalSupply();

            // Mint tokens to patient first
            await physioToken.connect(patientRewardContract).mint(patient.address, amount);

            // Get supply after minting
            const supplyAfterMint = await physioToken.totalSupply();
            expect(supplyAfterMint).to.equal(initialSupply + amount);

            // Burn tokens via Payment and Redemption Contract
            await physioToken.connect(paymentRedemptionContract).burn(patient.address, amount);

            // Get final supply after burning
            const finalSupply = await physioToken.totalSupply();
            expect(finalSupply).to.equal(supplyAfterMint - amount);
            expect(finalSupply).to.equal(initialSupply); // Should be back to initial supply

        });

        it("Should not allow unauthorized accounts to burn tokens", async function () {
            const amount = ethers.parseEther("50");
            await expect(
                physioToken.connect(doctor).burn(doctor.address, amount)
            ).to.be.revertedWithCustomError(physioToken, "AccessControlUnauthorizedAccount");
        });
    });

    it("Should allow owner to grant and revoke MINTER_ROLE", async function () {
        // Revoke MINTER_ROLE from DoctorReward Contract
        await physioToken.revokeMinterRole(doctorRewardContract.address);

        // Attempt to mint tokens should fail
        const amount = ethers.parseEther("100");
        await expect(
            physioToken.connect(doctorRewardContract).mint(doctor.address, amount)
        ).to.be.revertedWithCustomError(physioToken, "AccessControlUnauthorizedAccount");

        // Grant MINTER_ROLE back to DoctorReward Contract
        await physioToken.grantMinterRole(doctorRewardContract.address);

        // Mint tokens should now succeed
        await physioToken.connect(doctorRewardContract).mint(doctor.address, amount);
        const doctorBalance = await physioToken.balanceOf(doctor.address);
        expect(doctorBalance).to.equal(amount);
    });

    it("Should allow owner to grant and revoke BURNER_ROLE", async function () {
        // Revoke BURNER_ROLE from Payment and Redemption Contract
        await physioToken.revokeBurnerRole(paymentRedemptionContract.address);

        // Attempt to burn tokens should fail
        const amount = ethers.parseEther("50");
        await physioToken.connect(patientRewardContract).mint(patient.address, amount);
        await expect(
            physioToken.connect(paymentRedemptionContract).burn(patient.address, amount)
        ).to.be.revertedWithCustomError(physioToken, "AccessControlUnauthorizedAccount");

        // Grant BURNER_ROLE back to Payment and Redemption Contract
        await physioToken.grantBurnerRole(paymentRedemptionContract.address);

        // Burn tokens should now succeed
        await physioToken.connect(paymentRedemptionContract).burn(patient.address, amount);
        const patientBalance = await physioToken.balanceOf(patient.address);
        expect(patientBalance).to.equal(0);
    });

    describe("Transfers", function () {
        it("Should allow token transfers between accounts", async function () {
            const amount = ethers.parseEther("50");

            // Mint tokens to doctor
            await physioToken.connect(doctorRewardContract).mint(doctor.address, amount);

            // Transfer tokens from doctor to patient
            await physioToken.connect(doctor).transfer(patient.address, amount);

            const patientBalance = await physioToken.balanceOf(patient.address);
            expect(patientBalance).to.equal(amount);
        });

        it("Should fail if sender doesn't have enough tokens", async function () {
            const amount = ethers.parseEther("50");
            await expect(
                physioToken.connect(doctor).transfer(patient.address, amount)
            ).to.be.revertedWithCustomError(physioToken, "ERC20InsufficientBalance");
        });
    });
});