// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../Interface/IHyperbaseCore.sol';
import 'openzeppelin-contracts/contracts/utils/Timers.sol';
import 'openzeppelin-contracts/contracts/utils/Address.sol';
import 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

contract HyperbaseCore is IHyperbaseCore {  

  	////////////////
    // USING
    ////////////////

    using Timers for Timers.BlockNumber;
    using SafeCast for uint256;

  	////////////////
    // CONSTANTS
    ////////////////

    /**
    * @dev The token used for refunds.
    */
    address GAS_TOKEN;

    /**
    * @dev Expiry period in block time.
    */
    uint256 EXPIRY_PERIOD;

    /**
    * @dev Executions status of the transaction.
    */
    enum Status {
        PENDING,
        CANCELLED,
        SUBMITTED,
        EXECUTED,
        FAILED
    }

  	////////////////
    // STATE
    ////////////////

    /**
    * @dev Core transaction details.
    */
    struct Transaction {
        uint64 submitted;
        uint64 expires;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        Status status;
    }

    /**
    * @dev All _transactions from.
    */
	Transaction[] private _transactions;

    /**
    * @dev Mapping from transaction index to adress to approval status.
    */
    mapping(uint256 => mapping(address => bool)) public _approvalsByTransaction;

    /**
    * @dev Mapping from id to _transactions index.
    */
    mapping(uint256 => uint256) _transactionsByHash;

    /**
    * @dev Mapping from status to _transaction index.
    */
    mapping(Status => uint256[]) _transactionsByStatus;

  	////////////////
    // MODIFIERS
    ////////////////
     
    /**
     * @dev Ensure that the transaction does not already exist.
     */
    modifier transactionExists(
		uint256 txHash
	) {
        if (uint256(_transactions[_transactionsByHash[txHash]].required) == 0) 
            revert TransactionExists();
        _;
    }

    /**
     * @dev Ensure that the transaction has PENDING status.
     */
    modifier transactionPending(
        uint256 txHash
    ) {
        if (_transactions[_transactionsByHash[txHash]].status != Status.PENDING)
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
            revert NoTransactionArrayParity();
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
        returns (uint256)
    {
        // Hash the tx
        uint256 txHash = getTransactionHash(targets, values, calldatas);

        // Get the block times for now and transaction expiry
        uint64 submitted = block.number.toUint64();
        uint64 expires = submitted + getExpiryPeriod().toUint64();

        // If tx exsists then reset/update its fields
        if (0 < _transactionsByHash[txHash]) {

            _transactions[_transactionsByHash[txHash]].submitted = submitted;
            _transactions[_transactionsByHash[txHash]].expires = expires;

            _transactions[_transactionsByHash[txHash]].status = Status.PENDING;

        } 
        // Else create a new tx 
        else {
            
            // Create and push to transaction array
            _transactions.push(Transaction(
                submitted,
                expires,
                targets,
                values,
                calldatas,
                Status.PENDING
            ));

            // Transactions by hash
            _transactionsByHash[txHash] = _transactions.length;
        }

        // Add tx to tx by status
        _transactionsByStatus[Status.PENDING].push(_transactionsByHash[txHash]);

        // Add the approval from the sender
        _approvalsByTransaction[_transactions.length][_msgSender()] = true;   
    }

    /**
     * @dev Internal transaction executions function.
     */
    function _execute(
        uint256 txHash, /* txHash */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
        internal
        transactionPending(txHash)
    {
        // Execute the tx
        string memory errorMessage = "Hyperbase: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
    
        // Update the transaction status
        _transactions[_transactionsByHash[txHash]].status = Status.EXECUTED;

        return txHash;
    }

    /**
     * @dev Internal cancel a transaction function.
     */ 
    function _cancel(
        uint256 txHash,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
        internal
        virtual
        transactionPending(txHash)
        returns (uint256)
    {
        // Get tx status
        Status status = _transactions[_transactionsByHash[txHash]].status;

        // Update the transaction status
        _transactions[_transactionsByHash[txHash]].status = Status.CANCELLED;

        // Event
        emit Canceled(txHash, targets, values, calldatas);

        return _transactionsByHash[txHash];
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
        return EXPIRY_PERIOD;
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
        pure 
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(targets, values, calldatas)));
    }
    
    /**
     * @dev Returns total number of transactions after filters are applied.
     */ 
    function getTransactionCount(
        bool pending,
        bool executed
    )
        public
        view
        returns (uint8 approvalCount)
    {
        for (uint256 i = 0; i <  _transactions.length; i++)
            if (pending && _transactions[i].status == Status.PENDING || executed && _transactions[i].status == Status.EXECUTED)
                approvalCount++;
    }

    /**
     * @dev Returns list of transaction IDs in defined range.
     */ 
    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    )
        public
        view
        returns (uint256[] memory txHashs)
    {
        uint256[] memory txHashsTemp = new uint256[](_transactions.length);
        uint8 approvalCount = 0;
        for (uint256 i = 0; i < _transactions.length; i++) {
            if (pending && _transactions[i].status == Status.PENDING || executed && _transactions[i].status == Status.EXECUTED) {
                txHashsTemp[approvalCount] = i;
                approvalCount++;
            }
        }
        txHashs = new uint256[](to - from);
        for (uint256 i = from; i < to; i++)   
            txHashs[i - from] = txHashsTemp[i];
    }

}