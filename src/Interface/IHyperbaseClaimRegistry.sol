// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHyperbaseClaimRegistry {
    
  	////////////////
    // ERRORS
    ////////////////

    // Only the claim issuer can call this function
    error NotIssuer();
    
    // Only the claim issuer or subject can call this function
    error NotIssuerOrSubject();
    
  	////////////////
    // EVENTS
    ////////////////

    // A claim has been added to the registry 
    event ClaimAdded(uint256 claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, address indexed subject, string uri);
    
    // A claim has been altered in the regsitry
    event ClaimChanged(uint256 claimId, uint256 topic, uint256 scheme, address issuer, address subject, string uri);
    
    // A claim has been removed form the registry
    event ClaimRemoved(uint256 claimId, uint256 topic, uint256 scheme, address issuer, address subject, string uri);

    // An account that is trusted to provide claims pertaining to certain topics (for example, kyc) has been added
    event TrustedVerifierAdded(address indexed verifier, uint256[] claimTopics);
    
    // Topics that the verifier is trusted to attest to have been updated 
    event TrustedClaimTopicsUpdated(address indexed verifier, uint256[] trustedTopics);
    
    // A trusted verifier has been removed completely
    event TrustedVerifierRemoved(address indexed verifier);
    
    // #TODO: 
    event ClaimRequested(uint256 claimId, uint256 topic, uint256 scheme, address issuer, address subject, string uri);

  	////////////////
    // ERRORS
    ////////////////

    // There is no claim with this ID
    error NonExistantClaim();

    // Trusted claim topics cannot be empty
    error EmptyClaimTopics();

    // Trusted Verifier already exists
    error VerifierAlreadyExists();

    // Verifier doesn't exist
    error NonExistantVerifier();
    
    //////////////////////////////////////////////
    // ADD | REMOVE | REVOKE CLAIMS
    //////////////////////////////////////////////

    // Add a claim that a subject account has a given attribute 
    function addClaim(uint256 topic, uint256 scheme, address subject, string memory uri) external returns (uint256 claimId);

    // Revoke a claim by hash 
    function revokeClaimByHash(bytes32 claimHash) external returns (bool success);

    // Revoking a claim keeping a recorded history of its existence but (most-likely) invalivating it for current interactions 
    function revokeClaim(uint256 claim) external returns(bool);

    // Remove a claim by hash
    function removeClaimByHash(bytes32 claimHash) external returns (bool success);

    // Completely remove a claim 
    function removeClaim(uint256 claim) external returns (bool success);
    
    //////////////////////////////////////////////
    // ADD | REMOVE VERIFIER
    //////////////////////////////////////////////

    // Add a trusted verifier
    function addTrustedVerifier(address verifier, uint256[] calldata trustedTopics) external;

    // Remove a trusted verifier 
    function removeTrustedVerifier(address verifier) external;

    // Update the topics a verifier can verify on
    function updateVerifierClaimTopics(address verifier, uint256[] calldata trustedTopics) external;
    
    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////
    
    // Returns a claim id by claim has (hash of topic and issuer) and the subject
    function getClaimByHash(bytes32 hash) external view returns(uint256);

    // Returns the ids of claims associated with subject address
    function getClaimsBySubject(address subject) external view returns(uint256);

    // Returns the claims for the subject by given topic 
    function getClaimsSubjectTopic(address subject, uint256 topic) external view returns(uint256);

    // Returns the ids of claims issued by issuer address
    function getClaimsByIssuer(address issuer) external view returns(uint256);

    // Returns the claims issued by given topic 
    function getClaimsIssuerTopic(address issuer, uint256 topic) external view returns(uint256);
    
    // Return all the fields for a claim by the subject address and the claim id (hash of topic and issuer)
    function getClaim(uint256 claim) external view returns ( uint256, uint256, address, string memory ); 

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    // Checks if claim is valid by id.
    function checkIsClaimValidByHash(bytes32 hash) external view returns (bool claimValid);

    // Checks if a claim is valid.
    function checkIsClaimValid(uint256 claim) external view returns (bool claimValid);

    // Returns revocation status of a claim.
    function checkIsClaimRevoked(uint256 claim) external view returns (bool);
    
    // Checks if address is verifier
    function checkIsVerifier(address verifier) external view returns (bool);

    // Account has claim topic
    function checkIsVerifierTrustedTopic(address verifier, uint256 topic) external view returns (bool);

}