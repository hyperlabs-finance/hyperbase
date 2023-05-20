// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHyperbaseCore {  

  	////////////////
    // ERRORS
    ////////////////

    /**
    * @dev Transaction already has already been submitted.
    */
    error TransactionExists();

    /**
    * @dev Transaction has already been executed.
    */
    error TransactionExecuted();

    /**
    * @dev Transaction not pending.
    */
    error TransactionNotPending();

    /**
     * @dev Transaction is empty.
     */
    error TransactionEmpty();

    /**
     * @dev Transaction arrays have unequal lengths.
     */
    error NoTransactionArrayParity();

  	////////////////
    // EVENTS
    ////////////////

    /**
     * @dev A transaction has been submitted.
     */
    event Submitted(uint256 indexed executionId, address[] indexed to, uint256[] indexed value, bytes[] data);
    
    /**
     * @dev An approval has been added to a transaction.
     */
    event Approved(address indexed sender, uint indexed transactionId);

    /**
     * @dev An key revoked an approval on a transaction.
     */
    event Revoked(address indexed sender, uint indexed transactionId);

    /**
     * @dev A transaction has been executed.
     */
    event Executed(uint256 indexed executionId, address[] indexed to, uint256[] indexed value, bytes[] data);
    
    /**
     * @dev A transaction has been cancelled.
     */
    event Cancelled(uint256 indexed executionId, address[] indexed to, uint256[] indexed value, bytes[] data);
    
    /**
     * @dev An executed transactoin has failed.
     */
    event ExecutionFailure(uint indexed transactionId);

}