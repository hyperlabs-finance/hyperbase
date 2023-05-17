// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherits
import 'openzeppelin-contracts/contracts/access/Ownable.sol';
import '../Interface/IHyperbaseVerifiersRegistry.sol';

/**

    HyperbaseVerifiersRegistry records which accounts are "verifiers" and are trusted
    by users to provide high-risk claims that are used in credential-based interactions.
    These may include KYC agents or regulated broker dealers. The verifiers registry is
    seperated from the other contracts in the protocol so that it may be owned and controlled
    by a token curated registry. This design choice has been made (but yet to be implemented)
    in order to further decentralised control in the Hypersurface protocol, in order to ensure
    that no one group, not even Hypersurface, gets final say in terms of key decisions.  

 */

contract HyperbaseVerifiersRegistry is IHyperbaseVerifiersRegistry, Ownable {
	
  	////////////////
    // STATE
    ////////////////
    
    /**
     * @dev Array of all trusted _verifiers i.e. kyc agents, etc.
     */
    address[] public _verifiers;

    /**
     * @dev Mapping between a trusted verifier address and the corresponding topics it's trusted
     * to verify i.e. Accredited, HNWI, etc.
     */
    mapping(address => uint256[]) public _verifierTrustedTopics;

  	////////////////
    // MODIFIERS
    ////////////////

    /**
     * @dev Ensures the verifier does not already exist.
     * @param verifier The address of the trusted verifier.
     */
    modifier verifierNotExist(address verifier) {
        if (_verifierTrustedTopics[verifier].length != 0)
            revert VerifierAlreadyExists();
        _;
    }   

    /**
     * @dev Ensures the verifier already exists.
     * @param verifier The address of the trusted verifier.
     */
    modifier verifierExists(address verifier) {
        if (_verifierTrustedTopics[verifier].length == 0)
            revert NonExistantVerifier();
        _;
    }

    /**
     * @dev Ensures the submitted topics are not empty.
     * @param trustedTopics The claim topics to check the length of.
     */
    modifier notEmptyTopics(uint256[] memory trustedTopics) {
        if (trustedTopics.length == 0)
            revert EmptyClaimTopics();
        _;
    }
	
    //////////////////////////////////////////////
    // ADD | REMOVE VERIFIER
    //////////////////////////////////////////////

    /**
     * @dev Add a trusted verifier.
     * @param verifier The address of the trusted verifier to add.
     * @param trustedTopics The topics the verifier is trusted to make claims on.
     */
    function addTrustedVerifier(
        address verifier,
        uint256[] calldata trustedTopics
    )
        external
        onlyOwner
        verifierNotExist(verifier)
        notEmptyTopics(trustedTopics)
        returns (uint256)
    {
        // Add verifier
        _verifiers.push(verifier);

        // Add trusted topics
        _verifierTrustedTopics[verifier] = trustedTopics;

        // Event
        emit TrustedVerifierAdded(verifier, trustedTopics);

        return _verifiers.length;
    }

    /**
     * @dev Remove a trusted verifier.
     * @param verifier The address of the trusted verifier to remove.
     */
    function removeTrustedVerifier(
        address verifier
    )
        external
        verifierExists(verifier)
        onlyOwner
    {
        // Iterate through and remove
        for (uint256 i = 0; i < _verifiers.length; i++)
            if (_verifiers[i] == verifier)
                delete _verifiers[i];

        // Delete from 
        delete _verifierTrustedTopics[verifier];

        // Event
        emit TrustedVerifierRemoved(verifier);
    }

    /**
     * @dev Update the topics a verifier can verify on.
     * @param verifier The address of the trusted verifier to update.
     * @param trustedTopics The trusted topics to update the verifiers topics to.
     */
    function updateVerifierClaimTopics(
        address verifier,
        uint256[] calldata trustedTopics
    )
        external
        verifierExists(verifier)
        notEmptyTopics(trustedTopics)
        onlyOwner
    {
        // Update
        _verifierTrustedTopics[verifier] = trustedTopics;

        // Event
        emit TrustedClaimTopicsUpdated(verifier, trustedTopics);
    }
	
    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    /**
     * @dev Checks if address is a trusted verifier.
     * @param verifier The address of the trusted verifier to check exists.
     */
    function checkIsVerifier(
        address verifier
    )
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _verifiers.length; i++)
            if (_verifiers[i] == verifier)
                return true;
                
        return false;
    }

    /**
     * @dev Account has claim topic.
     * @param verifier The address of the trusted verifier to check the topic on.
     * @param topic The topic to check if the verifier is trusted to make claims about.
     */
    function checkIsVerifierTrustedTopic(
        address verifier,
        uint256 topic
    )
        public
        view
        returns (bool)
    {
        // Iterate through checking for claim topic
        for (uint256 i = 0; i < _verifierTrustedTopics[verifier].length; i++)
            if (_verifierTrustedTopics[verifier][i] == topic)
                return true;

        return false;
    }
}