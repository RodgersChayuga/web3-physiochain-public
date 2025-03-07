const { ethers } = require("hardhat");
const fs = require("fs");

interface Doctor {
    nationalID: string;
    licenseNumber: string;
    name: string;
    licenseStatus: string;
}

async function simulateDoctorVerification(
    doctorAddress: string,
    requestId: string
) {
    try {
        // Load the dummy government database
        const governmentDatabase = JSON.parse(fs.readFileSync("governmentDatabase.json", "utf-8"));

        // Connect to the deployed contracts
        const didRegistryAddress = "0xYourDIDRegistryAddress"; // Replace with actual address
        const governmentOracleAddress = "0xYourGovernmentOracleAddress"; // Replace with actual address

        const didRegistry = await ethers.getContractAt("DIDRegistry", didRegistryAddress);
        const governmentOracle = await ethers.getContractAt("GovernmentOracle", governmentOracleAddress);

        // Get the doctor's registration request data from DIDRegistry
        const doctorRequest = await didRegistry.doctorRequests(doctorAddress);
        if (!doctorRequest.did) {
            throw new Error("No pending registration request found for doctor");
        }

        const nationalID = doctorRequest.nationalIDHash;
        const licenseNumber = doctorRequest.licenseNumber;

        // Verify credentials against the dummy government database
        let isVerified = false;
        let name = "";
        let licenseStatus = "";
        const doctorData = governmentDatabase.doctors.find(
            (doc: Doctor) => doc.nationalID === nationalID && doc.licenseNumber === licenseNumber
        );

        if (doctorData) {
            console.log(`Doctor credentials verified for ${nationalID} and ${licenseNumber}`);
            isVerified = true;
            name = doctorData.name;
            licenseStatus = doctorData.licenseStatus;
        } else {
            console.log(`Doctor credentials NOT verified for ${nationalID} and ${licenseNumber}`);
        }

        // Simulate Chainlink requestVerification
        console.log("Simulating Chainlink requestVerification...");
        const requestTx = await governmentOracle.requestVerification(requestId, nationalID, licenseNumber);
        await requestTx.wait();
        console.log(`Chainlink request simulated: ${requestTx.hash}`);

        // Simulate Chainlink fulfill
        console.log("Simulating Chainlink fulfill...");
        const fulfillTx = await governmentOracle.fulfill(requestId, isVerified, name, licenseStatus);
        await fulfillTx.wait();
        console.log(`Chainlink fulfillment completed: ${fulfillTx.hash}`);

        // Verify the doctor is registered in DIDRegistry
        const userInfo = await didRegistry.getUserInfo(doctorAddress);
        console.log("Doctor registration status:", {
            did: userInfo[0],
            userType: userInfo[1].toNumber(), // 2 = Doctor
            isActive: userInfo[2],
            createdByDoctor: userInfo[3]
        });
    } catch (error: unknown) {
        console.error("Error in simulateDoctorVerification:",
            error instanceof Error ? error.message : String(error)
        );
    }
}

async function main() {
    // Dummy doctor address and requestId (you'll need to get the actual requestId from the emitted event)
    const doctorAddress = "0x1111111111111111111111111111111111111111";

    // Normally, you'd get the requestId by listening for the DoctorVerificationRequest event
    // For this example, compute it manually if you know the timestamp of the registration request
    const blockTimestamp = (await ethers.provider.getBlock("latest")).timestamp;
    const requestId = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
            ["address", "uint256"],
            [doctorAddress, blockTimestamp]
        )
    );

    await simulateDoctorVerification(doctorAddress, requestId);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });