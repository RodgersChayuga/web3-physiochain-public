import { expect } from "chai";
import { ethers } from "hardhat";
import { DIDRegistry } from "../typechain-types"; // Adjust import based on your project setup
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("DIDRegistry", function () {
  let didRegistry: DIDRegistry;
  let owner: HardhatEthersSigner;
  let doctor: HardhatEthersSigner;
  let patient: HardhatEthersSigner;

  const validDID = "did:example:1234";
  const validLicenseNumber = "DOC123456789";
  const invalidLicenseNumber = "INVALID123";
  const nationalIDHash = "QmNationalIDHash123";
  const passportPhotoHash = "QmPassportPhotoHash123";

  beforeEach(async function () {
    [owner, doctor, patient] = await ethers.getSigners();

    // Deploy DIDRegistry without PhysioToken dependency
    const DIDRegistryFactory = await ethers.getContractFactory("DIDRegistry");
    didRegistry = await DIDRegistryFactory.deploy();
  });

  describe("Deployment", function () {
    it("Should deploy the DIDRegistry contract successfully", async function () {
      const address = await didRegistry.getAddress();
      expect(address).to.properAddress;
    });

    it("Should initialize the ADMIN_ROLE correctly", async function () {
      const adminRole = ethers.keccak256(ethers.toUtf8Bytes("ADMIN_ROLE"));
      expect(await didRegistry.hasRole(adminRole, owner.address)).to.be.true;
    });
  });

  describe("User Registration", function () {
    it("Should allow admin to register a new user", async function () {
      await didRegistry.connect(owner).registerUser(doctor.address, validDID, 2); // UserType.Doctor = 2
      const [did, userType, isActive] = await didRegistry.getUserInfo(doctor.address);
      expect(did).to.equal(validDID);
      expect(userType).to.equal(2); // Doctor
      expect(isActive).to.be.true;
    });

    it("Should prevent registering the same DID twice", async function () {
      await didRegistry.connect(owner).registerUser(doctor.address, validDID, 2);
      await expect(
        didRegistry.connect(owner).registerUser(doctor.address, validDID, 2)
      ).to.be.revertedWith("User already registered");
    });

    it("Should prevent registering the same user twice", async function () {
      await didRegistry.connect(owner).registerUser(doctor.address, validDID, 2);
      await expect(
        didRegistry.connect(owner).registerUser(doctor.address, "did:example:5678", 2)
      ).to.be.revertedWith("User already registered");
    });
  });

  describe("Doctor Self-Registration", function () {
    it("Should allow doctors to submit registration requests", async function () {
      await didRegistry.connect(doctor).requestDoctorRegistration(
        validDID,
        validLicenseNumber,
        nationalIDHash,
        passportPhotoHash
      );
      const request = await didRegistry.doctorRequests(doctor.address);
      expect(request.did).to.equal(validDID);
      expect(request.licenseNumber).to.equal(validLicenseNumber);
      expect(request.isVerified).to.be.false;
    });

    it("Should prevent duplicate license numbers", async function () {
      await didRegistry.connect(doctor).requestDoctorRegistration(
        validDID,
        validLicenseNumber,
        nationalIDHash,
        passportPhotoHash
      );
      await expect(
        didRegistry.connect(doctor).requestDoctorRegistration(
          "did:example:5678",
          validLicenseNumber,
          nationalIDHash,
          passportPhotoHash
        )
      ).to.be.revertedWith("License number already in use");
    });

    it("Should allow admins to verify doctor registration requests", async function () {
      await didRegistry.connect(doctor).requestDoctorRegistration(
        validDID,
        validLicenseNumber,
        nationalIDHash,
        passportPhotoHash
      );
      await didRegistry.connect(owner).verifyDoctor(doctor.address, true);
      const [did, userType, isActive] = await didRegistry.getUserInfo(doctor.address);
      expect(did).to.equal(validDID);
      expect(userType).to.equal(2); // Doctor
      expect(isActive).to.be.true;
    });
  });

  describe("Patient Registration by Doctors", function () {
    beforeEach(async function () {
      // Register a verified doctor
      await didRegistry.connect(owner).registerUser(doctor.address, "did:example:doctor1", 2); // UserType.Doctor = 2
    });

    it("Should allow verified doctors to register patients", async function () {
      await didRegistry.connect(doctor).registerPatient(
        patient.address,
        validDID,
        "BiologicalDetails",
        nationalIDHash,
        passportPhotoHash
      );
      const [did, userType, isActive] = await didRegistry.getUserInfo(patient.address);
      expect(did).to.equal(validDID);
      expect(userType).to.equal(1); // Patient
      expect(isActive).to.be.true;
    });

    it("Should prevent unverified doctors from registering patients", async function () {
      // Unregister the doctor to simulate an unverified state
      await didRegistry.connect(owner).deactivateUser(doctor.address);

      await expect(
        didRegistry.connect(doctor).registerPatient(
          patient.address,
          validDID,
          "BiologicalDetails",
          nationalIDHash,
          passportPhotoHash
        )
      ).to.be.revertedWith("Caller must be a doctor");
    });
  });

  describe("Authorizing Doctors", function () {
    beforeEach(async function () {
      // Register a patient and a doctor
      await didRegistry.connect(owner).registerUser(patient.address, "did:example:patient1", 1);
      await didRegistry.connect(owner).registerUser(doctor.address, "did:example:doctor1", 2);
    });

    it("Should allow patients to authorize doctors", async function () {
      await didRegistry.connect(patient).authorizeDoctor(doctor.address);
      expect(await didRegistry.authorizedDoctors(patient.address, doctor.address)).to.be.true;
    });

    it("Should allow patients to revoke authorization for doctors", async function () {
      await didRegistry.connect(patient).authorizeDoctor(doctor.address);
      await didRegistry.connect(patient).revokeDoctorAuthorization(doctor.address);
      expect(await didRegistry.authorizedDoctors(patient.address, doctor.address)).to.be.false;
    });
  });

  describe("Deactivation and Reactivation", function () {
    beforeEach(async function () {
      // Register a user
      await didRegistry.connect(owner).registerUser(patient.address, "did:example:patient1", 1);
    });

    it("Should allow admins to deactivate users", async function () {
      await didRegistry.connect(owner).deactivateUser(patient.address);
      const [, , isActive] = await didRegistry.getUserInfo(patient.address);
      expect(isActive).to.be.false;
    });

    it("Should allow admins to reactivate users", async function () {
      await didRegistry.connect(owner).deactivateUser(patient.address);
      await didRegistry.connect(owner).reactivateUser(patient.address);
      const [, , isActive] = await didRegistry.getUserInfo(patient.address);
      expect(isActive).to.be.true;
    });
  });
});