// import { expect } from "chai";
// import { ethers } from "hardhat";
// import { DoctorRewards } from "../../typechain-types";

// describe("DoctorRewards", function () {
//     let doctorRewards: DoctorRewards;
//     let physioToken: any;
//     let owner: any, doctor1: any, doctor2: any;

//     beforeEach(async function () {
//         [owner, doctor1, doctor2] = await ethers.getSigners();

//         // Deploy mock $PHYSIO token
//         const PhysioTokenFactory = await ethers.getContractFactory("ERC20Mock");
//         physioToken = await PhysioTokenFactory.deploy("Physio Token", "PHYSIO");

//         // Deploy DoctorRewards contract
//         const DoctorRewardsFactory = await ethers.getContractFactory("DoctorRewards");
//         doctorRewards = await DoctorRewardsFactory.deploy(await physioToken.getAddress());

//         // Mint tokens to the contract
//         await physioToken.mint(await doctorRewards.getAddress(), ethers.parseEther("10000"));

//         // Verify role assignment
//         expect(await doctorRewards.hasRole(ethers.keccak256(ethers.toUtf8Bytes("ADMIN_ROLE")), owner.address)).to.be.true;
//     });

//     describe("Deployment", function () {
//         it("Should deploy the DoctorRewards contract successfully", async function () {
//             const address = await doctorRewards.getAddress();
//             expect(address).to.properAddress;
//         });

//         it("Should initialize the ADMIN_ROLE correctly", async function () {
//             const adminRole = ethers.keccak256(ethers.toUtf8Bytes("ADMIN_ROLE"));
//             expect(await doctorRewards.hasRole(adminRole, owner.address)).to.be.true;
//         });

//         it("Should set initial reward weights correctly", async function () {
//             expect(await doctorRewards.feedbackWeight()).to.equal(10);
//             expect(await doctorRewards.usageWeight()).to.equal(5);
//             expect(await doctorRewards.aiWeight()).to.equal(20);
//         });
//     });

//     describe("Rewarding Doctors", function () {
//         it("Should reward doctors based on performance metrics", async function () {
//             const patientFeedbackScore = 90;
//             const usageCount = 50;
//             const aiRating = 8;

//             // Calculate expected reward: (90 * 10) + (50 * 5) + (8 * 20) = 770
//             const expectedReward = ethers.parseEther("770");

//             await doctorRewards.connect(owner).rewardDoctor(
//                 doctor1.address,
//                 patientFeedbackScore,
//                 usageCount,
//                 aiRating
//             );

//             const balance = await physioToken.balanceOf(doctor1.address);
//             expect(balance).to.equal(expectedReward);
//         });

//         it("Should handle zero performance metrics", async function () {
//             await doctorRewards.connect(owner).rewardDoctor(doctor1.address, 0, 0, 0);

//             const balance = await physioToken.balanceOf(doctor1.address);
//             expect(balance).to.equal(0);
//         });

//         it("Should revert if contract has insufficient funds", async function () {
//             const patientFeedbackScore = 90;
//             const usageCount = 50;
//             const aiRating = 8;

//             // Burn all tokens from the contract
//             await physioToken.burn(await doctorRewards.getAddress(), ethers.parseEther("10000"));

//             await expect(
//                 doctorRewards.connect(owner).rewardDoctor(
//                     doctor1.address,
//                     patientFeedbackScore,
//                     usageCount,
//                     aiRating
//                 )
//             ).to.be.revertedWithCustomError(physioToken, "ERC20InsufficientBalance");
//         });
//     });

//     describe("Events", function () {
//         it("Should emit DoctorRewarded event", async function () {
//             const patientFeedbackScore = 90;
//             const usageCount = 50;
//             const aiRating = 8;

//             // Calculate expected reward: (90 * 10) + (50 * 5) + (8 * 20) = 770
//             const expectedReward = ethers.parseEther("770");

//             await expect(
//                 doctorRewards.connect(owner).rewardDoctor(
//                     doctor1.address,
//                     patientFeedbackScore,
//                     usageCount,
//                     aiRating
//                 )
//             )
//                 .to.emit(doctorRewards, "DoctorRewarded")
//                 .withArgs(doctor1.address, expectedReward);
//         });
//     });

//     describe("Cumulative Rewards Tracking", function () {
//         it("Should track cumulative rewards for leaderboard rankings", async function () {
//             // First reward: (90 * 10) + (50 * 5) + (8 * 20) = 770
//             await doctorRewards.connect(owner).rewardDoctor(doctor1.address, 90, 50, 8);

