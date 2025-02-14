// import { expect } from "chai";
// import { ethers } from "hardhat";
// import { PatientRewards } from "../../typechain-types"; // Adjust import based on your project setup

// describe("PatientRewards", function () {
//     let patientRewards: PatientRewards;
//     let physioToken: any; // Mock ERC20 token
//     let owner: any, patient1: any, patient2: any;

//     const REWARD_PER_SESSION = ethers.parseEther("10"); // 10 $PHYSIO tokens per session
//     const MILESTONE_REWARD = ethers.parseEther("100"); // 100 $PHYSIO tokens per milestone
//     const STREAK_THRESHOLD = 7; // Days
//     const SESSIONS_PER_MILESTONE = 10; // Sessions

//     beforeEach(async function () {
//         // Get signers (accounts) for testing
//         [owner, patient1, patient2] = await ethers.getSigners();

//         // Deploy mock $PHYSIO token
//         const PhysioTokenFactory = await ethers.getContractFactory("ERC20Mock"); // Use a mock ERC20 token
//         physioToken = await PhysioTokenFactory.deploy("Physio Token", "PHYSIO");
//         await physioToken.waitForDeployment();

//         // Deploy PatientRewards contract
//         const PatientRewardsFactory = await ethers.getContractFactory("PatientRewards");
//         patientRewards = await PatientRewardsFactory.deploy(await physioToken.getAddress());
//         await patientRewards.waitForDeployment();
//     });

//     describe("Deployment", function () {
//         it("Should deploy the PatientRewards contract successfully", async function () {
//             const address = await patientRewards.getAddress();
//             expect(address).to.properAddress;
//         });

//         it("Should initialize reward thresholds correctly", async function () {
//             expect(await patientRewards.SESSIONS_PER_MILESTONE()).to.equal(SESSIONS_PER_MILESTONE);
//             expect(await patientRewards.STREAK_THRESHOLD()).to.equal(STREAK_THRESHOLD);
//         });
//     });

//     describe("Exercise Logging and Rewards", function () {
//         it("Should log an exercise completion and reward tokens", async function () {
//             // Mint tokens to the contract
//             await physioToken.mint(await patientRewards.getAddress(), REWARD_PER_SESSION);

//             // Log exercise completion
//             await patientRewards.connect(patient1).logExerciseCompletion();

//             // Check progress
//             const progress = await patientRewards.patientProgress(patient1.address);
//             expect(progress.totalSessionsCompleted).to.equal(1);
//             expect(progress.currentStreak).to.equal(1);

//             // Check token balance
//             const balance = await physioToken.balanceOf(patient1.address);
//             expect(balance).to.equal(REWARD_PER_SESSION);
//         });

//         it("Should reward milestone tokens after completing 10 sessions", async function () {
//             // Mint tokens to the contract
//             const totalReward = (REWARD_PER_SESSION * BigInt(SESSIONS_PER_MILESTONE)) + MILESTONE_REWARD;
//             await physioToken.mint(await patientRewards.getAddress(), totalReward);

//             // Complete 10 sessions
//             for (let i = 0; i < SESSIONS_PER_MILESTONE; i++) {
//                 await patientRewards.connect(patient1).logExerciseCompletion();
//             }

//             // Check progress
//             const progress = await patientRewards.patientProgress(patient1.address);
//             expect(progress.totalSessionsCompleted).to.equal(SESSIONS_PER_MILESTONE);
//             expect(progress.milestonesAchieved).to.equal(1);

//             // Check token balance
//             const balance = await physioToken.balanceOf(patient1.address);
//             expect(balance).to.equal(totalReward);
//         });

//         it("Should reset streak if more than 1 day passes between exercises", async function () {
//             // Mint tokens to the contract
//             await physioToken.mint(await patientRewards.getAddress(), REWARD_PER_SESSION * 3n);

//             // Log first exercise
//             await patientRewards.connect(patient1).logExerciseCompletion();

//             // Simulate time passing (more than 1 day)
//             await ethers.provider.send("evm_increaseTime", [86400 * 2]); // 2 days
//             await ethers.provider.send("evm_mine", []);

//             // Log second exercise
//             await patientRewards.connect(patient1).logExerciseCompletion();

//             // Check progress
//             const progress = await patientRewards.patientProgress(patient1.address);
//             expect(progress.currentStreak).to.equal(1); // Streak resets
//         });

//         it("Should reward streak tokens after maintaining a 7-day streak", async function () {
//             // Mint tokens to the contract
//             const totalReward = (REWARD_PER_SESSION * BigInt(STREAK_THRESHOLD)) + MILESTONE_REWARD;
//             await physioToken.mint(await patientRewards.getAddress(), totalReward);

//             // Complete 7 sessions within 7 days
//             for (let i = 0; i < STREAK_THRESHOLD; i++) {
//                 await patientRewards.connect(patient1).logExerciseCompletion();
//                 await ethers.provider.send("evm_increaseTime", [86400]); // 1 day
//                 await ethers.provider.send("evm_mine", []);
//             }

//             // Check progress
//             const progress = await patientRewards.patientProgress(patient1.address);
//             expect(progress.currentStreak).to.equal(STREAK_THRESHOLD);

//             // Check token balance
//             const balance = await physioToken.balanceOf(patient1.address);
//             expect(balance).to.equal(totalReward);
//         });
//     });

//     describe("Edge Cases", function () {
//         it("Should not reward tokens if contract has insufficient funds", async function () {
//             await expect(patientRewards.connect(patient1).logExerciseCompletion()).to.be.revertedWith(
//                 "Token transfer failed"
//             );
//         });

//         it("Should handle multiple patients independently", async function () {
//             // Mint tokens to the contract
//             await physioToken.mint(await patientRewards.getAddress(), REWARD_PER_SESSION * 2n);

//             // Patient 1 logs an exercise
//             await patientRewards.connect(patient1).logExerciseCompletion();

//             // Patient 2 logs an exercise
//             await patientRewards.connect(patient2).logExerciseCompletion();

//             // Check balances
//             const balance1 = await physioToken.balanceOf(patient1.address);
//             const balance2 = await physioToken.balanceOf(patient2.address);
//             expect(balance1).to.equal(REWARD_PER_SESSION);
//             expect(balance2).to.equal(REWARD_PER_SESSION);
//         });
//     });
// });