// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.3;
pragma experimental ABIEncoderV2;


contract Migrations {
    address public owner = msg.sender;
    uint public lastCompletedMigration;

    modifier restricted() {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }

    function setCompleted(uint completed) public restricted {
        lastCompletedMigration = completed;
    }
}
