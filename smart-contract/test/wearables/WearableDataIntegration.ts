// import { expect } from "chai";
// import { ethers } from "hardhat";
// import { WearableDataIntegration } from "../../typechain-types";

// describe("WearableDataIntegration", function () {
//     let wearableDataIntegration: WearableDataIntegration;
//     let patient: any;

//     beforeEach(async function () {
//         [patient] = await ethers.getSigners();

//         // Deploy WearableDataIntegration contract
//         const WearableDataIntegrationFactory = await ethers.getContractFactory("WearableDataIntegration");
//         wearableDataIntegration = await WearableDataIntegrationFactory.deploy();
//     });

//     it("Should allow patients to update wearable data", async function () {
//         const steps = 10000;
//         const caloriesBurned = 500;
//         const sleepDuration = 8;

//         // Update wearable data
//         await wearableDataIntegration.connect(patient).updateWearableData(steps, caloriesBurned, sleepDuration);

//         // Retrieve wearable data
//         const data = await wearableDataIntegration.getWearableData(patient.address);
//         expect(data.steps).to.equal(steps);
//         expect(data.caloriesBurned).to.equal(caloriesBurned);
//         expect(data.sleepDuration).to.equal(sleepDuration);
//     });
// });