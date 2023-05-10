Sack off Hyperbase accounts

Sack off HyperDAO

For now, focus on a simple, unopinionated composable infrastructure




Restructure claims so as to be msg.sender rather than signed

Claim request, payment handler/wrapper for tx on-chain
    event ClaimRequested(uint256 claimId, uint256 topic, uint256 scheme, address issuer, address subject, string uri);

Subdomains for Hyperbase accounts (/ identities?)







	struct Topics {
		uint256 verifier; // Index of the verifier 
		uint256 expires; // Expiration date of apply stage
		
	}

	Topics[] _topics;

	
	uint256 _openTopics;
	
	
    struct Challenge {
        uint rewardPool;        // (remaining) Pool of tokens to be distributed to winning voters
        address challenger;     // Owner of Challenge
        bool resolved;          // Indication of if challenge is resolved
        uint stake;             // Number of tokens at stake for either party during challenge
        uint totalTokens;       // (remaining) Number of tokens used in voting by the winning side
        mapping(address => bool) tokenClaims; // Indicates whether a voter has claimed a reward yet
    }

	
    // Maps challengeIDs to associated challenge data
    mapping(uint => Challenge) public _challenges;





	// Allows a verifier to apply for a new topic they are trusted on
	function applyTopics(
		address verifier,
		uint256[] topics
	)
		public
		onlyVerifier(verifier)
	{

	}

	function _applyTopics(
		address verifier,
		uint256[] topics
	)
		public 
	{

	}