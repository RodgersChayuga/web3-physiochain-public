import { ethers } from "hardhat";

async function main() {
    // Step 1: Deploy DIDRegistry (base dependency for role-based access)
    const DIDRegistry = await ethers.deployContract("DIDRegistry");
    await DIDRegistry.waitForDeployment();
    console.log("DIDRegistry Contract Deployed at:", DIDRegistry.target);

    // Step 2: Deploy PhysioToken (used by multiple contracts)
    const PhysioToken = await ethers.deployContract("PhysioToken");
    await PhysioToken.waitForDeployment();
    console.log("PhysioToken Contract Deployed at:", PhysioToken.target);

    // Step 3: Deploy DataManagement (used by DoctorRewards and PatientRewards)
    const DataManagement = await ethers.deployContract("DataManagement");
    await DataManagement.waitForDeployment();
    console.log("DataManagement Contract Deployed at:", DataManagement.target);

    // Step 4: Deploy PatientRegistry (depends on PhysioToken)
    const PatientRegistry = await ethers.deployContract("PatientRegistry", [
        PhysioToken.target,
        DIDRegistry.target,
    ]);
    await PatientRegistry.waitForDeployment();
    console.log("PatientRegistry Contract Deployed at:", PatientRegistry.target);

    // Step 5: Deploy DoctorPayment (depends on PhysioToken)
    const DoctorPayment = await ethers.deployContract("DoctorPayment", [
        PhysioToken.target,
        DIDRegistry.target,
    ]);
    await DoctorPayment.waitForDeployment();
    console.log("DoctorPayment Contract Deployed at:", DoctorPayment.target);

    // Step 6: Deploy DoctorRewards (depends on DataManagement and PhysioToken)
    const DoctorRewards = await ethers.deployContract("DoctorRewards", [
        DataManagement.target,
        PhysioToken.target,
        DIDRegistry.target,
    ]);
    await DoctorRewards.waitForDeployment();
    console.log("DoctorRewards Contract Deployed at:", DoctorRewards.target);

    // Step 7: Deploy PatientRewards (depends on DataManagement and PhysioToken)
    const PatientRewards = await ethers.deployContract("PatientRewards", [
        DataManagement.target,
        PhysioToken.target,
        DIDRegistry.target,
    ]);
    await PatientRewards.waitForDeployment();
    console.log("PatientRewards Contract Deployed at:", PatientRewards.target);

    // Step 8: Deploy TreatmentPlanNFT (depends on DIDRegistry)
    const TreatmentPlanNFT = await ethers.deployContract("TreatmentPlanNFT", [
        DIDRegistry.target,
    ]);
    await TreatmentPlanNFT.waitForDeployment();
    console.log(
        "TreatmentPlanNFT Contract Deployed at:",
        TreatmentPlanNFT.target
    );

    // Step 9: Deploy WearableDataIntegration (no dependencies other than DIDRegistry)
    const WearableDataIntegration = await ethers.deployContract(
        "WearableDataIntegration",
        [DIDRegistry.target]
    );
    await WearableDataIntegration.waitForDeployment();
    console.log(
        "WearableDataIntegration Contract Deployed at:",
        WearableDataIntegration.target
    );

    // Step 10: Deploy AnalyticsContract (depends on DIDRegistry)
    const AnalyticsContract = await ethers.deployContract("AnalyticsContract", [
        DIDRegistry.target,
    ]);
    await AnalyticsContract.waitForDeployment();
    console.log(
        "AnalyticsContract Contract Deployed at:",
        AnalyticsContract.target
    );

    // Step 11: Deploy FeedbackContract (depends on DIDRegistry)
    const FeedbackContract = await ethers.deployContract("FeedbackContract", [
        DIDRegistry.target,
    ]);
    await FeedbackContract.waitForDeployment();
    console.log(
        "FeedbackContract Contract Deployed at:",
        FeedbackContract.target
    );

    // Step 12: Deploy DoctorRegistry (depends on DIDRegistry)
    const DoctorRegistry = await ethers.deployContract("DoctorRegistry", [
        DIDRegistry.target,
    ]);
    await DoctorRegistry.waitForDeployment();
    console.log("DoctorRegistry Contract Deployed at:", DoctorRegistry.target);

    // Step 13: Deploy InstitutionRegistry (depends on DIDRegistry)
    const InstitutionRegistry = await ethers.deployContract(
        "InstitutionRegistry",
        [DIDRegistry.target]
    );
    await InstitutionRegistry.waitForDeployment();
    console.log(
        "InstitutionRegistry Contract Deployed at:",
        InstitutionRegistry.target
    );

    // Save all deployment addresses
    const deployments = {
        DIDRegistry: DIDRegistry.target,
        PhysioToken: PhysioToken.target,
        DataManagement: DataManagement.target,
        PatientRegistry: PatientRegistry.target,
        DoctorRegistry: DoctorRegistry.target,
        InstitutionRegistry: InstitutionRegistry.target,
        DoctorPayment: DoctorPayment.target,
        DoctorRewards: DoctorRewards.target,
        PatientRewards: PatientRewards.target,
        TreatmentPlanNFT: TreatmentPlanNFT.target,
        AnalyticsContract: AnalyticsContract.target,
        FeedbackContract: FeedbackContract.target,
        WearableDataIntegration: WearableDataIntegration.target
    };

    console.log('\nAll deployment addresses:', deployments);

    // Write these addresses to a file
    const fs = require('fs');
    fs.writeFileSync(
        'deployments.json',
        JSON.stringify(deployments, null, 2)
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});