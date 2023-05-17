// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherits
import 'openzeppelin-contracts/contracts/access/Ownable.sol';
import '../Interface/IHyperbaseClaimRegistry.sol';

// Interfaces
import '../Interface/IHyperbaseVerifiersRegistry.sol';

/**

    HyperbaseClaimRegistry is the central registry where users of the hypersurface protocol can add 
    claims about themselves and others. These claims are then check in credital-based interactions.
    Examples of such claims may be that an user is an accredited investor or that the are a citizen
    of a particular jurisdiction.

 */

contract HyperbaseClaimRegistry is IHyperbaseClaimRegistry, Ownable {

  	////////////////
    // INTERFACES
    ////////////////

    /**
     * @dev The registry of accounts that are authorised to provide claims on particular topics.
     */
    IHyperbaseVerifiersRegistry _verifiers;

  	////////////////
    // STATE
    ////////////////

    /**
     * @dev Records the neccesary fields for a claim. 
     */
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
		address subject;
        string uri;
    }

    /**
     * @dev Array of all claims.
     */
    Claim[] _claims;

    /**
     * @dev Mapping from claim ID to claim validity.
     */
    mapping(uint256 => bool) _claimValidity;

    /**
     * @dev Mapping from address of subject to all claims to claim IDs.
     */
    mapping(address => uint256[]) _claimsBySubject;

    /**
     * @dev Mapping from subject address to topic to claim IDs.
     */
    mapping(address => mapping(uint256 => uint256[])) _claimsByTopicBySubject; 

    /**
     * @dev Mapping from issuer.
     */
    mapping(address => uint256[]) _claimsByIssuer;

    /**
     * @dev Mapping from subject address to topic to claim IDs.
     */
    mapping(address => mapping(uint256 => uint256[])) _claimsByTopicByIssuer; 

  	////////////////
    // CONSTRUCTOR
    ////////////////
		
	constructor(
        address verifiers
	)
	{
        setVerifiers(verifiers);
    }

  	////////////////
    // MODIFIERS
    ////////////////

    /**
     * @dev Ensures the caller is claim isser. 
     */
    modifier onlyIssuer(uint256 claim) {
        if (_msgSender() != _claims[claim].issuer)
            revert NotIssuer();
        _;
    }

    /**
     * @dev Ensures the caller is claim isser or claim subject.
     */
    modifier onlyIssuerOrSubject(uint256 claim) {
        if (_msgSender() != _claims[claim].issuer || _msgSender() != _claims[claim].subject)
            revert NotIssuerOrSubject();
        _;
    }

    /**
     * @dev Ensures the claim exists.
     */
    modifier claimExists(uint256 claim) {
        if (_claims[claim].topic == 0)
            revert NonExistantClaim();
        _;
    }

    //////////////////////////////////////////////
    // ADD | REMOVE | REVOKE CLAIMS
    //////////////////////////////////////////////

    /**
     * @dev Add a claim that a subject account has a given attribute.
     * @param topic The topic the of the claim supports. 
     * @param scheme The scheme of the claim topic.
     * @param subject The user account the claim is about. 
     * @param uri The uri for any supporting data.
     */
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

    /**
     * @dev Revoking a claim keeping a recorded history of its existence but (most-likely) invalidating
     * it for future interactions.
     *
     * @param claim The uint claim ID to revoke.
     */
    function revokeClaim(
        uint256 claim
    )
        public
        onlyIssuer(claim)
        claimExists(claim)
        returns(bool)
    {
        _claimValidity[claim] = false;

        // Event
        emit ClaimRevoked(claim);

        return true;
    }
    
    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////
    
    /**
     * @dev Returns the IDs of claims associated with subject address.
     * @param subject The address of the subject that is being queried.
     */
    function getClaimsBySubject(
        address subject
    )
        public 
        view
        returns(uint256[] memory)
    {
        return _claimsBySubject[subject];
    }
    
    /**
     * @dev Returns the claims for the subject by given topic.
     * @param subject The address of the subject that is being queried.
     * @param topic The topic of the claim that is being queried.
     */
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

    /**
     * @dev Returns the IDs of claims issued by issuer address.
     * @param issuer The address of the claim issuer, typically a trusted verifier. 
     */
    function getClaimsByIssuer(
        address issuer
    )
        public 
        view
        returns(uint256[] memory)
    {
        return _claimsByIssuer[issuer];
    }

    /**
     * @dev Returns all the claims issued by an issuer for a given topic.
     * @param issuer The address of the claim issuer, typically a trusted verifier. 
     * @param topic The topic of the claim that is being sought after.
     */
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
    
    /**
     * @dev Return all the fields for a claim by the subject address and the claim ID
     * @param claim The ID of the claim to return fields for.
     */
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

    /**
     * @dev Checks if a claim is valid.
     * @param claim The ID of the claim to return fields for.
     */
    function checkIsClaimValid(
        uint256 claim
    )
        public
        view
        returns (bool claimValid)
    {
        if (_claimValidity[claim] && _verifiers.checkIsVerifier(_claims[claim].issuer))
            if (_verifiers.checkIsVerifierTrustedTopic(_claims[claim].issuer, _claims[claim].topic))
                return true;

        return false;
    }

    /**
     * @dev Returns revocation status of a claim.
     * @param claim The ID of the claim to return fields for.
     */
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
    // SETTERS
    //////////////////////////////////////////////
    
    /**
     * @dev Sets the address of the trusted claim verifiers registry.
     * @param verifiers Address of the verifiers registry.
     */
    function setVerifiers(
        address verifiers
    )
        public 
        onlyOwner
    {
        _verifiers = IHyperbaseVerifiersRegistry(verifiers);

        emit VerifiersUpdated(verifiers);
    }

}