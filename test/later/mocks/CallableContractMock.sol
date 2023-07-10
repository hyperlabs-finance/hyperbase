// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CallableContractMock {
    
    uint256 public value;

    uint256[] public storedValues;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        storedValues.push(newValue);
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function getValue() public view returns (uint256) {
        return value;
    }
}
