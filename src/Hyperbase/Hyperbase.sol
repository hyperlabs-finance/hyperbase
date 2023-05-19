// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/metatx/ERC2771Context.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import './HyperbaseCore.sol';
import '../Interface/IHyperbase.sol';

// #TODO: EXPIRED TRANSACTIONS
// #TODO: sign multiple transactions in one

contract Hyperbase is IHyperbase, HyperbaseCore, ERC2771Context {  

  	////////////////
    // CONSTANTS
    ////////////////

    /**
    * @dev Maximum number of keys/devices on the account.
    */
    uint8 MAX_KEY_COUNT = 8;

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
    modifier keyNotExist(
		address key
	) {
        if (_keys[_keysByAddress[key]].exists)
            revert KeyExists();
        _;
    }

    /**
     * @dev Ensure that the key exists.
     */
    modifier keyExists(
		address key
	) {
        if (!_keys[_keysByAddress[key]].exists)
            revert KeyDoesNotExists();
        _;
    }

    /**
     * @dev Ensure that the key has approved.
     */
    modifier keyApproved(
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
    modifier keyNotApproved(
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
    modifier keyNotNull(
		address key
	) {
        if (key == address(0))
            revert KeyZeroAddress();
        _;
    }

    /**
     * @dev Ensure the update results in keys on the account that are valid.
     */
    modifier keyRequirementsValid(
		uint8 keyCount
	) {
        if (
            MAX_KEY_COUNT <= keyCount &&
            keyCount <= REQUIRED &&
            REQUIRED == 0 &&
            keyCount == 0
        )
            revert InkeyRequirementsValid();
        _;
    }

    //////////////////////////////////////////////
    // ADD | REMOVE | REPLACE KEY
    //////////////////////////////////////////////

    /**
     * @dev Adds a new key to the account. Transaction must be sent by this contract to itself.
     */
    function addKey(
		address key
	)
        public
        onlyThis
        keyNotExist(key)
        keyNotNull(key)
        keyRequirementsValid(_keys.length + 1)
    {
        // Push to transaction array
        _keys.push(key);
        
        emit KeyAdded(key);
    }

    /**
     * @dev Removes a key from the account. Transaction must be sent by this contract to itself.
     */
    function removeKey(
		address key
	)
        public
        onlyThis
        keyExists(key)
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
        keyExists(key)
        keyExists(newKey)
    {
        // Add key
        addKey(newKey);

        // Remove key
        removeKey(key);
    }

    //////////////////////////////////////////////
    // APPROVALS
    //////////////////////////////////////////////
    
    /**
     * @dev Approve a transaction with controlling key, intended as multi-factor auth rather than dedicated multisig.  
     */
    function approve(
        uint256 txHash, 
        bool approved
    )
        public
        keyExists(_msgSender())
        keyHasRequiredPermission(_msgSender())
        keyNotApproved(txHash, _msgSender())
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
        keyExists(_msgSender())
        keyApproved(txHash, _msgSender())
        transactionNotExecuted(txHash)
    {
        // Revoke approval
        _approvalsByTransaction[_transactionsByHash[txHash]][_msgSender()] = false;

        // Event 
        emit Revocation(_msgSender(), txHash);
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
        keyHasRequiredPermission(_msgSender())
		returns (uint256)
	{
        // Submit the tx
        _submit(targets, values, calldatas);

        // Event
        emit ExecutionRequested(txHash, targets, values, calldatas);

        // Call execute on the tx
        execute(targets, values, calldatas);

        return _transactions.length;
    }

    /**
     * @dev Wrapper to execute the transaction by the transaction fields.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    )
        public
        returns (uint256)
    {
        // Get the by hash
        uint256 txHash = getTransactionHash(targets, values, calldatas);

        // Execute
        execute(txHash);
    }

    /**
     * @dev Execute the transaction if can be executed.
     */
    function execute(
        uint256 txHash
    )
        public
        payable
        virtual
        keyExists(_msgSender())
        keyApproved(txHash, _msgSender())
        returns (uint256)
    {        
        if (REQUIRED <= getApprovalCount(txHash)) {

            // Execute the TX
            _execute(txHash, targets, values, calldatas);
                
            // Event
            emit Executed(txHash, targets, values, calldatas);
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
        if (REQUIRED <= getApprovalCount(txHash))
            return true;
        else
            return false;
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    function getMaxKeyCount()
        public
        view
        returns (uint256)
    {
        return MAX_KEY_COUNT;
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

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    // Allows to change the number of _required _approvalsByTransaction. Transaction has to be sent by This.
    function setRequirement(
        uint8 required
    )
        public
        onlyThis
        keyRequirementsValid(_keys.length, required)
    {
        REQUIRED = required;
        emit RequirementChange(required);
    }

}