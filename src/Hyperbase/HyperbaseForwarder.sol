// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/metatx/MinimalForwarder.sol';
import 'openzeppelin-contracts/contracts/access/ownable.sol';

contract HyperbaseForwarder is MinimalForwarder {

  	////////////////
    // STATE
    ////////////////

	// The protocol token used to pay for transactions
	address _paymentToken;

	// Transaction fee 
    uint8 _txFeePercentage;
	
  	////////////////
    // CONSTRUCTOR
    ////////////////
		
	constructor(
		address protocolToken,
		uint8 txFeePercentage
	)
	{
		_protocolToken = protocolToken;
		_txFeePercentage = txFeePercentage;
	}

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

	function setProtocolToken(
		address protocolToken
	)
		public
		onlyOwner
	{
		_protocolToken = protocolToken;
	}

	function setTxFeePercentage(
		uint8 txFeePercentage
	)
		public
		onlyOwner
	{
		_txFeePercentage = txFeePercentage;
	}

    //////////////////////////////////////////////
    // OWNER FUNCTIONS
    //////////////////////////////////////////////

	// Withdraw funds
	function withdraw(
		uint256 amount, 
		address tokenAddress
	)
		public
		onlyOwner
	{
		// # TODO
	}

}