// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/metatx/ERC2771Context.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import '../Interface/IHyperbase.sol';
import 'openzeppelin-contracts/contracts/utils/Timers.sol';
import 'openzeppelin-contracts/contracts/utils/Address.sol';
import 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

// #TODO: EXPIRED TRANSACTIONS
// #TODO: remove permission levels, needless complexity
// #TODO: sign multiple transactions in one

contract Hyperbase is IHyperbase, ERC2771Context {  

  	////////////////
    // CONSTANTS
    ////////////////

    /**
    * @dev The token used for refunds.
    */
    address GAS_TOKEN;

  	////////////////
    // STATE
    ////////////////

    /**
    * @dev Core transaction details
    */
    struct Transaction {
        Permission required;
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
     * @dev Ensure that the transaction has not already been executed.
     */
    modifier transactionNotExecuted(
		uint256 txHash
	) {
        if (_transactions[_transactionsByHash[txHash]].status == Status.EXECUTED)
            revert TransactionExecuted();
        _;
    }

    /**
     * @dev Ensure that the transaction has PENDING STATUS
     */
    modifier transactionPending(
        uint256 txHash
    ) {
        if (_transactions[_transactionsByHash[txHash]].status != Status.PENDING)
            revert TransactionNotPending();
        _;
    }














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
    * @dev Maximum number of keys/devices on the account.
    */
    uint8 MAX_KEY_COUNT = 8;

    /**
    * @dev Expiry period in block time.
    */
    uint256 EXPIRY_PERIOD;

    /**
    * @dev Number of sigs required.
    */
    uint256 REQUIRED;

  	////////////////
    // STATE
    ////////////////

    /**
    * @dev All keys on the approvalCount.
    */
    Key[] public _keys;

    /**
    * @dev Mapping from address to key index.
    */
    mapping(address => uint256) _keysByAddress;

  	////////////////
    // CONSTRUCTOR
    ////////////////
		
	constructor(
		address forwarder
	)
		ERC2771Context(forwarder)
	{
        
        // Push to transaction array
        _keys.push(_msgSender());

        _keysByAddress[_msgSender()] = _keys.length;
	}

  	////////////////
    // MODIFIERS
    ////////////////
        
    /**
     * @dev Ensure that only this contract can call these functions.
     */
    modifier onlyThis() {
        if (_msgSender() != address(this))
            revert OnlyThis();
        _;
    }

    /**
     * @dev Ensure that they key does not already exist.
     */
    modifier keyExists(
		address key
	) {
        if (_keys[_keysByAddress[key]].exists)
            revert KeyExists();
        _;
    }

    /**
     * @dev Ensure that the key exists.
     */
    modifier keyNotExist(
		address key
	) {
        if (!_keys[_keysByAddress[key]].exists)
            revert KeyDoesNotExists();
        _;
    }

    /**
     * @dev Ensure that the key has approved.
     */
    modifier keyNotApproved(
		uint256 txHash,
		address key
	) {
        if (!_approvalsByTransaction[_transactionsByHash[txHash]][key])
            revert KeyNotApproved();
        _;
    }

    /**
     * @dev Ensure that they key has not already approved.
     */
    modifier keyApproved(
		uint256 txHash,
		address key
	) {
        if (_approvalsByTransaction[_transactionsByHash[txHash]][key])
            revert KeyApproved();
        _;
    }

    /**
     * @dev Ensure that the key is not the zero address.
     */
    modifier keyZeroAddress(
		address key
	) {
        if (key == address(0))
            revert KeyZeroAddress();
        _;
    }

    /**
     * @dev Ensure the update results in keys on the account that are valid.
     */
    modifier validRequirement(
		uint8 keyCount,
        Permission permission
	) {
        if (
            MAX_KEY_COUNT <= keyCount &&
            keyCount <= REQUIRED &&
            REQUIRED == 0 &&
            keyCount == 0
        )
            revert InvalidRequirement();
        _;
    }

    //////////////////////////////////////////////
    // ADD | REMOVE | REPLACE KEY
    //////////////////////////////////////////////

    /**
     * @dev Adds a new key to the account. Transaction must be sent by this contract to itself.
     */
    function addKey(
		address key,
        Permission permission 
	)
        public
        onlyThis
        keyExists(key)
        keyZeroAddress(key)
        validRequirement(_keys.length + 1)
    {
        // Push to transaction array
        _keys.push(key);
        
        emit KeyAdded(key, uint8(permission));
    }

    /**
     * @dev Removes a key from the account. Transaction must be sent by this contract to itself.
     */
    function removeKey(
		address key
	)
        public
        onlyThis
        keyNotExist(key)
    {
        // Sanity checks
        require(1 < (_keys.length - 1), "Hyperbase: Cannot have zero keys");

        // Reset requirement
        if (_keys.length < REQUIRED)
            setRequirement(uint8(_keys.length - 1));
    
        // Delete key
        delete _keys[_keysByAddress[key]];

        // Event
        emit KeyRemoved(key);
    }

    /**
     * @dev Replaces an old key with a new key. Transaction must be sent by this contract to itself.
     */
    function replaceKey(
		address key,
		address newKey
	)
        public
        onlyThis
        keyNotExist(key)
        keyNotExist(newKey)
    {
        // Add key
        addKey(newKey);

        // Remove key
        removeKey(key);
    }

    //////////////////////////////////////////////
    // TRANSACTIONS
    //////////////////////////////////////////////

    /**
     * @dev Submit a transaction to execute on the account.
    */
    function submit(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
		public
        keyHasRequiredPermission(_msgSender(), targets, values, calldatas)
		returns (uint256)
	{
        // Sanity checks
        require(targets.length > 0, "Hyperbase: empty transaction");
        require(targets.length == values.length && values.length == calldatas.length, "Hyperbase: invalid transaction length");

        // Hash the tx
        uint256 txHash = getTransactionHash(targets, values, calldatas);

        Permission permission = getRequiredPermission(
            targets, values, calldatas
        );

        // Get the block times for now and transaction expiry
        uint64 submitted = block.number.toUint64();
        uint64 expires = submitted + getExpiryPeriod().toUint64();

        // If tx exsists then reset/update its fields
        if (0 < _transactionsByHash[txHash]) {

            _transactions[_transactionsByHash[txHash]].required = permission;
            _transactions[_transactionsByHash[txHash]].submitted = submitted;
            _transactions[_transactionsByHash[txHash]].expires = expires;

            _transactions[_transactionsByHash[txHash]].targets = targets;
            _transactions[_transactionsByHash[txHash]].values = values;
            _transactions[_transactionsByHash[txHash]].calldatas = calldatas;

            _transactions[_transactionsByHash[txHash]].status = Status.PENDING;

        } // Else create a new tx 
        else {
            // Create transaction
            Transaction memory transactionObj =  Transaction(
                permission,
                submitted,
                expires,
                targets,
                values,
                calldatas,
                Status.PENDING
            );

            // Push to transaction array
            _transactions.push(transactionObj);

            // Transactions by hash
            _transactionsByHash[txHash] = _transactions.length;
        }

        // Add tx to tx by status
        _transactionsByStatus[Status.PENDING].push(_transactionsByHash[txHash]);

        // Add the approval from the sender
        _approvalsByTransaction[_transactions.length][_msgSender()] = true;   

        // Event
        emit ExecutionRequested(txHash, targets, values, calldatas);

        // Call execute on the tx
        execute(targets, values, calldatas);

        return _transactions.length;
    }

    /**
     * @dev Approve a transaction with controlling key, intended as multi-factor auth rather than dedicated multisig.  
     */
    function approve(
        uint256 txHash, 
        bool approved
    )
        public
        keyNotExist(_msgSender())
        keyHasRequiredPermission(_msgSender(), _transactions[_transactionsByHash[txHash]].targets, _transactions[_transactionsByHash[txHash]].values, _transactions[_transactionsByHash[txHash]].calldatas)
        keyApproved(txHash, _msgSender())
        transactionNotExecuted(txHash)
        returns (uint256)
    {
        // Set approved
        _approvalsByTransaction[_transactionsByHash[txHash]][_msgSender()] = approved;   

        // Event
        emit Approved(_msgSender(), txHash, approved);

        // Call execute on the tx
        return execute(_transactions[txHash].targets, _transactions[txHash].values, _transactions[txHash].calldatas);
    }

    /**
     * @dev Allows a key to revoke an approval for a transaction.
     */
    function revokeApproval(
        uint256 txHash
    )
        public
        keyNotExist(_msgSender())
        keyNotApproved(txHash, _msgSender())
        transactionNotExecuted(txHash)
    {
        // Revoke approval
        _approvalsByTransaction[_transactionsByHash[txHash]][_msgSender()] = false;

        // Event 
        emit Revocation(_msgSender(), txHash);
    }

    /**
     * @dev Execute the transaction if can be executed.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
        public
        payable
        virtual
        keyNotExist(_msgSender())
        keyNotApproved(getTransactionHash(targets, values, calldatas), _msgSender())
        returns (uint256)
    {
        // Get the by hash
        uint256 txHash = getTransactionHash(targets, values, calldatas);
        
        if (REQUIRED[_transactions[_transactionsByHash[txHash]].required] <= getApprovalCount(txHash)) {

            // Execute the TX
            _execute(txHash, targets, values, calldatas);
                
            // Event
            emit Executed(txHash, targets, values, calldatas);

        }
    }

    //////////////////////////////////////////////
    // INTERNALS
    //////////////////////////////////////////////

    // Internal execute function 
    function _execute(
        uint256 txHash, /* txHash */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
        internal
        transactionPending(txHash)
        transactionNotExecuted(txHash)
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

    // Cancel a tx
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
        internal
        virtual
        returns (uint256)
    {
        // Get the hash
        uint256 txHash = getTransactionHash(targets, values, calldatas);

        // Get tx status
        Status status = _transactions[_transactionsByHash[txHash]].status;

        // Require transaction is in viable state
        require(status != Status.CANCELLED && status != Status.EXECUTED, "Hyperbase: transaction not active");

        // Update the transaction status
        _transactions[_transactionsByHash[txHash]].status = Status.CANCELLED;

        // Event
        // emit Canceled(txHash, targets, values, calldatas);

        return _transactionsByHash[txHash];
    }

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    function checkIsApproved(
        uint256 txHash
    )
        public
        returns (bool)
    {
        if (REQUIRED[_transactions[_transactionsByHash[txHash]].required] <= getApprovalCount(txHash))
            return true;
        else
            return false;
    }

    // Check key permissions
    function checkKeyHasPermission(
        address key,
        uint256 permission
    )
        public
        view
        returns(bool result)
    {
        if (permission <= uint8(_keys[_keysByAddress[key]].permission))
            return true;
        else
            return false;
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    function getExpiryPeriod()
        public
        view
        returns (uint256)
    {
        return EXPIRY_PERIOD;
    }
    
    function getMaxKeyCount()
        public
        view
        returns (uint256)
    {
        return MAX_KEY_COUNT;
    }
    
    // Return key details
    function getKey(
        address key
    )
        public
        view
        returns(address, Permission, bool)
    {
        return (_keys[_keysByAddress[key]].key, _keys[_keysByAddress[key]].permission, _keys[_keysByAddress[key]].exists);
    }

    function getKeyPermission(
        address key
    )
        public
        view
        returns(Permission)
    {
        return _keys[_keysByAddress[key]].permission;
    }

    function getKeysByPermission(
        uint256 _permission
    )
        public
        view
        returns(uint256[] memory _keys)
    {
        return _keysByPermission[_permission];
    }
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

    // Returns number of `_approvalsByTransaction` of a 
    function getApprovalCount(
        uint256 txHash
    )
        public
        view
        returns (uint8 approvalCount)
    {
        for (uint256 i = 0; i < _keys.length; i++)
            if (_approvalsByTransaction[_transactionsByHash[txHash]][_keys[i].key])
                approvalCount++;
    }

    // Returns total number of `_transactions` after filers are applied.
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

    // Returns array with `_key` addresses that confirmed 
    function getApprovals(
        uint256 txHash
    )
        public
        view
        returns (address[] memory approvalsByTransaction)
    {
        address[] memory _approvalsByTransactionTemp = new address[](_keys.length);
        uint8 approvalCount = 0;
        for (uint256 i = 0; i < _keys.length; i++) {
            if (_approvalsByTransaction[_transactionsByHash[txHash]][_keys[i].key]) {
                _approvalsByTransactionTemp[approvalCount] = _keys[i].key;
                approvalCount++;
            }
        }
        approvalsByTransaction = new address[](approvalCount);
        for (uint256 i = 0; i < approvalCount; i++)
            approvalsByTransaction[i] = _approvalsByTransactionTemp[i];
    }

    // Returns list of transaction IDs in defined range.
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

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    // Allows to change the number of _required _approvalsByTransaction. Transaction has to be sent by This.
    function setRequirement(
        uint8 required,
        Permission permission
    )
        public
        onlyThis
        validRequirement(_keys.length, required)
    {
        REQUIRED = required;
        emit RequirementChange(uint8(permission), required);
    }

    function setTransactionStatus(  
        uint256 txHash,
        Status status
    )
        public
    {   
        uint256 _transaction = _transactionsByHash[txHash];
        Status oldStatus = _transactions[_transaction].status;
        
        // Remove from current tx status
        for (uint256 i = 0; i < _transactionsByStatus[oldStatus].length; i++) 
            if (_transactionsByStatus[oldStatus][i] == _transaction)
                delete _transactionsByStatus[oldStatus][i];

        _transactions[_transaction].status = status;
        _transactionsByStatus[status].push(_transaction);

        // Event
        // #TODO
    }

}