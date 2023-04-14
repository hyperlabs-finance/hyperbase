// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/metatx/ERC2771Context.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import '../Interface/IHyperbase.sol';
import 'openzeppelin-contracts/contracts/utils/Timers.sol';
import 'openzeppelin-contracts/contracts/utils/Address.sol';
import 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

// #TODO: EXPIRED TRANSACTIONS

contract Hyperbase is IHyperbase, ERC2771Context {  

  	////////////////
    // USING
    ////////////////

    using Timers for Timers.BlockNumber;
    using SafeCast for uint256;

  	////////////////
    // ERRORS
    ////////////////
    
    // Key has already been added to the account
    error KeyAlreadyExists();

    // Key has not been added to the account
    error KeyDoesNotExists();

    // Transaction already has already been submitted
    error TransactionAlreadyExists();

    // Key has not approved the transaction
    error KeyNotApproved();

    // Key has already approved the transaction
    error KeyAlreadyApproved();

    // Transactionn has already been executed
    error TransactionAlreadyExecuted();

    // Key is zero address
    error KeyIsZeroAddress();

    // Key does not have permission for the transaction
    error KeyDoesNotHavePermission();

  	////////////////
    // CONSTANTS
    ////////////////

    // The token used for refunds
    address GAS_TOKEN;

    // Maximum keys
    uint8 MAX_KEY_COUNT = 8;

    // Expiry period in block time
    uint256 EXPIRY_PERIOD;

  	////////////////
    // STATE
    ////////////////

    address claimsRegistry;

    struct Key {
        address key;
        Permission permission;
        bool exists;
    }

	// All keys on the approvalCount
    Key[] public _keys;

    // Mapping from address to key index
    mapping(address => uint256) _keysByAddress;

    // Mapping from permission to key indexs
    mapping(uint256 => uint256[]) _keysByPermission;

    // Mapping from permission const to amount of sigs required
    mapping(Permission => uint256) _requiredByPermission;

    // Core transaction details
    struct Transaction {
        Permission required;
        uint64 submitted;
        uint64 expires;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        Status status;
    }

	// All _transactions from 
	Transaction[] private _transactions;

	// Mapping from transaction index to adress to approval status
    mapping(uint256 => mapping(address => bool)) public _approvalsByTransaction;

    // Mapping from id to _transactions index
    mapping(uint256 => uint256) _transactionsByHash;

    // Mapping from status to _transaction index
    mapping(Status => uint256[]) _transactionsByStatus;

  	////////////////
    // CONSTRUCTOR
    ////////////////
		
	constructor(
		address forwarder
	)
		ERC2771Context(forwarder)
	{
        // Create key
        Key memory key =  Key(
            _msgSender(),
            Permission.MANAGEMENT,
            true
        );

        // Push to transaction array
        _keys.push(key);

        _keysByAddress[_msgSender()] = _keys.length;
        
        // Update requirements for all op types
        _requiredByPermission[Permission.MANAGEMENT] = 1;
        _requiredByPermission[Permission.ACTION] = 1;
        _requiredByPermission[Permission.CLAIM] = 1;
	}

  	////////////////
    // MODIFIERS
    ////////////////
	
    modifier onlyThis() {
        require(_msgSender() == address(this));
        _;
    }

    modifier onlyManagement() {
        require(uint8(Permission.MANAGEMENT) <= uint8(_keys[_keysByAddress[_msgSender()]].permission));
        _;
    }

    modifier onlyAction() {
        require(uint8(Permission.ACTION) <= uint8(_keys[_keysByAddress[_msgSender()]].permission));
        _;
    }

    modifier onlyClaims() {
        require(uint8(Permission.CLAIM) <= uint8(_keys[_keysByAddress[_msgSender()]].permission));
        _;
    }

    modifier keyNotExist(
		address key
	) {
        if (_keys[_keysByAddress[key]].exists)
            revert KeyAlreadyExists();
        _;
    }

    modifier keyExist(
		address key
	) {
        if (!_keys[_keysByAddress[key]].exists)
            revert KeyDoesNotExists();
        _;
    }

    modifier transactionExist(
		uint256 txHash
	) {
        if (uint256(_transactions[_transactionsByHash[txHash]].required) == 0) 
            revert TransactionAlreadyExists();
        _;
    }

    modifier hasApproved(
		uint256 txHash,
		address key
	) {
        if (!_approvalsByTransaction[_transactionsByHash[txHash]][key])
            revert KeyNotApproved();
        _;
    }

    modifier notApproved(
		uint256 txHash,
		address key
	) {
        if (_approvalsByTransaction[_transactionsByHash[txHash]][key])
            revert KeyAlreadyApproved();
        _;
    }

    modifier notExecuted(
		uint256 txHash
	) {
        if (_transactions[_transactionsByHash[txHash]].status == Status.EXECUTED)
            revert TransactionAlreadyExecuted();
        _;
    }

    modifier notNull(
		address key
	) {
        if (key == address(0))
            revert KeyIsZeroAddress();
        _;
    }

    modifier keyHasRequiredPermission(
        address key,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) {
        if (uint8(getRequiredPermission(targets, values, calldatas)) < uint8(_keys[_keysByAddress[key]].permission))
            revert KeyDoesNotHavePermission();
        _;
    }

    modifier validRequirement(
		uint8 keyCount,
        Permission permission
	) {
        if (
            MAX_KEY_COUNT <= keyCount &&
            keyCount <= _requiredByPermission[permission] &&
            _requiredByPermission[permission] == 0 &&
            keyCount == 0
        )
            revert InvalidRequirement();
        _;
    }

    //////////////////////////////////////////////
    // ADD | REMOVE | REPLACE KEY
    //////////////////////////////////////////////

    // Allows to add a new key. Transaction has to be sent by This.
    function addKey(
		address key,
        Permission permission 
	)
        public
        onlyThis
        keyNotExist(key)
        notNull(key)
        validRequirement(_keys.length + 1, permission)
    {
        // Create key
        Key memory keyObj =  Key(
            key,
            permission,
            true
        );

        // Push to transaction array
        _keys.push(keyObj);
        
        emit KeyAdded(key, uint8(permission));
    }

    // Allows to remove an key. Transaction has to be sent by This.
    function removeKey(
		address key
	)
        public
        onlyThis
        keyExist(key)
    {
        // Sanity checks
        require(1 < (_keys.length - 1), "Hyperbase: Cannot have zero keys");

        Permission permission = _keys[_keysByAddress[key]].permission;

        // Reset requirement
        if (_keys.length < _requiredByPermission[permission])
            setRequirement(uint8(_keys.length - 1), permission);
    
        // Delete key
        delete _keys[_keysByAddress[key]];

        // Event
        emit KeyRemoved(key, uint8(permission));
    }

    // Replace key with a new key. Transaction has to be sent by This.
    function replaceKey(
		address key,
		address newKey
	)
        public
        onlyThis
        keyExist(key)
        keyNotExist(newKey)
    {
        // Add key
        addKey(newKey, _keys[_keysByAddress[key]].permission);

        // Remove key
        removeKey(key);
    }

    //////////////////////////////////////////////
    // TRANSACTIONS
    //////////////////////////////////////////////

    // Submit a transaction to execute on the account
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

    // Approve a transaction with controlling key, intended as multi-factor auth rather than dedicated multisig.  
    function approve(
        uint256 txHash, 
        bool approved
    )
        public
        keyExist(_msgSender())
        keyHasRequiredPermission(_msgSender(), _transactions[_transactionsByHash[txHash]].targets, _transactions[_transactionsByHash[txHash]].values, _transactions[_transactionsByHash[txHash]].calldatas)
        notApproved(txHash, _msgSender())
        notExecuted(txHash)
        returns (uint256)
    {
        // Set approved
        _approvalsByTransaction[_transactionsByHash[txHash]][_msgSender()] = approved;   

        // Event
        emit Approved(_msgSender(), txHash, approved);

        // Call execute on the tx
        return execute(_transactions[txHash].targets, _transactions[txHash].values, _transactions[txHash].calldatas);
    }

    // Allows an key to revoke a approval for a 
    function revokeApproval(
        uint256 txHash
    )
        public
        keyExist(_msgSender())
        hasApproved(txHash, _msgSender())
        notExecuted(txHash)
    {
        // Revoke approval
        _approvalsByTransaction[_transactionsByHash[txHash]][_msgSender()] = false;

        // Event 
        emit Revocation(_msgSender(), txHash);
    }

    // Execute the transaction if can be executed
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
        public
        payable
        virtual
        keyExist(_msgSender())
        hasApproved(getTransactionHash(targets, values, calldatas), _msgSender())
        notExecuted(getTransactionHash(targets, values, calldatas))
        returns (uint256)
    {
        // Get the by hash
        uint256 txHash = getTransactionHash(targets, values, calldatas);
        
        if (_requiredByPermission[_transactions[_transactionsByHash[txHash]].required] <= getApprovalCount(txHash)) {

            // Get the by hash
            uint256 txHash = getTransactionHash(targets, values, calldatas);

            // Require tx in appropriate state to be executed
            require(_transactions[_transactionsByHash[txHash]].status == Status.PENDING, "Hyperbase: can only execute");
                
            // Execute the TX
            _execute(txHash, targets, values, calldatas);

            // Update the transaction status
            _transactions[_transactionsByHash[txHash]].status = Status.EXECUTED;

            // Event
            emit Executed(txHash, targets, values, calldatas);

            return txHash;
        }
    }

    // Internal execute function 
    function _execute(
        uint256, /* txHash */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
        internal
    {
        string memory errorMessage = "Hyperbase: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
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
        if (_requiredByPermission[_transactions[_transactionsByHash[txHash]].required] <= getApprovalCount(txHash))
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

    // Returns the required permission
    function getRequiredPermission(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
        public
        view
        returns(Permission)
    {
        uint8 opType = 0;
        
        // Iterate through targets
        for (uint256 i = 0; i < targets.length; i++) {
            if (targets[i] == address(this))
                if (opType < uint8(Permission.MANAGEMENT))
                    return Permission.MANAGEMENT;
            if (targets[i] == address(claimsRegistry))
                if (opType < uint8(Permission.CLAIM))
                    opType = uint8(Permission.CLAIM);
            else 
                opType = uint8(Permission.CLAIM);
        }
        return Permission(opType);
    }

    // The transaction hash is is produced by hashing the `targets` array, the `values` array and the `calldatas` array.
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
        _requiredByPermission[permission] = required;
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