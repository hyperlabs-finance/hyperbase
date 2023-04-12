// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../Interface/IHyperbaseClaimRegistry.sol';
import 'openzeppelin-contracts/contracts/access/ownable.sol';
import 'openzeppelin-contracts/contracts/metatx/ERC2771Context.sol';

contract HyperbaseClaimRegistry is IHyperbaseClaimRegistry, ERC2771Context, Ownable {

  	////////////////
    // STATE
    ////////////////

    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
		address subject;
        string uri;
    }

    // Array of all claims
    Claim[] _claims;

    // Mapping from claim id to claim validity
    mapping(uint256 => bool) _claimValidity;

    // Mapping from subject address to claim id
    mapping(bytes32 => uint256) _claimByHash;
    
    // Mapping from address of subject to all claims to claim ids
    mapping(address => uint256[]) _claimsBySubject;
    
    // Mapping from subject address to topic to claim ids
    mapping(address => mapping(uint256 => uint256[])) _claimsByTopicBySubject; 

    // Mapping from issuer 
    mapping(address => uint256[]) _claimsByIssuer;
    
    // Mapping from subject address to topic to claim ids
    mapping(address => mapping(uint256 => uint256[])) _claimsByTopicByIssuer; 

    // Array of all trusted _verifiers i.e. kyc agents, etc
    address[] public _verifiers;

    // Mapping between a trusted verifier address and the corresponding topics it's trusted to verify i.e. Accredited, HNWI, etc.
    mapping(address => uint256[]) public _verifierTrustedTopics;

  	////////////////
    // MODIFIERS
    ////////////////

    // Require caller is claim isser 
    modifier onlyIssuer(uint256 claim) {
        if (_msgSender() != _claims[claim].issuer)
            revert NotIssuer();
        _;
    }

    // Require caller is claim isser or claim subject
    modifier onlyIssuerOrSubject(uint256 claim) {
        if (_msgSender() != _claims[claim].issuer || _msgSender() != _claims[claim].subject)
            revert NotIssuerOrSubject();
        _;
    }

    //////////////////////////////////////////////
    // ADD | REMOVE | REVOKE CLAIMS
    //////////////////////////////////////////////

    // Add a signed attestation
    function addClaim(
        uint256 topic,
        uint256 scheme,
	    address subject,
        string memory uri
    )
        public
        returns (uint256 claimId)
    {
        address issuer = _msgSender();

        Claim memory claim = Claim(
            topic,
            scheme,
            issuer,
            subject,
            uri
        );

        // Push to claims array
        _claims.push(claim);
    
        claimId = _claims.length;
        
        _claimValidity[claimId] = true;
        _claimByHash[keccak256(abi.encode(issuer, topic))] = claimId;
        _claims = claimId;
        _claimsBySubject[subject].push(claimId);
        _claimsByTopicBySubject[subject][topic].push(claimId);
        _claimsByIssuer[issuer].push(claimId);
        _claimsByTopicByIssuer[issuer][topic].push(claimId);

        // Event
        emit ClaimAdded(claimId, topic, scheme, issuer, subject, uri);
    }

    // Remove a claim 
    function revokeClaimByHash(
        bytes32 claimHash
    )
        public
        returns (bool success)
    {
        return revokeClaim(_claimByHash[claimHash]);
    }

    // Revoke a claim previously issued, the claim is no longer considered as valid after revocation.
    function revokeClaim(
        uint256 claim
    )
        public
        onlyIssuer(claim)
        returns(bool)
    {
        _claimValidity[claim] = false;

        return true;
    }

    // Remove a claim 
    function removeClaimByHash(
        bytes32 claimHash
    )
        public
        returns (bool success)
    {
        return removeClaim(_claimByHash[claimHash]);
    }

    // Remove a signed attestation 
    function removeClaim(
        uint256 claim
    )
        public
        onlyIssuer(claim)
        returns (bool success)
    {
        // Sanity checks
        if (_claims[claim].topic == 0)
            revert NonExistantClaim();

        delete _claimValidity[claim];
        delete _claimByHash[keccak256(abi.encode(_claims[claim].issuer, _claims[claim].topic))];

        delete _claimsBySubject[_claims[claim].subject];
        delete _claimsByTopicBySubject[_claims[claim].subject][_claims[claim].topic];
        delete _claimsByIssuer[_claims[claim].issuer];
        delete _claimsByTopicByIssuer[_claims[claim].issuer][_claims[claim].topic];

        // Events
        emit ClaimRemoved(
            claim,
            _claims[claim].topic,
            _claims[claim].scheme,
            _claims[claim].issuer,
            _claims[claim].subject,
            _claims[claim].uri
        );

        delete _claims[claim];

        return true;
    }
    
    //////////////////////////////////////////////
    // ADD | REMOVE VERIFIER
    //////////////////////////////////////////////

    // Add a trusted verifier
    function addTrustedVerifier(
        address verifier,
        uint256[] calldata trustedTopics
    )
        external
        onlyOwner
        returns (uint256)
    {
        // Sanity checks
        if (0 != _verifierTrustedTopics[verifier].length )
            revert VerifierAlreadyExists();
        if (0 == trustedTopics.length)
            revert EmptyClaimTopics();

        // Add verifier
        _verifiers.push(verifier);

        // Add trusted topics
        _verifierTrustedTopics[verifier] = trustedTopics;

        // Event
        emit TrustedVerifierAdded(verifier, trustedTopics);

        return _verifiers.length;
    }

    // Remove a trusted verifier 
    function removeTrustedVerifier(
        address verifier
    )
        external
        onlyOwner
    {
        // Sanity checks
        if (_verifierTrustedTopics[verifier].length == 0)
            revert NonExistantVerifier();

        // Iterate through and remove
        for (uint256 i = 0; i < _verifiers.length; i++)
            if (_verifiers[i] == verifier) {
                _verifiers[i] = _verifiers[_verifiers.length - 1];
                _verifiers.pop();
                break;
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
        onlyOwner
    {
        // Sanity checks
        if (0 == _verifierTrustedTopics[verifier].length)
            revert NonExistantVerifier();
        if (0 < trustedTopics.length)
            revert EmptyClaimTopics();

        // Update
        _verifierTrustedTopics[verifier] = trustedTopics;

        // Event
        emit TrustedClaimTopicsUpdated(verifier, trustedTopics);
    }
    
    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////
    
    // 
    function getClaimByHash(
        bytes32 hash
    )
        public 
        view
        returns(uint256)
    {
        return _claimByHash[hash];
    }

    // 
    function getClaimsBySubject(
        address subject
    )
        public 
        view
        returns(uint256[] memory)
    {
        return _claimsBySubject[subject];
    }

    // 
    function getClaimsSubjectTopic(
        address subject,
        uint256 topic
    )
        public 
        view
        returns(uint256)
    {
        return _claims[];
    }

    // 
    function getClaimsByIssuer(
        address issuer
    )
        public 
        view
        returns(uint256[] memory)
    {
        return _claimsByIssuer[issuer];
    }

    // 
    function getClaimsIssuerTopic(
        address issuer,
        uint256 topic
    )
        public 
        view
        returns(uint256)
    {
        return _claimsByIssuer[issuer][topic];
    }
    
    // Return all the fields for a claim by the subject address and the claim id (hash of topic and issuer)
    function getClaim(
        uint256 claim
    )
        public
        view
        returns (
            uint256,
            uint256,
            address,
            string memory
        )
    {
        return (
            _claims[claim].topic,
            _claims[claim].scheme,
            _claims[claim].issuer,
            _claims[claim].uri
        );
    }

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    // Checks if address is verifier
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

    // Account has claim topic
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

    // Checks if claim is valid by id.
    function checkIsClaimValidByHash(
        bytes32 hash
    )
        public
        view
        returns (bool claimValid)
    {
        return checkIsClaimValid(_claimByHash[hash]);
    }

    // Checks if a claim is valid.
    function checkIsClaimValid(
        uint256 claim
    )
        public
        view
        returns (bool claimValid)
    {
        if (_claimValidity[claim] && checkIsVerifier(_claims[claim].issuer) )
            if (checkIsVerifierTrustedTopic(_claims[claim].issuer, _claims[claim].topic))
                return true;

        return false;
    }

    // Returns revocation status of a claim.
    function checkIsClaimRevoked(
        uint256 claim
    )
        public
        view
        returns (bool)
    {
        return _claimValidity[claim];
    }

}