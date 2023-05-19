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

}