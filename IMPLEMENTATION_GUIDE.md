# Complete Implementation Guide

## CRITICAL: Create These Files Locally

### File 1: scripts/deploy.js

```javascript
const hre = require('hardhat');
const fs = require('fs');
const path = require('path');

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying with: ${deployer.address}`);

  const AuthMan = await ethers.getContractFactory('AuthorizationManager');
  const authManager = await AuthMan.deploy();
  await authManager.deployed();
  console.log(`AuthorizationManager: ${authManager.address}`);

  const Vault = await ethers.getContractFactory('SecureVault');
  const vault = await Vault.deploy(authManager.address);
  await vault.deployed();
  console.log(`SecureVault: ${vault.address}`);

  const data = {
    authManager: authManager.address,
    vault: vault.address,
    deployer: deployer.address,
    network: hre.network.name
  };

  const dir = path.join(__dirname, '../deployments');
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(
    path.join(dir, 'addresses.json'),
    JSON.stringify(data, null, 2)
  );
  console.log(JSON.stringify(data, null, 2));
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
```

### File 2: docker/Dockerfile

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
RUN npx hardhat compile
CMD ["sh", "./docker/entrypoint.sh"]
```

### File 3: docker/entrypoint.sh

```bash
#!/bin/sh
set -e
npx hardhat node --hostname 0.0.0.0 > /tmp/node.log 2>&1 &
sleep 5
npx hardhat run scripts/deploy.js --network localhost
wait
```

### File 4: docker-compose.yml

```yaml
version: '3.8'
services:
  blockchain:
    build:
      context: .
      dockerfile: docker/Dockerfile
    ports:
      - "8545:8545"
    volumes:
      - ./deployments:/app/deployments
```

### File 5: tests/system.spec.js

```javascript
const { expect } = require('chai');

describe('Vault System', () => {
  let authManager, vault, owner, recipient;

  before(async () => {
    [owner, recipient] = await ethers.getSigners();
    const AuthMan = await ethers.getContractFactory('AuthorizationManager');
    authManager = await AuthMan.deploy();
    const Vault = await ethers.getContractFactory('SecureVault');
    vault = await Vault.deploy(authManager.address);
  });

  it('Should accept deposits', async () => {
    const amount = ethers.utils.parseEther('1.0');
    await owner.sendTransaction({ to: vault.address, value: amount });
    const balance = await ethers.provider.getBalance(vault.address);
    expect(balance).to.equal(amount);
  });

  it('Should allow authorized withdrawals', async () => {
    const amount = ethers.utils.parseEther('0.5');
    const nonce = 1;
    await authManager.verifyAuthorization(vault.address, recipient.address, amount, nonce, '0x');
    await vault.withdraw(recipient.address, amount, nonce);
  });

  it('Should prevent reuse', async () => {
    const amount = ethers.utils.parseEther('0.1');
    const nonce = 99;
    await authManager.verifyAuthorization(vault.address, recipient.address, amount, nonce, '0x');
    await expect(
      authManager.verifyAuthorization(vault.address, recipient.address, amount, nonce, '0x')
    ).to.be.revertedWith('Authorization already consumed');
  });
});
```

## Deploy Instructions

1. Clone repo and run: `npm install`
2. Create all files above in respective directories
3. Run: `docker-compose up`
4. Check logs for contract addresses
5. Test with: `npm test`

## What You Have

✓ contracts/AuthorizationManager.sol
✓ contracts/SecureVault.sol
✓ package.json
✓ hardhat.config.js

## What You Need To Create Locally

✓ scripts/deploy.js
✓ docker/Dockerfile
✓ docker/entrypoint.sh
✓ docker-compose.yml
✓ tests/system.spec.js
✓ .gitignore

All code above is ready to copy-paste. Good luck!
