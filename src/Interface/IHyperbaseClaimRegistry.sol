// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHyperbaseClaimRegistry {
    
  	////////////////
    // EVENTS
    ////////////////

    // A claim has been added to the registry 
    event ClaimAdded(bytes32 claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, address indexed subject, bytes signature, bytes data, string uri);
    
    // A claim has been altered in the regsitry
    event ClaimChanged(bytes32 claimId, uint256 topic, uint256 scheme, address issuer, address subject, bytes signature, bytes data, string uri);
    
    // A claim has been removed form the registry
    event ClaimRemoved(bytes32 claimId, uint256 topic, uint256 scheme, address issuer, address subject, bytes signature, bytes data, string uri);

    // An account that is trusted to provide claims pertaining to certain topics (for example, kyc) has been added
    event TrustedVerifierAdded(address indexed verifier, uint256[] claimTopics);
    
    // Topics that the verifier is trusted to attest to have been updated 
    event TrustedClaimTopicsUpdated(address indexed verifier, uint256[] trustedTopics);
    
    // A trusted verifier has been removed completely
    event TrustedVerifierRemoved(address indexed verifier);
    
    // #TODO: 
    event ClaimRequested(bytes32 claimId, uint256 topic, uint256 scheme, address issuer, address subject, bytes signature, bytes data, string uri);

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
    
    // Add a new signed attestation (claim) that a subject account has a given attribute 
    function addClaim(uint256 topic, uint256 scheme, address issuer, address subject, bytes memory signature, bytes memory data, string memory uri) external returns (bytes32 claimRequestId);
    
    // Remove a claim completely
    function removeClaim(bytes32 claimId, address subject) external returns (bool success);

    // Revoking a claim keeping a recorded history of its existence but (most-likely) invalivating it for current interactions 
    function revokeClaim(bytes32 claimId, address subject) external returns(bool);

    //////////////////////////////////////////////
    // ADD | REMOVE VERIFIER
    //////////////////////////////////////////////

    // Add a trusted verifier to the registry. Takes address of verifier and trusted topics. Addition and removal of verifiers is administered by the protocol operators. 
    function addTrustedVerifier(address verifier, uint256[] calldata trustedTopics) external;
    
    // Remove a trusted verifier from the registry completely. 
    function removeTrustedVerifier(address verifier) external;

    // Update the topics a verifier is authorised to verify
    function updateVerifierClaimTopics(address verifier, uint256[] calldata trustedTopics) external;

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    // Returns a claim by the claim id (hash of topic and issuer) and the subject
    function getClaim(bytes32 claimId, address subject) external view returns (uint256, uint256, address, bytes memory, bytes memory, string memory);
    
    // Returns all of the claim for the subject ids by the subject address and topic (for example, kyc)
    function getClaimIdsByTopic(address subject, uint256 topic) external view returns(bytes32[] memory claimIds);

    // Returns the address that signed claim by the signature and the hashed data
    function getRecoveredAddress(bytes memory sig, bytes32 dataHash) external pure returns (address addr);

    ////////////////////////////////////////////////////////////////
    // CHECKS
    ////////////////////////////////////////////////////////////////
    
    // Returns the validty of a claim taking the id and the subject address
    function checkIsClaimValidById(address subject, bytes32 claimId) external view returns (bool claimValid);
    
    // Returns the validty of a claim by comparing its recovered address by checking it has not been revoked
    function checkIsClaimValid(address subject, uint256 topic, bytes memory sig, bytes memory data) external view returns (bool claimValid);
    
    // Returns the validity of the claim and whether it has been revoked
    function checkIsClaimRevoked(bytes memory sig) external view returns (bool);
    
    // Returns the validity of the address in question as a verifier 
    function checkIsVerifier(address verifier) external view returns (bool);
    
    // Returns the validity of the topic as one that the verifier is trusted to submit claims on 
    function checkIsVerifierTrustedTopic(address verifier, uint256 topic) external view returns (bool);
    
}