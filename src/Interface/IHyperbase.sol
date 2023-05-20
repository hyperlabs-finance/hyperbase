// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHyperbase {

  	////////////////
    // ERRORS
    ////////////////

    /**
    * @dev Only this contract can call these functions.
    */
    error OnlyThis();
        
    /**
    * @dev Key has already been added to the account.
    */
    error KeyExists();

    /**
    * @dev Key has not been added to the account.
    */
    error KeyDoesNotExists();

    /**
    * @dev Key has not approved the transaction.
    */
    error KeyNotApproved();

    /**
    * @dev Key has already approved the transaction.
    */
    error KeyApproved();

    /**
    * @dev Key is zero address.
    */
    error KeyZeroAddress();

    /**
    * @dev Change would result in inadequate keys on the account, either too many or too few.
    */
    error KeyRequirementInvalid();

  	////////////////
    // EVENTS
    ////////////////

    /**
    * @dev A key has been added to the account.
    */
    event KeyAdded(address indexed key);
    
    /**
    * @dev A key has been removed from the account.
    */
    event KeyRemoved(address indexed key);

    /**
    * @dev The amount of sigs require to execute a transaction has been updated.
    */
    event RequirementChange(uint256 requirement);

}