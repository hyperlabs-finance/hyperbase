// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHyperbaseVerifiersRegistry {

  	////////////////
    // EVENTS
    ////////////////
    
    /**
     * @dev An account that is trusted to provide claims pertaining to certain topics (for example, kyc) has been added
     */
    event TrustedVerifierAdded(address indexed verifier, uint256[] claimTopics);
    
    /**
     * @dev Topics that the verifier is trusted to attest to have been updated 
     */
    event TrustedClaimTopicsUpdated(address indexed verifier, uint256[] trustedTopics);

    /**
     * @dev A trusted verifier has been removed completely
     */
    event TrustedVerifierRemoved(address indexed verifier);	

  	////////////////
    // ERRORS
    ////////////////

    /**
     * @dev Trusted Verifier already exists
     */
    error VerifierAlreadyExists();
    
    /**
     * @dev Verifier doesn't exist
     */
    error NonExistantVerifier();
    
    /**
     * @dev Trusted claim topics cannot be empty
     */
    error EmptyClaimTopics();
    
    //////////////////////////////////////////////
    // ADD | REMOVE VERIFIER
    //////////////////////////////////////////////

    function addTrustedVerifier(address verifier, uint256[] calldata trustedTopics) external returns (uint256);
    function removeTrustedVerifier(address verifier) external;
    function updateVerifierClaimTopics(address verifier, uint256[] calldata trustedTopics) external;

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    function checkIsVerifier(address verifier) external view returns (bool);
    function checkIsVerifierTrustedTopic(address verifier, uint256 topic) external view returns (bool);
	
}