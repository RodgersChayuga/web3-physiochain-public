import { expect } from "chai";
import { ethers } from "hardhat";
import { DoctorPayment, PhysioToken } from "../../typechain-types";

describe("DoctorPayment Contract", function () {
    let payment: DoctorPayment;
    let physioToken: PhysioToken;
    let owner: any;
    let doctor: any;
    let patient: any;
    let paymentManager: any;

    const INITIAL_SUPPLY = ethers.parseEther("1000000"); // 1 million tokens
    const SERVICE_FEE_PERCENTAGE = 5; // 0.05%
    const FEE_PER_SESSION = ethers.parseEther("500"); // 500 tokens per session

    beforeEach(async function () {
        // Get signers
        [owner, doctor, patient, paymentManager] = await ethers.getSigners();

        // Deploy PhysioToken contract
        const PhysioTokenFactory = await ethers.getContractFactory("PhysioToken");
        physioToken = (await PhysioTokenFactory.deploy()) as PhysioToken;

        // Get MINTER_ROLE from PhysioToken
        const MINTER_ROLE = await physioToken.MINTER_ROLE();

        // Grant MINTER_ROLE to owner
        await physioToken.grantRole(MINTER_ROLE, owner.address);

        // Deploy DoctorPayment contract
        const DoctorPaymentFactory = await ethers.getContractFactory("DoctorPayment");
        payment = (await DoctorPaymentFactory.deploy(
            await physioToken.getAddress(),
            owner.address,
            SERVICE_FEE_PERCENTAGE
        )) as DoctorPayment;

        // Grant PAYMENT_MANAGER_ROLE to paymentManager
        const PAYMENT_MANAGER_ROLE = await payment.PAYMENT_MANAGER_ROLE();
        await payment.grantRole(PAYMENT_MANAGER_ROLE, paymentManager.address);

        // Mint tokens to patient for testing payments
        await physioToken.mint(patient.address, INITIAL_SUPPLY);
    });

    describe("Negotiation and Approval", function () {
        it("Should allow a doctor to propose a fee and a patient to approve it", async function () {
            // Doctor proposes a fee
            await payment.connect(doctor).proposeAgreement(patient.address, FEE_PER_SESSION);

            // Get the agreement ID (should be 1 as it's the first agreement)
            const agreementId = 1;

            // Patient approves the agreement
            await payment.connect(patient).approveAgreement(agreementId);

            // Verify the agreement is active
            const agreement = await payment.agreements(agreementId);
            expect(agreement.isActive).to.be.true;
            expect(agreement.feePerSession).to.equal(FEE_PER_SESSION);
            expect(agreement.doctor).to.equal(doctor.address);
            expect(agreement.patient).to.equal(patient.address);
        });
    });

    describe("Session Completion", function () {
        it("Should process payment correctly after session completion", async function () {
            // Doctor proposes a fee
            await payment.connect(doctor).proposeAgreement(patient.address, FEE_PER_SESSION);
            const agreementId = 1;

            // Patient approves the agreement
            await payment.connect(patient).approveAgreement(agreementId);

            // Approve token transfer for the payment contract
            await physioToken.connect(patient).approve(await payment.getAddress(), FEE_PER_SESSION);

            // Get initial balances
            const initialPatientBalance = await physioToken.balanceOf(patient.address);
            const initialDoctorBalance = await physioToken.balanceOf(doctor.address);
            const initialOwnerBalance = await physioToken.balanceOf(owner.address);

            // Confirm session completion
            await payment.connect(patient).confirmSessionCompletion(agreementId);

            // Calculate expected amounts
            const serviceFee = (FEE_PER_SESSION * BigInt(SERVICE_FEE_PERCENTAGE)) / 10000n;
            const doctorPayment = FEE_PER_SESSION - serviceFee;

            // Verify balances after payment
            expect(await physioToken.balanceOf(patient.address)).to.equal(initialPatientBalance - FEE_PER_SESSION);
            expect(await physioToken.balanceOf(doctor.address)).to.equal(initialDoctorBalance + doctorPayment);
            expect(await physioToken.balanceOf(owner.address)).to.equal(initialOwnerBalance + serviceFee);
        });

        it("Should fail if the patient has insufficient balance", async function () {
            // Doctor proposes a fee
            await payment.connect(doctor).proposeAgreement(patient.address, FEE_PER_SESSION);
            const agreementId = 1;

            // Patient approves the agreement
            await payment.connect(patient).approveAgreement(agreementId);

            // Approve token transfer for the payment contract
            await physioToken.connect(patient).approve(await payment.getAddress(), FEE_PER_SESSION);

            // Reduce patient's balance below the fee
            await physioToken.connect(patient).transfer(owner.address, INITIAL_SUPPLY);

            // Attempt to confirm session completion
            await expect(
                payment.connect(patient).confirmSessionCompletion(agreementId)
            ).to.be.revertedWith("Insufficient balance");
        });
    });

    describe("Renegotiation", function () {
        it("Should allow renegotiation of the fee per session", async function () {
            // Doctor proposes a fee
            await payment.connect(doctor).proposeAgreement(patient.address, FEE_PER_SESSION);
            const agreementId = 1;

            // Patient approves the agreement
            await payment.connect(patient).approveAgreement(agreementId);

            // Renegotiate the fee
            const newFeePerSession = ethers.parseEther("600");
            await payment.connect(doctor).renegotiateFee(agreementId, newFeePerSession);

            // Verify the new fee is applied
            const agreement = await payment.agreements(agreementId);
            expect(agreement.feePerSession).to.equal(newFeePerSession);
        });

        it("Should fail if renegotiation is attempted by an unauthorized account", async function () {
            // Doctor proposes a fee
            await payment.connect(doctor).proposeAgreement(patient.address, FEE_PER_SESSION);
            const agreementId = 1;

            // Patient approves the agreement
            await payment.connect(patient).approveAgreement(agreementId);

            // Attempt renegotiation by an unauthorized account
            const newFeePerSession = ethers.parseEther("600");
            await expect(
                payment.connect(owner).renegotiateFee(agreementId, newFeePerSession)
            ).to.be.revertedWith("Only the doctor or patient can renegotiate");
        });
    });

    describe("Service Fee Management", function () {
        it("Should allow payment manager to update service fee percentage", async function () {
            const newFeePercentage = 10; // 0.1%
            await payment.connect(paymentManager).updateServiceFeePercentage(newFeePercentage);
            expect(await payment.serviceFeePercentage()).to.equal(newFeePercentage);
        });

        it("Should not allow unauthorized accounts to update service fee percentage", async function () {
            const newFeePercentage = 10;
            await expect(
                payment.connect(doctor).updateServiceFeePercentage(newFeePercentage)
            ).to.be.reverted; // Will revert with AccessControl error
        });
    });
});