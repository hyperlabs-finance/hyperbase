// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/metatx/ERC2771Context.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import '../Interface/IHyperbase.sol';

contract Hyperbase is IHyperbase, ERC2771Context, IERC20 {  
	
  	////////////////
    // CONSTANTS
    ////////////////

    uint constant public MAX_KEY_COUNT = 8;

  	////////////////
    // STATE
    ////////////////

	// All keys on the acapprovalCount
    address[] public _keys;

	// Mapping from address to is key bool y/n
    mapping(address => bool) public _isKey;

	// Sigantures required to execute tx
	uint8 _required  = 1;

    enum Executed {
        PENDING,
        CANCELLED,
        SUBMITTED,
        SUCEEDED,
        FAILED
    }

    struct Meta {
        uint256 gasPrice;
        address gasToken;
        
    }

    struct Transaction {
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        string description;
        Executed executed;
    }

	// All _transactions from 
	Transaction[] private _transactions;

	// Mapping from transaction id to adress to confirmation status
    mapping(uint256 => mapping(address => bool)) public _confirmations;

  	////////////////
    // CONSTRUCTOR
    ////////////////
		
	constructor(
		address forwarder
	)
		ERC2771Context(forwarder)
	{
		_keys.push(_msgSender());
		_isKey[_msgSender()] = true;
	}

  	////////////////
    // MODIFIERS
    ////////////////
	
    modifier onlyThis() {
        require(_msgSender() == address(this));
        _;
    }

    modifier keyDoesNotExist(
		address key
	) {
        require(!_isKey[key]);
        _;
    }

    modifier keyExists(
		address key
	) {
        require(_isKey[key]);
        _;
    }

    modifier transactionExists(
		uint256 transactionId
	) {
        require(_transactions[transactionId].destination != 0);
        _;
    }

    modifier hasApproved(
		uint256 transactionId,
		address key
	) {
        require(_confirmations[transactionId][key]);
        _;
    }

    modifier notConfirmed(
		uint256 transactionId,
		address key
	) {
        require(!_confirmations[transactionId][key]);
        _;
    }

    modifier notExecuted(
		uint256 transactionId
	) {
        require(!_transactions[transactionId].executed);
        _;
    }

    modifier notNull(
		address _address
	) {
        require(_address != 0);
        _;
    }

    modifier validRequirement(
		uint keyCount,
		uint8 _required
	) {
        require(keyCount <= MAX_KEY_COUNT
            && _required <= keyCount
            && _required != 0
            && keyCount != 0);
        _;
    }

    //////////////////////////////////////////////
    // ADD | REMOVE | REPLACE KEY
    //////////////////////////////////////////////

    // Allows to add a new key. Transaction has to be sent by This.
    function addKey(
		address key
	)
        public
        onlyThis
        keyDoesNotExist(key)
        notNull(key)
        validRequirement(_keys.length + 1, _required)
    {
        _isKey[key] = true;
        _keys.push(key);
        KeyAddition(key);
    }

    // Allows to remove an key. Transaction has to be sent by This.
    function removeKey(
		address key
	)
        public
        onlyThis
        keyExists(key)
    {
        _isKey[key] = false;
        for (uint i=0; i<_keys.length - 1; i++)
            if (_keys[i] == key) {
                _keys[i] = _keys[_keys.length - 1];
                break;
            }
        _keys.length -= 1;
        if (_required > _keys.length)
            setRequirement(_keys.length);
        KeyRemoval(key);
    }

    // Allows to replace an key with a new key. Transaction has to be sent by This.
    function replaceKey(
		address key,
		address newKey
	)
        public
        onlyThis
        keyExists(key)
        keyDoesNotExist(newKey)
    {
        for (uint i=0; i<_keys.length; i++)
            if (_keys[i] == key) {
                _keys[i] = newKey;
                break;
            }
        _isKey[key] = false;
        _isKey[newKey] = true;
        KeyRemoval(key);
        KeyAddition(newKey);
    }

    //////////////////////////////////////////////
    // TRANSACTIONS
    //////////////////////////////////////////////

    function submit(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    )
		public
		returns (uint256)
	{
        require(targets.length == values.length, "Hyperbase: invalid transaction length");
        require(targets.length == calldatas.length, "Hyperbase: invalid transaction length");
        require(targets.length > 0, "Hyperbase: empty transaction");

        // Create transaction
        Transaction memory transaction =  Transaction(
            targets,
            values,
            calldatas,
            memory description,
            Executed(0)
		);

        // Push to transaction array
        _transactions.push(transaction);

        // Add the confirmation from the sender
        _confirmations[_transactions.length][_msgSender()] = true;   

        // Call execute on the tx
        execute(targets, values, calldatas, descriptionHash);

        // 
        refundRelay(uint256 gasPrice, address gasToken)

        return _transactions.length;
    }

    function approve(
        uint256 transactionId, 
        bool approved
    )
        public
        keyExists(_msgSender())
        hasApproved(transactionId, _msgSender())
        notExecuted(transactionId)
        returns (uint256)
    {
        // Set approved
        _confirmations[_transactionId][_msgSender()] = approved;   

        // Call execute on the tx
        execute(_transactions.targets, _transactions.values, _transactions.calldatas, _transactions.descriptionHash);
    }

    // Allows an key to revoke a confirmation for a transaction.
    function revokeApproval(uint256 transactionId)
        public
        keyExists(_msgSender())
        hasApproved(transactionId, _msgSender())
        notExecuted(transactionId)
    {
        _confirmations[transactionId][_msgSender()] = false;
        Revocation(_msgSender(), transactionId);
    }

    // Execute the transaction if can be executed
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory cal  ldatas,
        bytes32 descriptionHash
    )
        public
        payable
        virtual
        keyExists(_msgSender())
        hasApproved(transactionId, _msgSender())
        notExecuted(transactionId)
        returns (uint256)
    {
        if (_required < ) {

            TransactionState status = state(transactionId);

            // What's this?

            require(status == TransactionState.Succeeded || status == TransactionState.Queued, "Hyperbase: transaction not successful");
            
            transactions[transactionId].executed = Executed();

            _execute(transactionId, targets, values, calldatas, descriptionHash);

            // Event
            emit TransactionExecuted(transactionId);

            return transactionId;
        }
    }

    // Internal execute function 
    function _execute(
        uint256, /* transactionId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        string memory errorMessage = "Hyperbase: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
    }

    
        



    


    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual returns (uint256) {
        uint256 transactionId = hashTransaction(targets, values, calldatas, descriptionHash);
        TransactionState status = state(transactionId);

        require(
            // #TODO, look at transaction expiration
            status != TransactionState.Canceled && status != TransactionState.Expired && status != TransactionState.Executed,
            "Hyperbase: transaction not active"
        );
        transactions[transactionId].canceled = true;

        emit TransactionCanceled(transactionId);

        return transactionId;
    }




    // Internal function, handles refunding metatx to the relay in erc20 protocol token
    function refundRelay(
        uint256 gasPrice,
        uint256 startGas,
        address gasToken
    )
        internal
    {
        // Refund gas used using contract held ERC20 tokens or ETH
        if (gasPrice > 0) {
            uint256 amount = 21000 + (startGas - gasleft());
            amount = amount * gasPrice;
            if (gasToken == address(0)) {
                address(msg.sender).transfer(amount);
            } else {
                ERC20Token(gasToken).transfer(msg.sender, amount);
            }
        }
    }

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    function checkIsApproved(
        uint256 transactionId
    )
        public
        returns (bool)
    {
        uint256 approvals = 0;
        for (uint256 i = 0; i < _keys.length; i++) {
            if (_confirmations[_transactionId][_keys[i]])
                approvals++;
        }
        if (required < approvals) return true;
        else return false;
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    // Returns number of _confirmations of a transaction.
    function getConfirmationCount(
        uint256 transactionId
    )
        public
        constant
        returns (uint8 approvalCount)
    {
        for (uint i=0; i<_keys.length; i++)
            if (_confirmations[transactionId][_keys[i]])
                approvalCount++;
    }

    // Returns total number of _transactions after filers are applied.
    function getTransactionCount(
        bool pending,
        bool executed
    )
        public
        constant
        returns (uint8 approvalCount)
    {
        for (uint i=0; i< _transactions.length; i++)
            if (pending && !_transactions[i].executed || executed && _transactions[i].executed)
                approvalCount++;
    }

    // Returns list of _keys.
    function getKeys()
        public
        constant
        returns (address[])
    {
        return _keys;
    }

    // Returns array with key addresses, which confirmed transaction.
    function getApprovals(
        uint256 transactionId
    )
        public
        constant
        returns (address[] confirmations)
    {
        address[] memory _confirmationsTemp = new address[](_keys.length);
        uint8 approvalCount = 0;
        uint i;
        for (i=0; i<_keys.length; i++)
            if (_confirmations[transactionId][_keys[i]]) {
                _confirmationsTemp[approvalCount] = _keys[i];
                approvalCount++;
            }
        confirmations = new address[](approvalCount);
        for (i=0; i<approvalCount; i++)
            confirmations[i] = _confirmationsTemp[i];
    }

    // Returns list of transaction IDs in defined range.
    function getTransactionIds(
        uint from,
        uint to,
        bool pending,
        bool executed
    )
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](_transaction.length);
        uint8 approvalCount = 0;
        uint i;
        for (i=0; i<_transaction.length; i++)
            if (   pending && !_transactions[i].executed
                || executed && _transactions[i].executed)
            {
                transactionIdsTemp[approvalCount] = i;
                approvalCount++;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    // Allows to change the number of _required _confirmations. Transaction has to be sent by This.
    function setRequirement(
        uint8 _required
    )
        public
        onlyThis
        validRequirement(_keys.length, _required)
    {
        _required = _required;
        emit RequirementChange(_required);
    }


    /////////////////////////////////// LATER

	// #TODO, make fully cloneable
    // Contract constructor sets initial _keys and _required number of _confirmations.
    function initialize(
		address[] keys,
		uint8 _required
	)
        public
        validRequirement(keys.length, _required)
    {
        for (uint i=0; i<keys.length; i++) {
            require(!_isKey[keys[i]] && keys[i] != 0);
        }
        _keys = keys;
    }

}