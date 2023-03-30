// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../Interface/IHyperbaseClaimRegistry.sol';

contract HyperbaseClaimRegistry is IHyperbaseClaimRegistry {

  	////////////////
    // STATE
    ////////////////
    
    mapping(address => mapping(bytes32 => Claim)) internal _claimsByIdBySubject;
    mapping(address => mapping(uint256 => bytes32[])) internal _claimIdsByTopicsBySubject; 
    mapping(bytes => bool) public _revokedBySig;

    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
		address subject;
        bytes sig;
        bytes data;
        string uri;
    }

    ////////////////////////////////////////////////////////////////
    // ADD | REMOVE | REVOKE CLAIMS
    ////////////////////////////////////////////////////////////////

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
        override
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

    function removeClaim(
        bytes32 claimId,
		address subject
    )
        public
        override
        returns (bool success)
    {
        uint256 topic = _claimsByIdBySubject[subject][claimId].topic;
        require(topic != 0, "NonExisting: There is no claim with this ID");

        uint claimIndex = 0;
        while (_claimIdsByTopicsBySubject[subject][topic][claimIndex] != claimId) {
            claimIndex++;
        }

        _claimIdsByTopicsBySubject[subject][topic][claimIndex] = _claimIdsByTopicsBySubject[subject][topic][_claimIdsByTopicsBySubject[subject][topic].length - 1];
        _claimIdsByTopicsBySubject[subject][topic].pop();

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
    
    ////////////////////////////////////////////////////////////////
    // GETTERS
    ////////////////////////////////////////////////////////////////
    
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
        if (checkIsClaimRevoked(sig) == false) {
            return true;
        }

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
        if (_revokedBySig[_sig]) {
            return true;
        }

        return false;
    }


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
        if (sig.length != 65) {
            return address(0);
        }

        // Divide the sig in r, s and v variables
        assembly {
            ra := mload(add(sig, 32))
            sa := mload(add(sig, 64))
            va := byte(0, mload(add(sig, 96)))
        }

        if (va < 27) {
            va += 27;
        }

        address recoveredAddress = ecrecover(dataHash, va, ra, sa);

        return (recoveredAddress);
    }

}