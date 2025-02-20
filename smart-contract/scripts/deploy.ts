import { ethers } from "hardhat";

async function main() {
    // Step 1: Deploy DIDRegistry first as it's a base dependency
    const DIDRegistry = await ethers.deployContract("DIDRegistry", []);
    await DIDRegistry.waitForDeployment();
    console.log("DIDRegistry Contract Deployed at:", DIDRegistry.target);

    // Step 2: Deploy PhysioToken
    const PhysioToken = await ethers.deployContract("PhysioToken", []);
    await PhysioToken.waitForDeployment();
    console.log("PhysioToken Contract Deployed at:", PhysioToken.target);

    // Step 3: Deploy registries
    const PatientRegistry = await ethers.deployContract("PatientRegistry", []);
    await PatientRegistry.waitForDeployment();
    console.log("PatientRegistry Contract Deployed at:", PatientRegistry.target);

    const DoctorRegistry = await ethers.deployContract("DoctorRegistry", []);
    await DoctorRegistry.waitForDeployment();
    console.log("DoctorRegistry Contract Deployed at:", DoctorRegistry.target);

    const InstitutionRegistry = await ethers.deployContract("InstitutionRegistry", []);
    await InstitutionRegistry.waitForDeployment();
    console.log("InstitutionRegistry Contract Deployed at:", InstitutionRegistry.target);

    // Step 4: Deploy treatment-related contracts
    const TreatmentPlanNFT = await ethers.deployContract("TreatmentPlanNFT", [DIDRegistry.target]);
    await TreatmentPlanNFT.waitForDeployment();
    console.log("TreatmentPlanNFT Contract Deployed at:", TreatmentPlanNFT.target);

    const AnalyticsContract = await ethers.deployContract("AnalyticsContract", []);
    await AnalyticsContract.waitForDeployment();
    console.log("AnalyticsContract Contract Deployed at:", AnalyticsContract.target);

    const FeedbackContract = await ethers.deployContract("FeedbackContract", []);
    await FeedbackContract.waitForDeployment();
    console.log("FeedbackContract Contract Deployed at:", FeedbackContract.target);

    // Step 5: Deploy reward-related contracts
    const platformOwner = await (await ethers.provider.getSigner(0)).getAddress(); // Using first signer as platform owner
    const serviceFeePercentage = 500; // 5% as basis points

    const DoctorPayment = await ethers.deployContract("DoctorPayment", [
        PhysioToken.target,
        platformOwner,
        serviceFeePercentage
    ]);
    await DoctorPayment.waitForDeployment();
    console.log("DoctorPayment Contract Deployed at:", DoctorPayment.target);

    // Deploy DataManagement first (assuming it exists, as it's referenced in DoctorReward)
    const DataManagement = await ethers.deployContract("DataManagement", []);
    await DataManagement.waitForDeployment();
    console.log("DataManagement Contract Deployed at:", DataManagement.target);

    const DoctorRewards = await ethers.deployContract("DoctorRewards", [
        PhysioToken.target,
        DataManagement.target
    ]);
    await DoctorRewards.waitForDeployment();
    console.log("DoctorRewards Contract Deployed at:", DoctorRewards.target);

    const PatientRewards = await ethers.deployContract("PatientRewards", [
        PhysioToken.target,
        DataManagement.target
    ]);
    await PatientRewards.waitForDeployment();
    console.log("PatientRewards Contract Deployed at:", PatientRewards.target);

    // Step 6: Deploy wearable integration
    const WearableDataIntegration = await ethers.deployContract("WearableDataIntegration", []);
    await WearableDataIntegration.waitForDeployment();
    console.log("WearableDataIntegration Contract Deployed at:", WearableDataIntegration.target);

    // Save all deployment addresses and transaction hashes
    const deployments = {
        DIDRegistry: {
            address: DIDRegistry.target,
            deploymentHash: DIDRegistry.deploymentTransaction()?.hash
        },
        PhysioToken: {
            address: PhysioToken.target,
            deploymentHash: PhysioToken.deploymentTransaction()?.hash
        },
        DataManagement: {
            address: DataManagement.target,
            deploymentHash: DataManagement.deploymentTransaction()?.hash
        },
        PatientRegistry: {
            address: PatientRegistry.target,
            deploymentHash: PatientRegistry.deploymentTransaction()?.hash
        },
        DoctorRegistry: {
            address: DoctorRegistry.target,
            deploymentHash: DoctorRegistry.deploymentTransaction()?.hash
        },
        InstitutionRegistry: {
            address: InstitutionRegistry.target,
            deploymentHash: InstitutionRegistry.deploymentTransaction()?.hash
        },
        DoctorPayment: {
            address: DoctorPayment.target,
            deploymentHash: DoctorPayment.deploymentTransaction()?.hash
        },
        DoctorRewards: {
            address: DoctorRewards.target,
            deploymentHash: DoctorRewards.deploymentTransaction()?.hash
        },
        PatientRewards: {
            address: PatientRewards.target,
            deploymentHash: PatientRewards.deploymentTransaction()?.hash
        },
        TreatmentPlanNFT: {
            address: TreatmentPlanNFT.target,
            deploymentHash: TreatmentPlanNFT.deploymentTransaction()?.hash
        },
        AnalyticsContract: {
            address: AnalyticsContract.target,
            deploymentHash: AnalyticsContract.deploymentTransaction()?.hash
        },
        FeedbackContract: {
            address: FeedbackContract.target,
            deploymentHash: FeedbackContract.deploymentTransaction()?.hash
        },
        WearableDataIntegration: {
            address: WearableDataIntegration.target,
            deploymentHash: WearableDataIntegration.deploymentTransaction()?.hash
        }
    };

    console.log('\nAll deployment addresses:', deployments);

    // Write these addresses to a file
    try {
        const fs = require('fs');
        fs.writeFileSync(
            'deployments.json',
            JSON.stringify(deployments, null, 2)
        );
        console.log('Deployment addresses saved to deployments.json');
    } catch (error) {
        console.error('Failed to write deployments.json:', error);
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});