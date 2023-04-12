// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/metatx/MinimalForwarder.sol';
import 'openzeppelin-contracts/contracts/access/ownable.sol';

contract HyperbaseForwarder is MinimalForwarder, Ownable {

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
		address paymentToken,
		uint8 txFeePercentage
	)
	{
		_paymentToken = paymentToken;
		_txFeePercentage = txFeePercentage;
	}

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

	function setProtocolToken(
		address paymentToken
	)
		public
		onlyOwner
	{
		_paymentToken = paymentToken;
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