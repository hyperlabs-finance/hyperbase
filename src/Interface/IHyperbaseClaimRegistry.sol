// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHyperbaseClaimRegistry {
    
  	////////////////
    // ERRORS
    ////////////////

    /**
     * @dev Only the claim issuer can call this function.
     */
    error NotIssuer();
    
    /**
     * @dev Only the claim issuer or subject can call this function.
     */
    error NotIssuerOrSubject();
    
  	////////////////
    // EVENTS
    ////////////////

    /**
     * @dev A claim has been added to the registry.
     */
    event ClaimAdded(uint256 claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, address indexed subject, string uri);
    
    /**
     * @dev A claim has been altered in the regsitry.
     */
    event ClaimChanged(uint256 claimId, uint256 topic, uint256 scheme, address issuer, address subject, string uri);
    
    /**
     * @dev A claim has been removed form the registry.
     */
    event ClaimRevoked(uint256 claimId);

    /**
     * @dev The verifiers registry has been updated.
     */
    event VerifiersUpdated(address indexed verifiersRegistrAddress);

  	////////////////
    // ERRORS
    ////////////////
    
    /**
     * @dev There is no claim with this ID
     */
    error NonExistantClaim();
    
    //////////////////////////////////////////////
    // ADD | REMOVE | REVOKE CLAIMS
    //////////////////////////////////////////////

    function addClaim(uint256 topic, uint256 scheme, address subject, string memory uri) external returns (uint256 claimId);
    function revokeClaim(uint256 claim) external returns(bool);
    
    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    function getClaimsBySubject(address subject) external view returns(uint256[] memory);
    function getClaimsSubjectTopic(address subject, uint256 topic) external view returns(uint256[] memory);
    function getClaimsByIssuer(address issuer) external view returns(uint256[] memory);
    function getClaimsIssuerTopic(address issuer, uint256 topic) external view returns(uint256[] memory);
    function getClaim(uint256 claim) external view returns (uint256, uint256, address, string memory); 

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    function checkIsClaimValid(uint256 claim) external view returns (bool claimValid);
    function checkIsClaimRevoked(uint256 claim) external view returns (bool);

}