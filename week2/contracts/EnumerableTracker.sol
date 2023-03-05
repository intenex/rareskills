// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title RareSkills Week 2 ERC 721 Enumerable View Contract
 * @author Ben Yu
 * @notice A contract for returning information on an enumerable ERC-721 contract
 */
contract EnumerableTracker {
    address public erc20Contract;
    address public erc721Contract;
    mapping(uint256 => address) public nftToOwner;
    mapping(uint256 => uint256) public nftToTimeStakedSinceLastClaim;

    /**
     * @notice Initialize the contract with the address of the ERC-721 contract to read
     * @param _erc721Contract Address of the ERC-721 contract
     */
    constructor(address _erc721Contract) {
        erc721Contract = _erc721Contract;
    }

    /**
     * @notice Returns true if the number is prime using the 6k + 1 optimization (https://en.wikipedia.org/wiki/Primality_test#Simple_methods)
     * @param _number Number to check
     */
    function isPrime(uint256 _number) public pure returns (bool) {
        if (_number <= 1) {
            return false;
        } else if (_number <= 3) {
            return true;
        } else if (_number % 2 == 0 || _number % 3 == 0) {
            return false;
        }
        uint256 i = 5;
        while (i * i <= _number) {
            if (_number % i == 0 || _number % (i + 2) == 0) {
                return false;
            }
            i += 6;
        }
        return true;
    }

    /**
     * @notice Returns the total number of token ids owned by an address that are prime numbers
     * @param _owner Address of the owner to check
     */
    function primeTokenIdBalanceOf(
        address _owner
    ) public view returns (uint256) {
        IERC721Enumerable erc721 = IERC721Enumerable(erc721Contract);
        uint256 primeTokenIdCount = 0;
        uint256 totalTokenIdCount = erc721.balanceOf(_owner);
        for (uint256 i = 0; i < totalTokenIdCount; i++) {
            uint256 tokenId = erc721.tokenOfOwnerByIndex(_owner, i);
            if (isPrime(tokenId)) {
                primeTokenIdCount++;
            }
        }
        return primeTokenIdCount;
    }
}
