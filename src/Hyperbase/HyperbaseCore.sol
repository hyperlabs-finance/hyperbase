// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../Interface/IHyperbaseCore.sol';
import 'openzeppelin-contracts/contracts/utils/Timers.sol';
import 'openzeppelin-contracts/contracts/utils/Address.sol';
import 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

/**

  	HyperbaseCore manages the transactions for the Hyperbase account. It records
    past and pending transactions handles their execution.

 */
 
contract HyperbaseCore is IHyperbaseCore {  

  	////////////////
    // USING
    ////////////////

    using Timers for Timers.BlockNumber;
    using SafeCast for uint256;

  	////////////////
    // STATE
    ////////////////

    /**
    * @dev The token used for refunds.
    */
    address gas_token;

    /**
    * @dev Expiry period in block time.
    */
    uint256 expiry_period;

    /**
    * @dev Executions status of the transaction.
    */
    enum Status {
        PENDING,
        CANCELLED,
        EXECUTED,
        FAILED
    }

    /**
    * @dev Core transaction details.
    */
    struct Transaction {
        bool exists;
        uint64 submitted;
        uint64 expires;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        Status status;
    }

    /**
    * @dev Mapping from transaction has to transactionId.
    */
    mapping(uint256 => Transaction) internal _transactionsByHash;

    /**
    * @dev Mapping from status to _transaction index.
    */
    mapping(Status => uint256[]) internal _transactionHashByStatus;

  	////////////////
    // MODIFIERS
    ////////////////

    /**
     * @dev Ensure that the transaction has PENDING status.
     */
    modifier transactionPending(
        uint256 txHash
    ) {
        if (_transactionsByHash[txHash].status != Status.PENDING)
            revert TransactionNotPending();
        _;
    }

    /**
     * @dev Ensure that the transaction fields are not empty.
     */
    modifier transactionNotEmpty(
        address[] memory targets
    ) {
        if (targets.length == 0)      
            revert TransactionEmpty();
        _;
    }

    /**
     * @dev Ensure that the transaction arrays are of equal length.
     */
    modifier transactionArrayParity(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) {
        if (targets.length != values.length || values.length != calldatas.length)
            revert TransactionArrayUnequal();
        _;
    }

    //////////////////////////////////////////////
    // TRANSACTIONS
    //////////////////////////////////////////////

    /**
     * @dev Internal transaction submission function.
     */
    function _submit(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
        internal
        transactionNotEmpty(targets)
        transactionArrayParity(targets, values, calldatas)
        returns (uint256 txHash_)
    {
        // Hash the tx
        uint256 txHash_ = getTransactionHash(targets, values, calldatas);

        // Get the block times for now and transaction expiry
        uint64 submitted = block.number.toUint64();
        uint64 expires = submitted + getExpiryPeriod().toUint64();

        // If tx exsists then reset/update its fields
        if (_transactionsByHash[txHash_].exists) {
            _transactionsByHash[txHash_].submitted = submitted;
            _transactionsByHash[txHash_].expires = expires;
            _transactionsByHash[txHash_].status = Status.PENDING;
        } 
        else {
            // Create and push to transaction array
            _transactionsByHash[txHash_] = Transaction(
                true,
                submitted,
                expires,
                targets,
                values,
                calldatas,
                Status.PENDING
            );
        }

        // Add tx to tx by status
        _transactionHashByStatus[Status.PENDING].push(txHash_);
    }

    /**
     * @dev Internal transaction executions function.
     */
    function _execute(
        uint256 txHash
    )
        internal
        transactionPending(txHash)
    {
        address[] memory targets = _transactionsByHash[txHash].targets;
        uint256[] memory values = _transactionsByHash[txHash].values;
        bytes[] memory calldatas = _transactionsByHash[txHash].calldatas;

        // Execute the tx
        string memory errorMessage = "Hyperbase: call reverted without message";
        for (uint8 i = 0; i < targets.length; i++) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
    
        // Update the transaction status
        _transactionsByHash[txHash].status = Status.EXECUTED;
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    /**
     * @dev Returns the expirey period for a submitted transaction.
     */ 
    function getExpiryPeriod()
        public
        view
        returns (uint256)
    {
        return expiry_period;
    }
    
    /**
     * @dev Returns the transaction hash for a transaction.
     */ 
    function getTransactionHash(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
        public
        view
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(targets, values, calldatas)));
    }
    
    /**
     * @dev Returns list of pending transactions.
     */ 
    function getPendingTransactions()
        public
        returns(uint256[] memory)
    {
        return _transactionHashByStatus[Status.PENDING];
    }

    /**
     * @dev Returns list of pending transactions.
     */ 
    function getPendingTransaction()
        public
        returns(uint256[] memory)
    {
        return _transactionHashByStatus[Status.PENDING];
    }

    /**
     * @dev Returns list of executed transactions.
     */ 
    function getExecutedTransactions()
        public
        returns(uint256[] memory)
    {
        return _transactionHashByStatus[Status.EXECUTED];
    }

    /**
     * @dev Returns the details for a transaction.
     */
    function getTransaction(
        uint256 txHash
    )
        public
        view
        returns (
            bool exists,
            uint64 submitted,
            uint64 expires,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            uint256 status
        )
    {
        exists = _transactionsByHash[txHash].exists;
        submitted = _transactionsByHash[txHash].submitted;
        expires = _transactionsByHash[txHash].expires;
        targets = _transactionsByHash[txHash].targets;
        values = _transactionsByHash[txHash].values;
        calldatas = _transactionsByHash[txHash].calldatas;
        status = uint256(_transactionsByHash[txHash].status);
    }

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    function checkTransactionExists(
        uint256 txHash
    )
        public
        view
        returns(bool)
    {
        return _transactionsByHash[txHash].exists;
    }

}