// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AuthorizationManager.sol";

/**
 * @title SecureVault
 * @dev Holds funds and executes withdrawals only with valid authorizations
 * Relies on AuthorizationManager for permission validation
 */
contract SecureVault {
    AuthorizationManager private authManager;
    
    uint256 public totalDeposited;
    mapping(address => uint256) public balances;
    
    // Events
    event Deposit(address indexed depositor, uint256 amount, uint256 newBalance);
    event Withdrawal(address indexed recipient, uint256 amount, bytes32 authId);
    event VaultInitialized(address indexed authManagerAddress);
    
    /**
     * @dev Initializes the vault with authorization manager address
     * @param _authManager Address of the AuthorizationManager contract
     */
    constructor(address _authManager) {
        require(_authManager != address(0), "Invalid auth manager address");
        authManager = AuthorizationManager(_authManager);
        emit VaultInitialized(_authManager);
    }
    
    /**
     * @dev Allows anyone to deposit ETH into the vault
     * Accepts native currency via fallback
     */
    receive() external payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        balances[msg.sender] += msg.value;
        totalDeposited += msg.value;
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }
    
    /**
     * @dev Executes a withdrawal with authorization verification
     * @param recipient Address receiving the withdrawal
     * @param amount Amount to withdraw
     * @param nonce Unique identifier for this authorization
     * @return Success indicator
     */
    function withdraw(
        address payable recipient,
        uint256 amount,
        uint256 nonce
    ) external returns (bool) {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient vault balance");
        
        // Verify authorization with AuthorizationManager
        bool isAuthorized = authManager.verifyAuthorization(
            address(this),
            recipient,
            amount,
            nonce,
            ""
        );
        require(isAuthorized, "Authorization verification failed");
        
        // Update state BEFORE transferring funds (checks-effects-interactions)
        totalDeposited -= amount;
        
        // Transfer funds
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
        
        // Construct auth ID for event
        bytes32 authId = keccak256(abi.encodePacked(
            address(this),
            recipient,
            amount,
            nonce,
            block.chainid
        ));
        
        emit Withdrawal(recipient, amount, authId);
        return true;
    }
    
    /**
     * @dev Returns current vault balance
     */
    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Returns the address of the authorization manager
     */
    function getAuthManager() external view returns (address) {
        return address(authManager);
    }
}
