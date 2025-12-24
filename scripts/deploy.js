const hre = require('hardhat');
const fs = require('fs');
const path = require('path');

async function main() {
  console.log('\n========== DEPLOYMENT STARTED =========\\n');
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying with account: ${deployer.address}`);

  // Deploy AuthorizationManager
  console.log('\nDeploying AuthorizationManager...');
  const AuthManager = await ethers.getContractFactory('AuthorizationManager');
  const authManager = await AuthManager.deploy();
  await authManager.deployed();
  console.log(`✓ AuthorizationManager deployed to: ${authManager.address}`);

  // Deploy SecureVault
  console.log('\nDeploying SecureVault...');
  const Vault = await ethers.getContractFactory('SecureVault');
  const vault = await Vault.deploy(authManager.address);
  await vault.deployed();
  console.log(`✓ SecureVault deployed to: ${vault.address}`);

  // Save deployment data
  const deploymentData = {
    authManager: authManager.address,
    vault: vault.address,
    deployer: deployer.address,
    network: hre.network.name,
    timestamp: new Date().toISOString()
  };

  const dir = path.join(__dirname, '../deployments');
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(
    path.join(dir, 'deployment-addresses.json'),
    JSON.stringify(deploymentData, null, 2)
  );

  console.log('\n========== DEPLOYMENT SUCCESSFUL =========\\n');
  console.log(JSON.stringify(deploymentData, null, 2));
  console.log('\n=========================================\\n');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
