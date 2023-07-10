// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/metatx/ERC2771Context.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import './HyperbaseCore.sol';
import '../Interface/IHyperbase.sol';

/**

  	Hyperbase handles key management for the smart contract account, functioning
    like a multi-signature wallet. Each key for the wallet is a context-specific key
    pair stored locally on the users device. When new devices are added a key is 
    created locally and permission is requested from another key on the account to 
    add the new device/key to the Hyperbase account.

 */

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
    address[] public _keys;

    /**
    * @dev Mapping from address to key index.
    */
    mapping(address => uint256) _keysByAddress;

    /**
    * @dev Mapping from key address to exists status.
    */
    mapping(address => bool) _keyExistsByAddress;

    /**
    * @dev Mapping from transaction hash to adress to approval status.
    */
    mapping(uint256 => mapping(address => bool)) private _approvalsByTransactionHash;

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

        _keysByAddress[_msgSender()] = _keys.length - 1;
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
        if (_keyExistsByAddress[key])
            revert KeyExists();
        _;
    }

    /**
     * @dev Ensure that the key exists.
     */
    modifier keyExists(
		address key
	) {
        if (!_keyExistsByAddress[key])
            revert KeyDoesNotExist();
        _;
    }

    /**
     * @dev Ensure that the key has approved.
     */
    modifier keyApproved(
		uint256 txHash,
		address key
	) {
        if (!_approvalsByTransactionHash[txHash][key])
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
        if (_approvalsByTransactionHash[txHash][key])
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
		uint8 required
	) {
        if (MAX_KEY_COUNT <= _keys.length || _keys.length <= required || required == 0 || _keys.length == 0)
            revert KeyRequirementInvalid();
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
        keyRequirementsValid(uint8(_keys.length + 1))
    {
        // Push to transaction array
        _keys.push(key);

        // Key exists
        _keyExistsByAddress[key] = true;
        
        // Event
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

        // Key exists
        _keyExistsByAddress[key] = false;

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
        uint256 txHash
    )
        public
        keyExists(_msgSender())
        keyNotApproved(txHash, _msgSender())
        transactionPending(txHash)
    {
        // Set approved
        _approvalsByTransactionHash[txHash][_msgSender()] = true;   

        // Event
        emit Approved(_msgSender(), txHash);

        // Call execute on the tx
        execute(txHash);
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
        transactionPending(txHash)
    {
        // Revoke approval
        _approvalsByTransactionHash[txHash][_msgSender()] = false;

        // Event 
        emit Revoked(_msgSender(), txHash);
    }

    /**
     * @dev Resets the transaction approvals when calling a repeat tx.
     */
    function _resetApproval(
        uint256 txHash
    )
        internal
    {
        // If tx already exists
        if (_transactionsByHash[txHash].exists)
            // Iterate through all keys on the account and set as false
            for (uint8 i = 0; i < _keys.length; i++)
                _approvalsByTransactionHash[txHash][_keys[i]] = false;       
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
		returns (uint256 txHash)
	{
        // Submit the tx
        txHash = _submit(targets, values, calldatas);

        // Reset the tx
        _resetApproval(txHash);

        // Approve the tx from the sender
        approve(txHash);

        // Event
        emit Submitted(txHash, targets, values, calldatas);

        // Call execute on the tx
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
    {        
        // If approved, execute
        if (REQUIRED <= getApprovalCount(txHash)) {

            // Execute the TX
            _execute(txHash);
                
            // Event
            emit Executed(txHash, _transactionsByHash[txHash].targets, _transactionsByHash[txHash].values, _transactionsByHash[txHash].calldatas);
        }
    }

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    /**
     * @dev Returns boolean as to if the transaction has been approved.
     */
    function checkIsApproved(
        uint256 txHash
    )
        public
        view
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

    /**
     * @dev Returns The maximum number of keys that can be added to the account.
     */
    function getMaxKeyCount()
        public
        view
        returns (uint256)
    {
        return MAX_KEY_COUNT;
    }
    
    /**
     * @dev Returns number of `_approvalsByTransactionHash` for a transaction.
     */
    function getApprovalCount(
        uint256 txHash
    )
        public
        view
        returns (uint8 approvalCount)
    {
        for (uint256 i = 0; i < _keys.length; i++)
            if (_approvalsByTransactionHash[txHash][_keys[i]])
                approvalCount++;
    }
    
    /**
     * @dev Returns array with `_key` addresses that confirmed.
     */
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
            if (_approvalsByTransactionHash[txHash][_keys[i]]) {
                _approvalsByTransactionTemp[approvalCount] = _keys[i];
                approvalCount++;
            }
        }
        approvalsByTransaction = new address[](approvalCount);
        for (uint256 i = 0; i < approvalCount; i++)
            approvalsByTransaction[i] = _approvalsByTransactionTemp[i];
    }

    /**
     * @dev Returns array with `_key` addresses.
     */
    function getKeys()
        public
        view
        returns (address[] memory)
    {
        return _keys;
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    /**
     * @dev Changes the number of required approvals to execute a transaction.
     */
    function setRequirement(
        uint8 required
    )
        public
        onlyThis
        keyRequirementsValid(required)
    {
        REQUIRED = required;

        emit RequirementChange(required);
    }

}