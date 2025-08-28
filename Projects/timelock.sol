// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Project - TimeLock Contract
 * @dev A smart contract that allows users to lock funds until a specific timestamp
 * @author Your Name
 */
contract Project {
    
    // Struct to store lock information
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
        address owner;
        bool withdrawn;
    }
    
    // Mapping from lock ID to Lock struct
    mapping(uint256 => Lock) public locks;
    
    // Mapping from user address to their lock IDs
    mapping(address => uint256[]) public userLocks;
    
    // Counter for lock IDs
    uint256 public nextLockId;
    
    // Events
    event FundsLocked(
        uint256 indexed lockId,
        address indexed owner,
        uint256 amount,
        uint256 unlockTime
    );
    
    event FundsWithdrawn(
        uint256 indexed lockId,
        address indexed owner,
        uint256 amount
    );
    
    // Custom errors
    error InvalidUnlockTime();
    error NoFundsSent();
    error LockNotFound();
    error NotOwner();
    error FundsNotUnlocked();
    error AlreadyWithdrawn();
    error WithdrawalFailed();
    
    /**
     * @dev Lock funds until a specific timestamp
     * @param _unlockTime The timestamp when funds can be withdrawn
     */
    function lockFunds(uint256 _unlockTime) external payable {
        if (msg.value == 0) revert NoFundsSent();
        if (_unlockTime <= block.timestamp) revert InvalidUnlockTime();
        
        uint256 lockId = nextLockId++;
        
        locks[lockId] = Lock({
            amount: msg.value,
            unlockTime: _unlockTime,
            owner: msg.sender,
            withdrawn: false
        });
        
        userLocks[msg.sender].push(lockId);
        
        emit FundsLocked(lockId, msg.sender, msg.value, _unlockTime);
    }
    
    /**
     * @dev Withdraw locked funds after the unlock time has passed
     * @param _lockId The ID of the lock to withdraw from
     */
    function withdrawFunds(uint256 _lockId) external {
        Lock storage lock = locks[_lockId];
        
        if (lock.owner == address(0)) revert LockNotFound();
        if (lock.owner != msg.sender) revert NotOwner();
        if (block.timestamp < lock.unlockTime) revert FundsNotUnlocked();
        if (lock.withdrawn) revert AlreadyWithdrawn();
        
        lock.withdrawn = true;
        
        (bool success, ) = payable(msg.sender).call{value: lock.amount}("");
        if (!success) revert WithdrawalFailed();
        
        emit FundsWithdrawn(_lockId, msg.sender, lock.amount);
    }
    
    /**
     * @dev Get lock information by lock ID
     * @param _lockId The ID of the lock
     * @return amount The locked amount
     * @return unlockTime The timestamp when funds can be withdrawn
     * @return owner The owner of the lock
     * @return withdrawn Whether the funds have been withdrawn
     */
    function getLockInfo(uint256 _lockId) 
        external 
        view 
        returns (
            uint256 amount,
            uint256 unlockTime,
            address owner,
            bool withdrawn
        ) 
    {
        Lock memory lock = locks[_lockId];
        return (lock.amount, lock.unlockTime, lock.owner, lock.withdrawn);
    }
    
    /**
     * @dev Get all lock IDs for a specific user
     * @param _user The address of the user
     * @return An array of lock IDs owned by the user
     */
    function getUserLocks(address _user) external view returns (uint256[] memory) {
        return userLocks[_user];
    }
    
    /**
     * @dev Check if funds can be withdrawn from a specific lock
     * @param _lockId The ID of the lock
     * @return True if funds can be withdrawn, false otherwise
     */
    function canWithdraw(uint256 _lockId) external view returns (bool) {
        Lock memory lock = locks[_lockId];
        return (
            lock.owner != address(0) &&
            block.timestamp >= lock.unlockTime &&
            !lock.withdrawn
        );
    }
    
    /**
     * @dev Get the total number of locks created
     * @return The total number of locks
     */
    function getTotalLocks() external view returns (uint256) {
        return nextLockId;
    }
}
