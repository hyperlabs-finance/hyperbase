// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/tx/ERC2771Context.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import '../Interface/IHyperbase.sol';
import 'openzeppelin-contracts/contracts/utils/Timers.sol';
import 'openzeppelin-contracts/contracts/utils/Address.sol';

// #TODO: EXPIRED TRANSACTIONS

contract Hyperbase is IHyperbase, ERC2771Context, IERC20 {  

  	////////////////
    // USING
    ////////////////

    using Timers for Timers.BlockNumber;
    
  	////////////////
    // CONSTANTS
    ////////////////

    // 
    address GAS_TOKEN;

    // Maximum keys
    uint8 MAX_KEY_COUNT;

    // Expiry period in block time
    uint256 EXPIRY_PERIOD;

    // Determines what types of tx the key can submit/approve 
    enum Purpose {
        MANAGEMENT,
        ACTION,
        CLAIM
    }
    
    // Execution status
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

    struct Key {
        address key;
        Purpose purpose;
        bool exists;
    }

	// All keys on the acapprovalCount
    Key[] public _keys;

    // Mapping from 
    mapping (uint256 => uint256[]) _keysByPurpose;

    // Mapping from purpose const to amount of sigs required
    mapping(Purpose => uint256) _requiredByPurpose;

    // Core transaction details
    struct Transaction {
        Purpose required;
        Timers.BlockNumber submitted;
        Timers.BlockNumber expires;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        Status executed;
    }

	// All _transaction from 
	Transaction[] private _transaction;

	// Mapping from transaction index to adress to approval status
    mapping(uint256 => mapping(address => bool)) public _approvalsByTransaction;

    // Mapping from id to _transaction index
    mapping(uint256 => uint256) _transactionByHash;

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
            true,
            Purpose.MANAGEMENT
        );

        // Push to transaction array
        _keys.push(key);
        
        // Update requirements for all op types
        for (uint16 i = 0; i < _requirementsByKeyType.length; i++) {
            _requiredByPurpose[Purpose(i)] = 1;
        }
	}

  	////////////////
    // MODIFIERS
    ////////////////
	
    modifier onlyThis() {
        require(_msgSender() == address(this));
        _;
    }

    modifier onlyManagement() {
        require(uint8(Purpose.MANAGEMENT) =< uint8(_keys[_msgSender()].purpose));
        _;
    }

    modifier onlyAction() {
        require(uint8(Purpose.ACTION) =< uint8(_keys[_msgSender()].purpose));
        _;
    }

    modifier onlyClaims() {
        require(uint8(Purpose.CLAIMS) =< uint8(_keys[_msgSender()].purpose));
        _;
    }

    modifier keyDoesNotExist(
		address key
	) {
        require(!_keys[key].exists);
        _;
    }

    modifier keyExists(
		address key
	) {
        require(_keys[key].exists);
        _;
    }

    modifier transactionExists(
		uint256 txHash
	) {
        require(_transaction[_transactionByHash[txHash]].destination != 0);
        _;
    }

    modifier hasApproved(
		uint256 txHash,
		address key
	) {
        require(_approvalsByTransaction[_transactionByHash[txHash]][key]);
        _;
    }

    modifier notConfirmed(
		uint256 txHash,
		address key
	) {
        require(!_approvalsByTransaction[_transactionByHash[txHash]][key]);
        _;
    }

    modifier notExecuted(
		uint256 txHash
	) {
        require(!_transaction[_transactionByHash[txHash]].status);
        _;
    }

    modifier notNull(
		address _address
	) {
        require(_address != 0);
        _;
    }

    modifier validRequirement(
		uint8 keyCount,
		uint8 required
	) {
        require(
            keyCount <= _MAX_KEY_COUNT &&
            required <= keyCount &&
            required != 0 &&
            keyCount != 0
        );
        _;
    }

    //////////////////////////////////////////////
    // ADD | REMOVE | REPLACE KEY
    //////////////////////////////////////////////

    // Allows to add a new key. Transaction has to be sent by This.
    function addKey(
		address addr,
        Purpose purpose 
	)
        public
        onlyThis
        keyDoesNotExist(key)
        notNull(key)
        validRequirement(_keys.length + 1, _required)
    {
        // Create key
        Key memory key =  Key(
            addr,
            true,
            purpose
        );

        // Push to transaction array
        _keys.push(key);
        
        emit KeyAdded(key);
    }

    // Allows to remove an key. Transaction has to be sent by This.
    function removeKey(
		address key
	)
        public
        onlyThis
        keyExists(key)
    {
        // Sanity checks
        require(1 < _keys.length, "Hyperbase: Cannot have zero keys");
        
        // Delete key
        _keys[key].pop();

        // Reset requirement
        if (_required > _keys.length)
            setRequirement(_keys.length);

        // Event
        emit KeyRemoved(key);
    }

    // Replace key with a new key. Transaction has to be sent by This.
    function replaceKey(
		address key,
		address newKey
	)
        public
        onlyThis
        keyExists(key)
        keyDoesNotExist(newKey)
    {
        // Add key
        addKey(newKey, _keys[key].purpose);

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
        keyHasRequiredPurpose(_msgSender(), targets, values, calldatas)
		returns (uint256, uint256)
	{
        // Sanity checks
        require(targets.length > 0, "Hyperbase: empty transaction");
        require(targets.length == values.length == calldatas.length, "Hyperbase: invalid transaction length");

        // #TODO: require the key has appropriate permission levels to submit the tx

        // Hash the tx
        uint256 txHash = getTransactionHash(targets, values, calldatas);

        Purpose purpose = getRequiredPermissions(
            targets, values, calldatas
        );

        // Get the block times for now and transaction expiry
        uint64 submitted = block.number.toUint64();
        uint64 expires = submitted + getExpiryPeriod().toUint64();

        // If tx exsists then reset/update its fields
        if (0 < _transactionByHash[txHash]) {

            _transaction[_transactionByHash[txHash]].purpose = purpose;
            _transaction[_transactionByHash[txHash]].submitted = submitted;
            _transaction[_transactionByHash[txHash]].expires = expires;

            _transaction[_transactionByHash[txHash]].targets = targets;
            _transaction[_transactionByHash[txHash]].values = values;
            _transaction[_transactionByHash[txHash]].calldatas = calldatas;

            _transaction[_transactionByHash[txHash]].status = Status.PENDING;

        } // Else create a new tx 
        else {
            // Create transaction
            Transaction memory transaction =  Transaction(
                // #TODO: pass these params from forwarder 
                purpose
                submitted,
                expires,
                targets,
                values,
                calldatas
                Status.PENDING
            );

            // Push to transaction array
            _transactions.push(transaction);

            // Transactions by hash
            _transactionByHash[txHash] = _transactions.length;
        }

        // If the user has the approvals allow them to approve?

        // Add the approval from the sender
        _approvalsByTransaction[_transactions.length][_msgSender()] = true;   

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
        keyExists(_msgSender())
        keyHasRequiredPurpose(_msgSender(), _transactionByHash[txHash].targets, _transactionByHash[txHash].values, _transactionByHash[txHash].calldatas)
        hasNotApproved(txHash, _msgSender())
        notExecuted(txHash)
        returns (uint256)
    {
        // Set approved
        _approvalsByTransaction[_transactionByHash[txHash]][_msgSender()] = approved;   

        // Event
        emit Approved(_msgSender(), _txHash, approved);

        // Call execute on the tx
        return execute(_targets, _values, _calldatas);
    }

    // Allows an key to revoke a approval for a 
    function revokeApproval(
        uint256 txHash
    )
        public
        keyExists(_msgSender())
        hasApproved(txHash, _msgSender())
        notExecuted(txHash)
    {
        // Revoke approval
        _approvalsByTransaction[_transactionByHash[txHash]][_msgSender()] = false;

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
        keyExists(_msgSender())
        hasApproved(getTransactionHash(targets, values, calldatas), _msgSender())
        notExecuted(getTransactionHash(targets, values, calldatas))
        returns (bool)
    {
        // Get the by hash
        uint256 txHash = hashTransaction(targets, values, calldatas);
        
        if (_required =< _approvalsByTransaction[_transactionByHash[txHash]]) {

            // Get the by hash
            uint256 txHash = hashTransaction(targets, values, calldatas);

            // Require tx in appropriate state to be executed
            require(_transaction[_transactionByHash[txHash]].status == Status.PENDING, "Hyperbase: can only execute");
                
            // Execute the TX
            _execute(txHash, targets, values, calldatas);

            // Update the transaction status
            _transaction[_transactionByHash[txHash]].status = Status.EXECUTED;

            // Event
            emit TransactionExecuted(txHash);

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
        returns
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
        uint256 txHash = hashTransaction(targets, values, calldatas);

        // Get tx status
        Status status = _transaction[_transactionByHash[txHash]].status;

        // Require transaction is in viable state
        require(status != Status.CANCELLED && status != Status.EXPIRED && status != Status.EXECUTED, "Hyperbase: transaction not active");

        // Update the transaction status
        _transaction[_transactionByHash[txHash]].status = Status.CANCELLED;

        // Event
        emit TransactionCanceled(_transactionByHash[txHash]);

        return _transactionByHash[txHash];
    }

    // Internal function, handles refunding tx to the relay in erc20 protocol token
    function refundRelay(
        uint256 gasPrice,
        uint256 startGas
    )
        internal
    {
        if (gasPrice > 0) {
            
            // Calc gas
            uint256 amount = (startGas - gasleft()) * gasPrice;

            // If not set gas token
            if (GAS_TOKEN == address(0)) 
                address(msg.sender).transfer(amount);

            // Else ERC20 refund
            else 
                ERC20Token(GAS_TOKEN).transfer(msg.sender, amount);
        }
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
        uint256 approvals = 0;
        for (uint256 i = 0; i < _keys.length; i++) {
            if (_approvalsByTransaction[_txHash][_keys[i]])
                approvals++;
        }
        if (required < approvals) return true;
        else return false;
    }

    // Check key permissions
    function checkKeyHasPurpose(
        bytes32 key,
        uint256 purpose
    )
        public
        view
        returns(bool result)
    {
        bool isThere;
        if (_keys[key].key == 0)
            return false;
        isThere = _keys[key].purpose <= purpose;
        return isThere;
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    function getExpiryPeriod()
        returns (uint256)
    {
        return EXPIRY_PERIOD;
    }
    
    function getMaxKeyCount()
        returns (uint256)
    {
        return MAX_KEY_COUNT;
    }

    // Returns list of `_keys`.
    function getKeys()
        public
        view
        returns (address[])
    {
        return _keys;
    }
    
    // Return key details
    function getKey(
        address _key
    )
        public
        view
        returns(uint256, Purpose, bool)
    {
        return (_keys.key, _keys.purpose, _keys.exists);
    }


    function getKeyPurpose(
        address _key
    )
        public
        view
        returns(Purpose)
    {
        return (keys[_key].purpose);
    }

    function getKeysByPurpose(
        uint256 _purpose
    )
        public
        view
        returns(bytes32[] _keys)
    {
        return _keysByPurpose[_purpose];
    }

    // 
    function getRequiredPermissions(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
        public
        view
        returns(bytes32[] _keys)
    {
        
    }

    // The transaction hash is is produced by hashing the `targets` array, the `values` array and the `calldatas` array.
    function getTransactionHash(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
        public
        pure 
        override returns (uint256)
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
        for (uint256 i=0; i<_keys.length; i++)
            if (_approvalsByTransaction[_transactionByHash[txHash]][_keys[i]])
                approvalCount++;
    }

    // Returns total number of `_transaction` after filers are applied.
    function getTransactionCount(
        bool pending,
        bool executed
    )
        public
        view
        returns (uint8 approvalCount)
    {
        for (uint256 i=0; i< _length; i++)
            if (pending && !_transaction[i].status || executed && _transaction[i].status)
                approvalCount++;
    }

    // Returns array with `_key` addresses that confirmed 
    function getApprovals(
        uint256 txHash
    )
        public
        view
        returns (address[] approvalsByTransaction)
    {
        address[] memory _approvalsByTransactionTemp = new address[](_keys.length);
        uint8 approvalCount = 0;
        uint256 i;
        for (i=0; i<_keys.length; i++) {
            if (_approvalsByTransaction[_transactionByHash[txHash]][_keys[i]]) {
                _approvalsByTransactionTemp[approvalCount] = _keys[i];
                approvalCount++;
            }
        }
        approvalsByTransaction = new address[](approvalCount);
        for (i=0; i<approvalCount; i++)
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
        returns (uint256[] _txHashs)
    {
        uint256[] memory txHashsTemp = new uint256[](_length);
        uint8 approvalCount = 0;
        uint256 i;
        for (i=0; i<_length; i++) {
            if (pending && !_transaction[i].status || executed && _transaction[i].status) {
                txHashsTemp[approvalCount] = i;
                approvalCount++;
            }
        }
        _txHashs = new uint256[](to - from);
        for (i=from; i<to; i++)
            _txHashs[i - from] = txHashsTemp[i];
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    // Allows to change the number of _required _approvalsByTransaction. Transaction has to be sent by This.
    function setRequirement(
        uint8 required
    )
        public
        onlyThis
        validRequirement(_keys.length, required)
    {
        _required = required;
        emit RequirementChange(required);
    }

    /////////////////////////////////// LATER

	// #TODO: make fully cloneable
    // Contract constructor sets initial _keys and _required number of _approvalsByTransaction.
    function initialize(
		address[] keys,
		uint8 _required
	)
        public
        validRequirement(keys.length, _required)
    {
        for (uint256 i=0; i<keys.length; i++) {
            require(!_isKey[keys[i]] && keys[i] != 0);
        }
        _keys = keys;
    }

}