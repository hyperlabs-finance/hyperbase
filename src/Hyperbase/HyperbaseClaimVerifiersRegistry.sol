// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '.././Interface/IHyperbaseClaimVerifiersRegistry.sol';
import '.././Interface/IHyperbaseIdentityRegistry.sol';
import 'openzeppelin-contracts/contracts/access/ownable.sol';

// #TODOShould this be deployed with each contract instance or provide a central registry?
contract HyperbaseClaimVerifiersRegistry is IHyperbaseClaimVerifiersRegistry, Ownable {
    
  	////////////////
    // INTERFACES
    ////////////////
    
    IHyperbaseIdentityRegistry _identityRegistry;
    
  	////////////////
    // STATE
    ////////////////
    
    // Array of all trusted _verifiers i.e. kyc agents, etc
    address[] public _verifiers;

    // Mapping between a trusted verifier address and the corresponding topics it's trusted to verify i.e. Accredited, HNWI, etc.
    mapping(address => uint256[]) public _verifierTrustedTopics;

    /////////////////
    // CONSTRUCTOR
    ////////////////

  	constructor(
        address identityRegistry
    ) {
        _identityRegistry = IHyperbaseIdentityRegistry(identityRegistry);
    }

    //////////////////////////////////////////////
    // OWNER
    //////////////////////////////////////////////

    // Owner can add a trusted verifier
    function addTrustedVerifier(
        address verifier,
        uint256[] calldata trustedTopics
    )
        external
        override
        onlyOwner
    {
        // Sanity checks
        require(_verifierTrustedTopics[verifier].length == 0, "Trusted Verifier already exists");
        require(trustedTopics.length > 0, "Trusted claim topics cannot be empty");

        // Add verifier
        _verifiers.push(verifier);

        // Add trusted topics
        _verifierTrustedTopics[verifier] = trustedTopics;

        // Event
        emit TrustedVerifierAdded(verifier, trustedTopics);
    }

    // Owner can remove a trusted verifier 
    function removeTrustedVerifier(
        address verifier
    )
        external
        override
        onlyOwner
    {
        // Sanity checks
        require(_verifierTrustedTopics[verifier].length != 0, "Verifier doesn't exist");

        // Iterate through and remove
        for (uint256 i = 0; i < _verifiers.length; i++) {
            if (_verifiers[i] == verifier) {
                _verifiers[i] = _verifiers[_verifiers.length - 1];
                _verifiers.pop();
                break;
            }
        }

        // Delete from 
        delete _verifierTrustedTopics[verifier];

        // Event
        emit TrustedVerifierRemoved(verifier);
    }

    // Update the topics a verifier can verify on
    function updateVerifierClaimTopics(
        address verifier,
        uint256[] calldata trustedTopics
    )
        external
        override
        onlyOwner
    {
        // Sanity checks
        require(_verifierTrustedTopics[verifier].length != 0, "Verifier doesn't exist");
        require(trustedTopics.length > 0, "Claims topics cannot be empty");

        // Update
        _verifierTrustedTopics[verifier] = trustedTopics;

        // Event
        emit ClaimTopicsUpdated(verifier, trustedTopics);
    }
    
    //////////////////////////////////////////////
    // VERIFIERS
    //////////////////////////////////////////////

    // Checks if address is verifier
    function checkIsVerifier(
        address verifier
    )
        external
        view
        override
        returns (bool)
    {
        for (uint256 i = 0; i < _verifiers.length; i++) {
            if (_verifiers[i] == verifier) {
                return true;
            }
        }
        return false;
    }

    // Account has claim topic
    function checkIsVerifierTrustedTopic(
        address verifier,
        uint256 topic
    )
        external
        view
        override
        returns (bool)
    {
        // Iterate through checking for claim topic
        for (uint256 i = 0; i < _verifierTrustedTopics[verifier].length; i++) {
            if (_verifierTrustedTopics[verifier][i] == topic) {
                return true;
            }
        }
        return false;
    }
}