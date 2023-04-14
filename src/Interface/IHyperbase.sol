// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHyperbase {
    
    // Determines what types of tx the key can submit/approve 
    enum Permission {
        CLAIM,
        ACTION,
        MANAGEMENT
    }
    
    // Execution status
    enum Status {
        PENDING,
        CANCELLED,
        SUBMITTED,
        EXECUTED,
        FAILED
    }
    
    event KeyAdded(address indexed key, uint8 indexed permission);
    event KeyRemoved(address indexed key, uint8 indexed permission);

    event ExecutionRequested(uint256 indexed executionId, address[] indexed to, uint256[] indexed value, bytes[] data);
    event Approved(address indexed sender, uint indexed transactionId, bool approved);
    event Executed(uint256 indexed executionId, address[] indexed to, uint256[] indexed value, bytes[] data);
    event ExecutionFailure(uint indexed transactionId);

    event Revocation(address indexed sender, uint indexed transactionId);
    

    event RequirementChange(uint8 permission, uint8 required);

}