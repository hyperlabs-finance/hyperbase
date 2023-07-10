// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "../src/mocks/HyperbaseMock.sol";
import "../src/mocks/CallableContractMock.sol";

contract HyperbaseCoreTest is Test {
    
    // hyperbase
    HyperbaseMock public _hyperbase;

    // callable
    CallableContractMock public _callable;

    // Set up
    function setUp() public {

        // hyperbase 
		_hyperbase = new HyperbaseMock();

        // Callable
        _callable = new CallableContractMock();

    }

    function testSubmit_failTransactionEmpty() public {
    
        // Create a list of targets
        address[] memory targets = new address[](0);

        // Create a list of values
        uint256[] memory values = new uint256[](0);

        // Create a list of calldatas
        bytes[] memory calldatas = new bytes[](0);
        
        // Test revert
		vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("TransactionEmpty()"))));

        // Call the proposal function on the governor contract with the fields `targets`, `values`, `calldatas` 
        _hyperbase.submit(
            targets, // targets
            values, // values
            calldatas // calldatas
        );
    }
    
    function testSubmit_failTransactionArrayUnequal() public {
    
        // Create a list of targets
        address[] memory targets = new address[](2);

        // Create a list of values
        uint256[] memory values = new uint256[](1);

        // Create a list of calldatas
        bytes[] memory calldatas = new bytes[](1);
        
        // Test revert
		vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("TransactionArrayUnequal()"))));

        // Call the proposal function on the governor contract with the fields `targets`, `values`, `calldatas` 
        _hyperbase.submit(
            targets, // targets
            values, // values
            calldatas // calldatas
        );
    }
    
    function testSubmit() public returns(uint256 txHash) {
    
        // Create a list of targets
        address[] memory targets = new address[](1);
        targets[0] = address(_callable);

        // Create a list of values
        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        // Create a list of calldatas
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("store(address)",99);

        // Call the proposal function on the governor contract with the fields `targets`, `values`, `calldatas` 
        txHash = _hyperbase.submit(targets, values, calldatas);

        uint256 txHashNew = _hyperbase.getTransactionHash(targets, values, calldatas);

        assertTrue(_hyperbase.checkTransactionExists(txHashNew) == true, "TX does not exist");

        // #TODO, not returning the txHash?
        // console.log(txHash);
        // console.log(txHashNew);
        // assertTrue(txHash == txHashNew, "TX hash inequality");
        
    }

    function testExecute() public {
        
        _callable.store(100);

        assertTrue(_callable.getValue() == 100, "testSubmit: Stored value mismatch");

        uint256 txHash = testSubmit();

        _hyperbase.execute(txHash);

        // assertTrue(_callable.getValue() == 99, "Updated values mismatch");
    }

}