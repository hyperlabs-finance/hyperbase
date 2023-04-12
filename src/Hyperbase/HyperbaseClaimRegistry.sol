// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../Interface/IHyperbaseClaimRegistry.sol';
import 'openzeppelin-contracts/contracts/access/ownable.sol';

contract HyperbaseClaimRegistry is IHyperbaseClaimRegistry, Ownable {

  	////////////////
    // STATE
    ////////////////

    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
		address subject;
        bytes sig;
        bytes data;
        string uri;
    }       

    // Mapping from subject address to claim id to claim
    mapping(address => mapping(bytes32 => Claim)) internal _claimsByIdBySubject;
    
    // Mapping from subject address to topic to claim ids
    mapping(address => mapping(uint256 => bytes32[])) internal _claimIdsByTopicsBySubject; 

    // Mapping from signature claim id to revoked bool
    mapping(bytes => bool) public _revokedBySig;

    // Array of all trusted _verifiers i.e. kyc agents, etc
    address[] public _verifiers;

    // Mapping between a trusted verifier address and the corresponding topics it's trusted to verify i.e. Accredited, HNWI, etc.
    mapping(address => uint256[]) public _verifierTrustedTopics;

    ////////////////////////////////////////////////////////////////
    // ADD | REMOVE | REVOKE CLAIMS
    ////////////////////////////////////////////////////////////////

    // Add a signed attestation
    function addClaim(
        uint256 topic,
        uint256 scheme,
        address issuer,
		address subject,
        bytes memory sig,
        bytes memory data,
        string memory uri
    )
        public
        returns (bytes32 claimRequestId)
    {
        bytes32 claimId = keccak256(abi.encode(issuer, topic));

        if (_claimsByIdBySubject[subject][claimId].issuer != issuer) {
            _claimIdsByTopicsBySubject[subject][topic].push(claimId);
            _claimsByIdBySubject[subject][claimId].topic = topic;
            _claimsByIdBySubject[subject][claimId].scheme = scheme;
            _claimsByIdBySubject[subject][claimId].issuer = issuer;
            _claimsByIdBySubject[subject][claimId].subject = subject;
            _claimsByIdBySubject[subject][claimId].sig = sig;
            _claimsByIdBySubject[subject][claimId].data = data;
            _claimsByIdBySubject[subject][claimId].uri = uri;

            // Event
            emit ClaimAdded(
                claimId,
                topic,
                scheme,
                issuer,
                subject,
                sig,
                data,
                uri
            );
        } else {
            _claimsByIdBySubject[subject][claimId].topic = topic;
            _claimsByIdBySubject[subject][claimId].scheme = scheme;
            _claimsByIdBySubject[subject][claimId].issuer = issuer;
            _claimsByIdBySubject[subject][claimId].subject = subject;
            _claimsByIdBySubject[subject][claimId].sig = sig;
            _claimsByIdBySubject[subject][claimId].data = data;
            _claimsByIdBySubject[subject][claimId].uri = uri;

            // Event
            emit ClaimChanged(
                claimId,
                topic,
                scheme,
                issuer,
                subject,
                sig,
                data,
                uri
            );
        }

        return claimId;
    }

    // Remove a signed attestation 
    function removeClaim(
        bytes32 claimId,
		address subject
    )
        public
        returns (bool success)
    {
        uint256 topic = _claimsByIdBySubject[subject][claimId].topic;
        if (topic == 0)
            revert NonExistantClaim();

        uint256 claimIndex = 0; 
        while (_claimIdsByTopicsBySubject[subject][topic][claimIndex] != claimId)
            claimIndex++;
        

        _claimIdsByTopicsBySubject[subject][topic][claimIndex] = _claimIdsByTopicsBySubject[subject][topic][_claimIdsByTopicsBySubject[subject][topic].length - 1];
        _claimIdsByTopicsBySubject[subject][topic].pop();

        // Events
        emit ClaimRemoved(
            claimId,
            _claimsByIdBySubject[subject][claimId].topic,
            _claimsByIdBySubject[subject][claimId].scheme,
            _claimsByIdBySubject[subject][claimId].issuer,
            _claimsByIdBySubject[subject][claimId].subject,
            _claimsByIdBySubject[subject][claimId].sig,
            _claimsByIdBySubject[subject][claimId].data,
            _claimsByIdBySubject[subject][claimId].uri
        );

        delete _claimsByIdBySubject[subject][claimId];

        return true;
    }

    // Revoke a claim previously issued, the claim is no longer considered as valid after revocation.
    function revokeClaim(
        bytes32 claimId,
        address subject
    )
        public
        override
        returns(bool)
    {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;
        string memory uri;

        (topic, scheme, issuer, sig, data, uri) = getClaim(claimId, subject);

        _revokedBySig[sig] = true;

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
        override
        onlyOwner
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
    }

    // Remove a trusted verifier 
    function removeTrustedVerifier(
        address verifier
    )
        external
        override
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
        override
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
    
    // Return all the fields for a claim by the subject address and the claim id (hash of topic and issuer)
    function getClaim(
        bytes32 claimId,
		address subject
    )
        public
        override
        view
        returns (
            uint256,
            uint256,
            address,
            bytes memory,
            bytes memory,
            string memory
        )
    {
        return (
            _claimsByIdBySubject[subject][claimId].topic,
            _claimsByIdBySubject[subject][claimId].scheme,
            _claimsByIdBySubject[subject][claimId].issuer,
            _claimsByIdBySubject[subject][claimId].sig,
            _claimsByIdBySubject[subject][claimId].data,
            _claimsByIdBySubject[subject][claimId].uri
        );
    }

    // Returns the claims of a given topic by subject address and topic 
    function getClaimIdsByTopic(
		address subject,
        uint256 topic
    )
        public
        override
        view
        returns(bytes32[] memory claimIds)
    {
        return _claimIdsByTopicsBySubject[subject][topic];
    }

    // #TODO: refactor for ERC-2771?
    // Get address from sig
    function getRecoveredAddress(
        bytes memory sig,
        bytes32 dataHash
    )
        public
        override
        pure
        returns (address addr)
    {
        bytes32 ra;
        bytes32 sa;
        uint8 va;

        // Check the sig length
        if (sig.length != 65)
            return address(0);

        // Divide the sig in r, s and v variables
        assembly {
            ra := mload(add(sig, 32))
            sa := mload(add(sig, 64))
            va := byte(0, mload(add(sig, 96)))
        }

        if (va < 27)
            va += 27;

        address recoveredAddress = ecrecover(dataHash, va, ra, sa);

        return (recoveredAddress);
    }

    ////////////////////////////////////////////////////////////////
    // CHECKS
    ////////////////////////////////////////////////////////////////

    // Checks if claim is valid by id.
    function checkIsClaimValidById(
        address subject,    
        bytes32 claimId
    )
        public
        override
        view
        returns (bool claimValid)
    {
        return checkIsClaimValid(_claimsByIdBySubject[subject][claimId].subject, _claimsByIdBySubject[subject][claimId].topic, _claimsByIdBySubject[subject][claimId].sig, _claimsByIdBySubject[subject][claimId].data);
    }

    // #TODO: this is basically redundant? Or is broken
    // Checks if a claim is valid.
    function checkIsClaimValid(
        address subject,
        uint256 topic,
        bytes memory sig,
        bytes memory data
    )
        public
        override
        view
        returns (bool claimValid)
    {
        bytes32 dataHash = keccak256(abi.encode(subject, topic, data));
        
        // Use abi.encodePacked to concatenate the message prefix and the message to sign.
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));

        // Recover address of data signer
        address recovered = getRecoveredAddress(sig, prefixedHash);

        // Take hash of recovered address
        bytes32 hashedAddr = keccak256(abi.encode(recovered));

        // Does the trusted identifier have they key which signed the user's claim?
        if (checkIsClaimRevoked(sig) == false)
            return true;

        return false;
    }

    // Returns revocation status of a claim.
    function checkIsClaimRevoked(
        bytes memory _sig
    )
        public
        override
        view
        returns (bool)
    {
        if (_revokedBySig[_sig])
            return true;

        return false;
    }
    
    // Checks if address is verifier
    function checkIsVerifier(
        address verifier
    )
        external
        view
        override
        returns (bool)
    {
        for (uint256 i = 0; i < _verifiers.length; i++)
            if (_verifiers[i] == verifier) {
                return true;
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
        for (uint256 i = 0; i < _verifierTrustedTopics[verifier].length; i++)
            if (_verifierTrustedTopics[verifier][i] == topic) {
                return true;
            }

        return false;
    }

}