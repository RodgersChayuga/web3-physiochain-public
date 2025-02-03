### **1. Prerequisites**
Before proceeding, ensure you have the following tools installed on your system:

- **Node.js and npm/yarn**: Install from [https://nodejs.org](https://nodejs.org).
- **Git**: Install from [https://git-scm.com](https://git-scm.com).
- **MetaMask Wallet**: Install the MetaMask browser extension or mobile app.
- **Hardhat**: For smart contract development.
- **IPFS CLI or Pinata**: For decentralized storage.
- **React Native Environment**: Set up your environment for React Native development:
  - Follow the official guide: [https://reactnative.dev/docs/environment-setup](https://reactnative.dev/docs/environment-setup).
- **Web Development Tools**: Node.js, npm/yarn, and a code editor like VS Code.

---

### **2. New Development Setup**

#### **Step 1: Initialize the Project**
1. Create a new directory for your project:
   ```bash
   mkdir PhysioChain-MVP
   cd PhysioChain-MVP
   ```

2. Initialize a Git repository:
   ```bash
   git init
   ```

3. Create the folder structure:
   ```bash
   mkdir contracts frontend tests ipfs scripts
   ```

4. Add a `README.md` file to document your project:
   ```bash
   echo "# PhysioChain MVP" > README.md
   ```

---

#### **Step 2: Set Up Smart Contracts with Hardhat**
1. Navigate to the `contracts` folder:
   ```bash
   cd contracts
   ```

2. Initialize a Hardhat project:
   ```bash
   npx hardhat
   ```
   - Choose "Create an empty hardhat.config.js" when prompted.

3. Install necessary dependencies:
   ```bash
   npm install @openzeppelin/contracts ethers dotenv
   ```

4. Create your first smart contract:
   ```bash
   touch TreatmentPlan.sol RewardToken.sol AccessControl.sol
   ```

5. Configure `hardhat.config.js` for Polygon testnet:
   ```javascript
   require("@nomiclabs/hardhat-waffle");
   require("dotenv").config();

   module.exports = {
       solidity: "0.8.17",
       networks: {
           mumbai: {
               url: process.env.POLYGON_MUMBAI_URL,
               accounts: [process.env.PRIVATE_KEY],
           },
       },
   };
   ```

6. Add `.env` file for sensitive data:
   ```bash
   echo "POLYGON_MUMBAI_URL=https://rpc-mumbai.maticvigil.com" > .env
   echo "PRIVATE_KEY=your-private-key" >> .env
   ```

---

#### **Step 3: Set Up React Native Apps**
1. Navigate to the `frontend` folder:
   ```bash
   cd ../frontend
   ```

2. Create the Patient App:
   ```bash
   npx react-native init PatientApp
   cd PatientApp
   npm install @react-navigation/native @react-navigation/stack react-native-web3 ethers axios
   ```

3. Create the Doctor App:
   ```bash
   cd ..
   npx react-native init DoctorApp
   cd DoctorApp
   npm install @react-navigation/native @react-navigation/stack react-native-web3 ethers axios
   ```

4. Link dependencies (if required):
   ```bash
   npx react-native link
   ```

---

#### **Step 4: Set Up Web Dashboard**
1. Navigate to the `frontend` folder:
   ```bash
   cd ../frontend
   ```

2. Create the Web Dashboard:
   ```bash
   npx create-react-app web-dashboard
   cd web-dashboard
   npm install ethers web3 axios react-router-dom
   ```

3. Start the development server:
   ```bash
   npm start
   ```

---

#### **Step 5: Set Up IPFS**
1. Install IPFS CLI:
   ```bash
   sudo apt-get install ipfs-desktop
   ```

2. Alternatively, use Pinata for IPFS:
   - Sign up at [https://www.pinata.cloud](https://www.pinata.cloud).
   - Install the Pinata SDK:
     ```bash
     npm install @pinata/sdk
     ```

3. Test uploading a file to IPFS:
   ```bash
   ipfs add path/to/file.json
   ```

---

### **3. Cloning the Project**

#### **Step 1: Clone the Repository**
1. Clone the GitHub repository:
   ```bash
   git clone https://github.com/your-repo/PhysioChain-MVP.git
   cd PhysioChain-MVP
   ```

---

#### **Step 2: Install Dependencies**
1. Install dependencies for smart contracts:
   ```bash
   cd contracts
   npm install
   ```

2. Install dependencies for React Native apps:
   ```bash
   cd ../frontend/PatientApp
   npm install
   cd ../DoctorApp
   npm install
   ```

3. Install dependencies for the Web Dashboard:
   ```bash
   cd ../web-dashboard
   npm install
   ```

---

#### **Step 3: Configure Environment Variables**
1. Add a `.env` file in the `contracts` folder:
   ```bash
   echo "POLYGON_MUMBAI_URL=https://rpc-mumbai.maticvigil.com" > .env
   echo "PRIVATE_KEY=your-private-key" >> .env
   ```

2. Add any required `.env` files for the frontend apps if needed.

---

#### **Step 4: Run the Apps**
1. Start the Patient App:
   ```bash
   cd frontend/PatientApp
   npx react-native run-android # or run-ios
   ```

2. Start the Doctor App:
   ```bash
   cd ../DoctorApp
   npx react-native run-android # or run-ios
   ```

3. Start the Web Dashboard:
   ```bash
   cd ../web-dashboard
   npm start
   ```

---

#### **Step 5: Deploy Smart Contracts**
1. Compile and deploy contracts:
   ```bash
   cd ../../contracts
   npx hardhat compile
   npx hardhat run scripts/deploy.js --network mumbai
   ```

2. Save the deployed contract addresses in a `config.js` file for frontend integration.

---

### **4. Testing the Setup**
1. Test the Patient App and Doctor App by connecting MetaMask to Polygon Mumbai testnet.
2. Test the Web Dashboard by interacting with deployed smart contracts.
3. Verify IPFS uploads by retrieving metadata for treatment plans.

---

### **5. Troubleshooting**
- **Hardhat Errors**: Ensure `.env` variables are correctly set.
- **React Native Issues**: Clear cache using `npm start --reset-cache`.
- **IPFS Uploads**: Check your internet connection and ensure IPFS/Pinata is properly configured.

---

This guide provides a clear, step-by-step process for both new development and cloning the project. By following these instructions, you’ll have a fully functional development environment ready for building and testing PhysioChain MVP. Good luck! 🚀