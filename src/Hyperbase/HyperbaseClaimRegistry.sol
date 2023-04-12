// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../Interface/IHyperbaseClaimRegistry.sol';
import 'openzeppelin-contracts/contracts/metatx/ERC2771Context.sol';

contract HyperbaseClaimRegistry is IHyperbaseClaimRegistry, ERC2771Context {

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
    // CONSTRUCTOR
    ////////////////
		
	constructor(
		address forwarder
	)
		ERC2771Context(forwarder) 
	{
        _transferOwnership(_msgSender());
    }

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
        _claimsBySubject[subject].push(claimId);
        _claimsByTopicBySubject[subject][topic].push(claimId);
        _claimsByIssuer[issuer].push(claimId);
        _claimsByTopicByIssuer[issuer][topic].push(claimId);

        // Event
        emit ClaimAdded(claimId, topic, scheme, issuer, subject, uri);
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
        returns(uint256[] memory)
    {
        return _claimsByTopicBySubject[subject][topic];
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
        returns(uint256[] memory)
    {
        return _claimsByTopicByIssuer[issuer][topic];
    }
    
    // Return all the fields for a claim by the subject address and the claim id 
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

    //////////////////////////////////////////////
    // OWNABLE
    //////////////////////////////////////////////

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}