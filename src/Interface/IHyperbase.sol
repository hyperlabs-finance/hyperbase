// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHyperbase {

  	////////////////
    // ERRORS
    ////////////////

    /**
    * @dev Only this contract can call these functions.
    */
    error OnlyThis()
        
    /**
    * @dev Key has already been added to the account.
    */
    error KeyExists();

    /**
    * @dev Key has not been added to the account.
    */
    error KeyDoesNotExists();

    /**
    * @dev Key has not approved the transaction.
    */
    error KeyNotApproved();

    /**
    * @dev Key has already approved the transaction.
    */
    error KeyApproved();

    /**
    * @dev Key is zero address.
    */
    error KeyZeroAddress();

    /**
    * @dev Key does not have permission for the transaction.
    */
    error KeyDoesNotHavePermission();




    
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