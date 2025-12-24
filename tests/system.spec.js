const { expect } = require('chai');

describe('Secured Vault System', () => {
  let authManager, vault, owner, recipient;

  before(async () => {
    [owner, recipient] = await ethers.getSigners();
    const AuthMan = await ethers.getContractFactory('AuthorizationManager');
    authManager = await AuthMan.deploy();
    await authManager.deployed();
    const Vault = await ethers.getContractFactory('SecureVault');
    vault = await Vault.deploy(authManager.address);
    await vault.deployed();
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

  it('Should prevent reuse of authorizations', async () => {
    const amount = ethers.utils.parseEther('0.1');
    const nonce = 99;
    await authManager.verifyAuthorization(vault.address, recipient.address, amount, nonce, '0x');
    await expect(
      authManager.verifyAuthorization(vault.address, recipient.address, amount, nonce, '0x')
    ).to.be.revertedWith('Authorization already consumed');
  });
});
