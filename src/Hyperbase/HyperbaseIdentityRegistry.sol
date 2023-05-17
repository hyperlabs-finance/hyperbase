// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherits
import '.././Interface/IHyperbaseIdentityRegistry.sol';

/**

    HyperbaseIdentityRegistry records key fields about user identities on-chain. This 
    will soon be updated so as to obfuscate the underlying accounts allowing claims to 
    be recorded on-chain without readily revealing information about the user the 
    pertain to.

 */

contract HyperbaseIdentityRegistry is IHyperbaseIdentityRegistry {
	
  	////////////////
    // STATE
    ////////////////
    
    /**
     * @dev Identity fields.
     */
    struct Identity {
		bool exists;
        Country country;
    }

    /**
     * @dev Array of all identities.
     */
	Identity[] public _identities;

    /**
     * @dev Mapping from address to identity index.
     */
    mapping(address => uint256) public _identitiesByAddress;

  	////////////////
    // MODIFIERS
    ////////////////

    /**
     * @dev Ensures that only the identity owner can call this function.
     */
	modifier onlyIdentity(
		uint256 identity
	) {
        if (_identitiesByAddress[msg.sender] != identity)
            revert OnlyIdentity();
		_;
	}

    //////////////////////////////////////////////
    // CREATE | DELETE IDENTITY
    //////////////////////////////////////////////

    /**
     * @dev Adds a new idenity to the identity registry. This is neccesary for identity-based interactions in the protocol.
     * @param account The account that for which the new identity is being is being added.
     * @param country The country of the new identity.
     */
    function newIdentity(
		address account, 
        uint16 country
    )
        public
		returns (uint256 identityId_)
    {
		// Create identity
		identityId_ = _createIdentity(account, country);

        // Event
	    emit IdentityRegistered(account, identityId_);
    }

    /**
     * @dev Internal function to create new identity.
     * @param account The account that for which the new identity is being is being added.
     * @param country The country of the new identity.
     */
	function _createIdentity(
		address account,
        uint16 country
    )
        internal
		returns (uint256)
    {
		// Create identity
        Identity memory _identity = Identity({
			exists: true,
            country: Country(country)
        });

        // Push identity
		_identities.push(_identity);

        // Update identity by address
        _identitiesByAddress[account] = _identities.length - 1;

        // Return identity
        return _identities.length - 1;
	}

    /**
     * @dev Removes an identity from the registry by address.
     * @param account The address of the identity.
     */
    function deleteIdentityByAddress(
        address account
    )
        public
	{
		deleteIdentity(_identitiesByAddress[account]);
    }

    /**
     * @dev Removes an identity from the registry.
     * @param identity The identity ID to remove.
     */
    function deleteIdentity(
        uint256 identity
    )
        public
		onlyIdentity(identity)
	{
        // Delete
        delete _identities[identity];

        // Event
    	emit IdentityRemoved(msg.sender, identity);
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    /**
     * @dev Updates the country associated with an identity.
     * @param identity The identity ID to update the country on.
     * @param country The new country for the account.
     */
    function setCountry(
        uint256 identity, 
        uint16 country
    )
        public
		onlyIdentity(identity)
    {
        // Update 
        _identities[_identitiesByAddress[msg.sender]].country = Country(country);

        // Event
	    emit CountryUpdated(msg.sender, country);
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    /**
     * @dev Returns the fields associated with an identity by the underlying address.
     * @param account The address of the account to return the identity on.
     */
	function getIdentityByAddress(
		address account
	)
		public
		view
		returns (bool, uint16)
	{
		return getIdentity(_identitiesByAddress[account]);
	}

    /**
     * @dev Returns all fields for an identity.
     * @param identity The ID of the identity.
     */
	function getIdentity(
		uint256 identity
	)
		public
		view
		returns (bool, uint16)
	{
		return (_identities[identity].exists, uint16(_identities[identity].country));
	}

    /**
     * @dev Returns the country associated with an identity by the underlying address
     * @param account The account to return the country of.
     */
    function getCountryByAddress(
        address account
    )
        public
        view
        returns (uint16)
    {
		return uint16(getCountry(_identitiesByAddress[account])); 
    }

    /**
     * @dev Returns the country of an identity
     * @param identity The ID of the identity to return the country of.
     */
	function getCountry(
		uint256 identity
	)
		public
		view
		returns (uint16)
	{
		return uint16(_identities[identity].country);
	}
}