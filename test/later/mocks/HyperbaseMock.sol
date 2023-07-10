// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '../Hyperbase/HyperbaseCore.sol';

/**

	Minimal wraper around core execution contract.

*/

contract HyperbaseMock is HyperbaseCore {  

	function submit(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
	)
		public
		returns(uint256 txHash_)
	{
		txHash_ = _submit(targets, values, calldatas);
	}

	function execute(
		uint256 txHash
	)
		public
	{
		_execute(txHash);
	}

	function cancel(
		uint256 txHash
	) public {
		_execute(txHash);
	}

}