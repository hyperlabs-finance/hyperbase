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

    //////////////////////////////////////////////
    // OWNER FUNCTIONS
    //////////////////////////////////////////////

    /** 
     * @dev Withdraw eth from the contract.
     * @param beneficiary Account to pay.
     * @param withdrawAmount Amount to pay to beneficiary.
     */
    function withdrawFunds(
        address payable beneficiary,
        uint256 withdrawAmount
    )
        external
        onlyOwner
    {
        // Sanity checks
        if (address(this).balance < withdrawAmount)
            revert WithdrawExceedsBalance();
        if (address(this).balance - _betAmountLockIn < withdrawAmount)
            revert WithdrawExceedsFreeBalance();
        
        // Send funds
        beneficiary.transfer(withdrawAmount);

        // Update amount withdrawn
        _betAmountCumulativeWithdrawal += withdrawAmount;
    }

    /** 
     * @dev Withdraw tokens from the contract.
	 * @param tokenAddress address of token to withdraw from contract.
     */
    function withdrawTokens(
        address tokenAddress
    )
        external
        onlyOwner
    {
        IERC20(tokenAddress).safeTransfer(owner(), IERC20(tokenAddress).balanceOf(address(this)));
    }

    /** 
     * @dev Withdraw all tokens and funds from the contract.
     */
    function withdrawAll()
        external
        onlyOwner
    {
        uint256 withdrawAmount = address(this).balance - _betAmountLockIn;
        _betAmountCumulativeWithdrawal += withdrawAmount;
        payable(msg.sender).transfer(withdrawAmount);
        _paymentToken.transfer(owner(), _paymentToken.balanceOf(address(this)));
    }
    
    fallback()
        external
        payable
    {
        _betAmountCumulativeDeposit += msg.value;
    }

    receive()
        external
        payable
    {
        _betAmountCumulativeDeposit += msg.value;
    }
}