//             // Second reward: (80 * 10) + (40 * 5) + (7 * 20) = 940
//             await doctorRewards.connect(owner).rewardDoctor(doctor1.address, 80, 40, 7);

//             // Total expected: 770 + 940 = 1320
//             const expectedTotalReward = ethers.parseEther("1320");

//             const balance = await physioToken.balanceOf(doctor1.address);
//             expect(balance).to.equal(expectedTotalReward);

//             const cumulativeRewards = await doctorRewards.getCumulativeRewards(doctor1.address);
//             expect(cumulativeRewards).to.equal(expectedTotalReward);
//         });
//     });

//     describe("Configurable Weights", function () {
//         it("Should allow admins to update reward weights", async function () {
//             await doctorRewards.connect(owner).updateWeights(15, 10, 25);

//             expect(await doctorRewards.feedbackWeight()).to.equal(15);
//             expect(await doctorRewards.usageWeight()).to.equal(10);
//             expect(await doctorRewards.aiWeight()).to.equal(25);
//         });

//         it("Should calculate rewards using updated weights", async function () {
//             await doctorRewards.connect(owner).updateWeights(15, 10, 25);

//             const patientFeedbackScore = 90;
//             const usageCount = 50;
//             const aiRating = 8;

//             // Calculate expected reward: (90 * 15) + (50 * 10) + (8 * 25) = 1670
//             const expectedReward = ethers.parseEther("1670");

//             await doctorRewards.connect(owner).rewardDoctor(
//                 doctor1.address,
//                 patientFeedbackScore,
//                 usageCount,
//                 aiRating
//             );

//             const balance = await physioToken.balanceOf(doctor1.address);
//             expect(balance).to.equal(expectedReward);
//         });
//     });

//     describe("Batch Rewards", function () {
//         it("Should reward multiple doctors in a single transaction", async function () {
//             const doctors = [doctor1.address, doctor2.address];
//             const patientFeedbackScores = [90, 80];
//             const usageCounts = [50, 40];
//             const aiRatings = [8, 7];

//             await doctorRewards.connect(owner).rewardDoctorsBatch(
//                 doctors,
//                 patientFeedbackScores,
//                 usageCounts,
//                 aiRatings
//             );

//             // Doctor1: (90 * 10) + (50 * 5) + (8 * 20) = 770
//             // Doctor2: (80 * 10) + (40 * 5) + (7 * 20) = 940
//             const expectedReward1 = ethers.parseEther("770");
//             const expectedReward2 = ethers.parseEther("940");

//             const balance1 = await physioToken.balanceOf(doctor1.address);
//             const balance2 = await physioToken.balanceOf(doctor2.address);
//             expect(balance1).to.equal(expectedReward1);
//             expect(balance2).to.equal(expectedReward2);
//         });

//         it("Should revert if input arrays have mismatched lengths", async function () {
//             const doctors = [doctor1.address, doctor2.address];
//             const patientFeedbackScores = [90];
//             const usageCounts = [50, 40];
//             const aiRatings = [8, 7];

//             await expect(
//                 doctorRewards.connect(owner).rewardDoctorsBatch(
//                     doctors,
//                     patientFeedbackScores,
//                     usageCounts,
//                     aiRatings
//                 )
//             ).to.be.revertedWith("Input arrays must have the same length");
//         });
//     });

//     describe("Access Control", function () {
//         it("Should prevent non-admins from calling restricted functions", async function () {
//             const patientFeedbackScore = 90;
//             const usageCount = 50;
//             const aiRating = 8;

//             await expect(
//                 doctorRewards.connect(doctor1).rewardDoctor(
//                     doctor1.address,
//                     patientFeedbackScore,
//                     usageCount,
//                     aiRating
//                 )
//             ).to.be.revertedWithCustomError(doctorRewards, "AccessControlUnauthorizedAccount");

//             await expect(
//                 doctorRewards.connect(doctor1).updateWeights(15, 10, 25)
//             ).to.be.revertedWithCustomError(doctorRewards, "AccessControlUnauthorizedAccount");

//             const doctors = [doctor1.address, doctor2.address];
//             const patientFeedbackScores = [90, 80];
//             const usageCounts = [50, 40];
//             const aiRatings = [8, 7];

//             await expect(
//                 doctorRewards.connect(doctor1).rewardDoctorsBatch(
//                     doctors,
//                     patientFeedbackScores,
//                     usageCounts,
//                     aiRatings
//                 )
//             ).to.be.revertedWithCustomError(doctorRewards, "AccessControlUnauthorizedAccount");
//         });
//     });
// });