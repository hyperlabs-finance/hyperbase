// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHyperbaseIdentityRegistry {

  	////////////////
    // ERRORS
    ////////////////

	/**
	 * @dev Only the identity owner can call this function
	 */
    error OnlyIdentity();
	
  	////////////////
    // EVENTS
    ////////////////

	/**
	 * @dev A new identity has been added to the registry
	 */
    event IdentityRegistered(address indexed holderAddress, uint256 indexed identity);
	
	/**
	 * @dev An indentity has been removed from the registry
	 */
    event IdentityRemoved(address indexed holderAddress, uint256 indexed identity);
	
	/**
	 * @dev An identities country has been updated
	 */
    event CountryUpdated(address indexed holderAddress, uint16 indexed country);

  	////////////////
    // CONSTANTS
    ////////////////

	/**
	 * @dev Enumerated list of countries
	 */
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
	
    //////////////////////////////////////////////
    // CREATE | DELETE IDENTITY
    //////////////////////////////////////////////

    function newIdentity(address account, uint16 country) external returns (uint256 identityId_);
    function deleteIdentityByAddress(address account) external;
    function deleteIdentity(uint256 identity) external;
    
    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////
    
    // Update the country of an idenity 
    function setCountry(uint256 identity,  uint16 country) external;
    
    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

	function getIdentityByAddress(address account) external view returns (bool, uint16);
	function getIdentity(uint256 identity) external view returns (bool, uint16);
    function getCountry(uint256 identity) external view returns (uint16);
    function getCountryByAddress(address account) external view returns (uint16);

}