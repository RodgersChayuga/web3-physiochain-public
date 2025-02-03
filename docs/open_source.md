# **PhysioChain - Open Source Contribution Guide**

Welcome to **PhysioChain**, an open-source project aimed at revolutionizing physiotherapy through blockchain and AI technologies. We welcome contributions from developers, designers, and enthusiasts who are passionate about healthcare innovation. Below is a step-by-step guide to help you get started with contributing to the project.

---

## **Table of Contents**
- [**PhysioChain - Open Source Contribution Guide**](#physiochain---open-source-contribution-guide)
  - [**Table of Contents**](#table-of-contents)
  - [**Project Overview**](#project-overview)
  - [**Getting Started**](#getting-started)
    - [**Fork the Repository**](#fork-the-repository)
    - [**Cloning the Repository**](#cloning-the-repository)
    - [**Syncing Your Fork**](#syncing-your-fork)
    - [**Setting Up the Environment**](#setting-up-the-environment)
      - [**Smart Contracts**](#smart-contracts)
      - [**Frontend (Patient App and Doctor App)**](#frontend-patient-app-and-doctor-app)
      - [**Web Dashboard**](#web-dashboard)
  - [**Contributing Guidelines**](#contributing-guidelines)
    - [**Branching Strategy**](#branching-strategy)
    - [**Commit Message Format**](#commit-message-format)
    - [**Submitting Pull Requests**](#submitting-pull-requests)
  - [**Codebase Structure**](#codebase-structure)
  - [**Testing**](#testing)
  - [**Reporting Issues**](#reporting-issues)
  - [**Community and Support**](#community-and-support)

---

## **Project Overview**

PhysioChain is a decentralized, AI-powered physiotherapy platform that combines blockchain technology and artificial intelligence to address challenges in patient monitoring, adherence, and data privacy. The MVP focuses on building the core infrastructure, including smart contracts, token rewards, and basic frontend interfaces for patients and doctors.

---

## **Getting Started**

### **Fork the Repository**
1. Navigate to the [PhysioChain GitHub repository](https://github.com/your-repo/PhysioChain-MVP).
2. Click the **"Fork"** button in the top-right corner of the page.
   - This will create a copy of the repository under your GitHub account.

3. After forking, you will have your own version of the repository at:
   ```
   https://github.com/your-username/PhysioChain-MVP
   ```

---

### **Cloning the Repository**
1. Clone **your forked repository** to your local machine:
   ```bash
   git clone https://github.com/your-username/PhysioChain-MVP.git
   cd PhysioChain-MVP
   ```

2. Add the original repository as an **upstream remote** to keep your fork updated:
   ```bash
   git remote add upstream https://github.com/your-repo/PhysioChain-MVP.git
   ```

3. Verify the remotes:
   ```bash
   git remote -v
   ```
   You should see both `origin` (your fork) and `upstream` (the original repository).

---

### **Syncing Your Fork**
To keep your fork up-to-date with the original repository:
1. Fetch updates from the upstream repository:
   ```bash
   git fetch upstream
   ```

2. Merge the updates into your local branch:
   ```bash
   git merge upstream/main
   ```

3. Push the updates to your fork:
   ```bash
   git push origin main
   ```

---

### **Setting Up the Environment**

#### **Smart Contracts**
1. Navigate to the `contracts` folder:
   ```bash
   cd contracts
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Configure `.env` file:
   ```bash
   echo "POLYGON_MUMBAI_URL=https://rpc-mumbai.maticvigil.com" > .env
   echo "PRIVATE_KEY=your-private-key" >> .env
   ```

4. Compile and deploy contracts:
   ```bash
   npx hardhat compile
   npx hardhat run scripts/deploy.js --network mumbai
   ```

---

#### **Frontend (Patient App and Doctor App)**
1. Navigate to the `frontend/PatientApp` or `frontend/DoctorApp` folder:
   ```bash
   cd frontend/PatientApp
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run the app:
   ```bash
   npx react-native run-android # or run-ios
   ```

---

#### **Web Dashboard**
1. Navigate to the `frontend/web-dashboard` folder:
   ```bash
   cd frontend/web-dashboard
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

---

## **Contributing Guidelines**

We follow a structured process to ensure high-quality contributions. Please adhere to the following guidelines:

### **Branching Strategy**
1. Create a new branch for your contribution:
   ```bash
   git checkout -b feature/your-feature-name
   ```
   Use one of the following prefixes for your branch name:
   - `feature/`: New features.
   - `fix/`: Bug fixes.
   - `docs/`: Documentation updates.
   - `chore/`: Maintenance tasks.

2. Push your branch to GitHub:
   ```bash
   git push origin feature/your-feature-name
   ```

---

### **Commit Message Format**
Write clear and concise commit messages using the following format:
```
<type>: <short description>
```
Examples:
- `feat: add treatment plan creation functionality`
- `fix: resolve issue with reward token distribution`
- `docs: update README with contribution guidelines`

---

### **Submitting Pull Requests**
1. Once your changes are ready, submit a pull request (PR) from your forked repository to the original repository's `main` branch.
2. Provide a detailed description of your changes in the PR, including:
   - What the PR addresses.
   - How the changes work.
   - Any testing performed.

3. Ensure your PR passes all CI/CD checks (e.g., linting, tests).

4. A maintainer will review your PR and provide feedback. Address any requested changes before the PR is merged.

---

## **Codebase Structure**

The project is organized as follows:
```
PhysioChain-MVP/
├── contracts/                # Smart contracts
│   ├── TreatmentPlan.sol     # Smart contract for treatment plans (NFTs)
│   ├── RewardToken.sol       # ERC-20 token for rewards ($PHYSIO)
│   ├── AccessControl.sol     # Role-based access control (RBAC)
│   └── migrations/           # Migration scripts for deploying contracts
├── frontend/                 # Frontend applications
│   ├── PatientApp/           # Patient-facing app (React Native)
│   ├── DoctorApp/            # Doctor-facing app (React Native)
│   └── web-dashboard/        # Web dashboard (Next.js + Tailwind CSS + shadcn)
├── tests/                    # Unit and integration tests
├── ipfs/                     # IPFS-related files
├── scripts/                  # Helper scripts
└── README.md                 # Project overview and setup instructions
```

---

## **Testing**

Run tests to ensure your changes do not break existing functionality:
1. **Smart Contracts**:
   ```bash
   npx hardhat test
   ```

2. **Frontend**:
   - Patient App and Doctor App:
     ```bash
     npm test
     ```
   - Web Dashboard:
     ```bash
     npm run test
     ```

---

## **Reporting Issues**

If you encounter a bug or have a feature request:
1. Check the [Issues](https://github.com/your-repo/PhysioChain-MVP/issues) tab to see if it has already been reported.
2. If not, create a new issue with the following details:
   - A clear title.
   - Steps to reproduce the issue.
   - Expected vs. actual behavior.
   - Screenshots or error logs (if applicable).

---

## **Community and Support**

Join our community to stay updated and collaborate with other contributors:
- **Discord**: [Join our Discord server](https://discord.gg/your-link)
- **GitHub Discussions**: [Participate in discussions](https://github.com/your-repo/PhysioChain-MVP/discussions)
- **Twitter**: Follow us [@YourTwitterHandle](https://twitter.com/YourTwitterHandle)

---

Thank you for contributing to **PhysioChain**! Your efforts help us build a better future for decentralized healthcare. 🚀
