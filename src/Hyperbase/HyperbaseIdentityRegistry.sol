// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '.././Interface/IHyperbaseIdentityRegistry.sol';

contract HyperbaseIdentityRegistry is IHyperbaseIdentityRegistry {
	
  	////////////////
    // STATE
    ////////////////

    // Identity fields
    struct Identity {
		bool exists;
        Country country;
		// #TODO any more pertinant fields to include? Hashed name for example? Multiple accounts on an identity?
    }

	// Array of identities
	Identity[] public _identities;

    // Mapping from address to identity index
    mapping(address => uint256) public _identitiesByAddress;

  	////////////////
    // MODIFIERS
    ////////////////

    // Ensure that only the identity owner can call this function
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

    // Register new identity
    function newIdentity(
		address account, 
        uint16 country
    )
        public
		returns (uint256)
    {
		// Create identity
		uint256 identityId = _createIdentity(account, country);

        // Event
	    emit IdentityRegistered(account, identityId);
    }

	// Internal function to create new identity
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

    // Removes an identity from the registry by address
    function deleteIdentityByAddress(
        address account
    )
        public
	{
		deleteIdentity(_identitiesByAddress[account]);
    }

    // Removes an identity from the registry
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

    // Updates the country associated with an identity
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

	// Returns the fields associated with an identity by the underlying address
	function getIdentityByAddress(
		address account
	)
		public
		view
		returns (bool, uint16)
	{
		return getIdentity(_identitiesByAddress[account]);
	}

	// Returns all fields for an identity 
	function getIdentity(
		uint256 identity
	)
		public
		view
		returns (bool, uint16)
	{
		return (_identities[identity].exists, uint16(_identities[identity].country));
	}

	// Returns the country associated with an identity by the underlying address
    function getCountryByAddress(
        address account
    )
        public
        view
        returns (uint16)
    {
		return uint16(getCountry(_identitiesByAddress[account])); 
    }

	// Returns the country of an identity
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