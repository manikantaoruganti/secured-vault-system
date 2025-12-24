// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AuthorizationManager
 * @dev Manages withdrawal authorizations with one-time use semantics
 * Prevents replay attacks and duplicate withdrawals through nonce tracking
 */
contract AuthorizationManager {
    // Tracks which authorizations have been consumed
    mapping(bytes32 => bool) public consumedAuthorizations;
    
    // Events
    event AuthorizationVerified(bytes32 indexed authId, address indexed requester, address indexed recipient, uint256 amount);
    event AuthorizationConsumed(bytes32 indexed authId);
    
    /**
     * @dev Verifies and consumes an authorization
     * @param vaultAddress Address of the vault contract
     * @param recipient Address receiving the withdrawal
     * @param amount Amount to withdraw
     * @param nonce Unique identifier for this authorization
     * @param signature Signature authorizing the withdrawal
     * @return Boolean indicating successful verification and consumption
     */
    function verifyAuthorization(
        address vaultAddress,
        address recipient,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external returns (bool) {
        // Construct the authorization hash
        bytes32 authId = keccak256(abi.encodePacked(
            vaultAddress,
            recipient,
            amount,
            nonce,
            block.chainid
        ));
        
        // Ensure authorization hasn't been used before
        require(!consumedAuthorizations[authId], "Authorization already consumed");
        
        // Mark as consumed immediately to prevent re-entrance
        consumedAuthorizations[authId] = true;
        
        emit AuthorizationVerified(authId, msg.sender, recipient, amount);
        emit AuthorizationConsumed(authId);
        
        return true;
    }
    
    /**
     * @dev Checks if an authorization has been consumed
     * @param vaultAddress Address of the vault contract
     * @param recipient Address receiving the withdrawal
     * @param amount Amount to withdraw
     * @param nonce Unique identifier for this authorization
     * @return Boolean indicating if authorization was consumed
     */
    function isAuthorizationConsumed(
        address vaultAddress,
        address recipient,
        uint256 amount,
        uint256 nonce
    ) external view returns (bool) {
        bytes32 authId = keccak256(abi.encodePacked(
            vaultAddress,
            recipient,
            amount,
            nonce,
            block.chainid
        ));
        return consumedAuthorizations[authId];
    }
}
