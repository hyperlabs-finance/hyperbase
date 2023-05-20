// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/metatx/MinimalForwarder.sol';
import 'openzeppelin-contracts/contracts/access/ownable.sol';

contract HyperbaseForwarder is MinimalForwarder, Ownable {

  	////////////////
    // STATE
    ////////////////

    /**
     * @dev The protocol token used to pay for transactions.
     */
	address _paymentToken;

    /**
     * @dev Transaction fee charged on top of gas for the transaction.
     */
    uint8 _txFeePercentage;

    /**
     * @dev Total amount of tokens withdrawn from the forwarder.
     */
    uint256 _amountCumulativeWithdrawal;
	
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

    /**
     * @dev Set the payment token for the protocol.
	 * @param paymentToken The address of the token used to pay for transactions.
     */
	function setProtocolToken(
		address paymentToken
	)
		public
		onlyOwner
	{
		_paymentToken = paymentToken;
	}

    /**
     * @dev Set amount charged on transactions.
	 * @param txFeePercentage The amount to be charged on top of gas as a percentage.
     */
	function setTxFeePercentage(
		uint8 txFeePercentage
	)
		public
		onlyOwner
	{
		_txFeePercentage = txFeePercentage;
	}
}