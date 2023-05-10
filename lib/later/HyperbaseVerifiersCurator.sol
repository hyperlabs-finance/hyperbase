// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/access/Ownable.sol';
import '../Interface/IHyperbaseVerifiersCurator.sol';

// Curator manages the addition of verifiers to the verifiers registry via submission and voting

contract HyperbaseVerifiersCurator is IHyperbaseVerifiersCurator, Ownable {

	enum Status {
		REVIEWING;
		ACCEPTED;
		REJECTED;
	} 

	struct Verifiers {
		address verifier; // Account of verifier
		uint256 applied; // Application date
		uint256 expires; // Expiration date of apply stage
		Status status; 	// Current status of verifier
	}

	// Array of all verifiers applications
	Verifiers[] _verifiers;

	// Mapping from address 
	mapping(address => uint256) _verifiersByAddress;

	// Mapping from status to verifier
	mapping(Status => uint256) _verifiersByStatus;

  	////////////////
    // MODIFIERS
    ////////////////

    // Ensure the subject is a verifier
    modifier onlyVerifier(
		address verifier
	) {
        if (_verifiersByAddress[verifier].status != Status.ACCEPTED)
            revert NotVerifier();
        _;
    }

	// Ensure that the verifier elligible to (re-/) apply
	modifier elligibleApplicant(
		address verifier
	) {
		if (_verifiersByAddress[verifier].account == address(0) || _verifiersByAddress[verifier].status != Status.REJECTED)
			revert InelligibleApplicant();
		_;
	}

    //////////////////////////////////////////////
    // APPLY VERIFIER
    //////////////////////////////////////////////
	
	// Allows a verifier to start an application
    function applyVerifier(
		// #TODO evidence?
	)
		public
	{
		// Collect the payment
		// #TODO
		
        address verifier = _msgSender();

        Verifiers memory verifier = Verifiers(
            verifier,
			applied,
			expires,
			Status.REVIEWING
        );

        // Push to verifiers array
        _verifiers.push(verifier);

		_verifiersByStatus[Status.REVIEWING] = _verifiers.length;
		_verifiersByAddress[verifier] = _verifiers.length;



    }

	

}