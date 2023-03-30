// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '.././Interface/IHyperbaseIdentityRegistry.sol';

contract HyperbaseIdentityRegistry is IHyperbaseIdentityRegistry {

  	////////////////
    // STATE
    ////////////////

    // Enumerated list of countries
	enum Country {
		Afghanistan,
		Albania,
		Algeria,
		Andorra,
		Angola,
		Antigua_and_Deps,
		Argentina,
		Armenia,
		Australia,
		Austria,
		Azerbaijan,
		Bahamas,
		Bahrain,
		Bangladesh,
		Barbados,
		Belarus,
		Belgium,
		Belize,
		Benin,
		Bhutan,
		Bolivia,
		Bosnia_Herzegovina,
		Botswana,
		Brazil,
		Brunei,
		Bulgaria,
		Burkina,
		Burundi,
		Cambodia,
		Cameroon,
		Canada,
		Cape_Verde,
		Central_African_Rep,
		Chad,
		Chile,
		China,
		Colombia,
		Comoros,
		Congo,
		Congo_Democratic_Rep,
		Costa_Rica,
		Croatia,
		Cuba,
		Cyprus,
		Czech_Republic,
		Denmark,
		Djibouti,
		Dominica,
		Dominican_Republic,
		East_Timor,
		Ecuador,
		Egypt,
		El_Salvador,
		Equatorial_Guinea,
		Eritrea,
		Estonia,
		Ethiopia,
		Fiji,
		Finland,
		France,
		Gabon,
		Gambia,
		Georgia,
		Germany,
		Ghana,
		Greece,
		Grenada,
		Guatemala,
		Guinea,
		Guinea_Bissau,
		Guyana,
		Haiti,
		Honduras,
		Hungary,
		Iceland,
		India,
		Indonesia,
		Iran,
		Iraq,
		Ireland,
		Israel,
		Italy,
		Ivory_Coast,
		Jamaica,
		Japan,
		Jordan,
		Kazakhstan,
		Kenya,
		Kiribati,
		Korea_North,
		Korea_South,
		Kosovo,
		Kuwait,
		Kyrgyzstan,
		Laos,
		Latvia,
		Lebanon,
		Lesotho,
		Liberia,
		Libya,
		Liechtenstein,
		Lithuania,
		Luxembourg,
		Macedonia,
		Madagascar,
		Malawi,
		Malaysia,
		Maldives,
		Mali,
		Malta,
		Marshall_Islands,
		Mauritania,
		Mauritius,
		Mexico,
		Micronesia,
		Moldova,
		Monaco,
		Mongolia,
		Montenegro,
		Morocco,
		Mozambique,
		Myanmar,
		Namibia,
		Nauru,
		Nepal,
		Netherlands,
		New_Zealand,
		Nicaragua,
		Niger,
		Nigeria,
		Norway,
		Oman,
		Pakistan,
		Palau,
		Panama,
		Papua_New_Guinea,
		Paraguay,
		Peru,
		Philippines,
		Poland,
		Portugal,
		Qatar,
		Romania,
		Russian_Federation,
		Rwanda,
		St_Kitts_and_Nevis,
		St_Lucia,
		Saint_Vincent_and_the_Grenadines,
		Samoa,
		San_Marino,
		Sao_Tome_and_Principe,
		Saudi_Arabia,
		Senegal,
		Serbia,
		Seychelles,
		Sierra_Leone,
		Singapore,
		Slovakia,
		Slovenia,
		Solomon_Islands,
		Somalia,
		South_Africa,
		South_Sudan,
		Spain,
		Sri_Lanka,
		Sudan,
		Suriname,
		Swaziland,
		Sweden,
		Switzerland,
		Syria,
		Taiwan,
		Tajikistan,
		Tanzania,
		Thailand,
		Togo,
		Tonga,
		Trinidad_and_Tobago,
		Tunisia,
		Turkey,
		Turkmenistan,
		Tuvalu,
		Uganda,
		Ukraine,
		United_Arab_Emirates,
		United_Kingdom,
		United_States,
		Uruguay,
		Uzbekistan,
		Vanuatu,
		Vatican_City,
		Venezuela,
		Vietnam,
		Yemen,
		Zambia,
		Zimbabwe
	}

    // Identity fields
    struct Identity {
		bool exists;
        Country country;
		// #TODO any more pertinant fields? Hashed name for example?
    }

	// Array of identities
	Identity[] public _identities;

    // Mapping from address to identity index
    mapping(address => uint256) public _identitiesByAddress;

  	////////////////
    // MODIFIERS
    ////////////////

	modifier onlyIdentity(
		uint256 identity
	) {
        require(_identitiesByAddress[msg.sender] == identity, "Only the owner of an identity can make changes to it");
		_;
	}

    //////////////////////////////////////////////
    // CREATE / DELETE IDENTITY
    //////////////////////////////////////////////

    // Register new identity
    function newIdentity(
		address account, 
        uint16 country
    )
        public
		override
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
        override
	{
		deleteIdentity(_identitiesByAddress[account]);
    }

    // Removes an identity from the registry
    function deleteIdentity(
        uint256 identity
    )
        public
        override
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
        override
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

	function getIdentity(
		uint256 identity
	)
		public
		view
		override
		returns (bool, uint16)
	{
		return (
			_identities[identity].exists,
			uint16(_identities[identity].country)
		);
	}

	function getCountry(
		uint256 identity
	)
		public
		view
		override
		returns (uint16)
	{
		return uint16(_identities[identity].country);
	}
	
	// Returns the fields associated with an identity
	function getIdentityByAddress(
		address account
	)
		public
		view
		override
		returns (bool, uint16)
	{
		return getIdentity(_identitiesByAddress[account]);
	}

	// Returns the country associated with an identity
    function getCountryByAddress(
        address account
    )
        public
        view
        override
        returns (uint16)
    {
		return uint16(getCountry(_identitiesByAddress[account])); 
    }

}