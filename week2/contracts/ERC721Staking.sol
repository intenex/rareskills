// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Basic ERC-721
 * @author Ben Yu
 * @notice This contract handles public minting of ERC-721 tokens
 */
contract ERC721Staking is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private supplyCounter;

    uint256 public constant PRICE = 0.01 ether;
    uint256 public constant MAX_SUPPLY = 1000;
    uint96 public constant ROYALTY_FEE = 250;

    string public baseTokenURI =
        "ipfs://bafybeih5lgrstt7kredzhpcvmft2qefue5pl3ykrdktadw5w62zd7cbkja/";
    bool public publicSaleActive;

    /**
     * @notice Construct a Curious Addys instance
     * @param _name Token name
     * @param _symbol Token symbol
     */
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    /**
     * @notice Override the default base URI function to provide a real base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Update the base token URI
     * @param _newBaseURI New base URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Returns the total supply of tokens
     */
    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    /**
     * @notice Allows for public minting of tokens
     * @param _mintNumber Number of tokens to mint
     */
    function publicMint(uint256 _mintNumber) external payable virtual {
        require(msg.value == PRICE * _mintNumber, "INVALID_PRICE");
        require((totalSupply() + _mintNumber) <= MAX_SUPPLY, "MINT_TOO_LARGE");

        for (uint256 i = 0; i < _mintNumber; i++) {
            _safeMint(msg.sender, supplyCounter.current());
            supplyCounter.increment();
        }
    }

    /**
     * @notice Allow contract owner to withdraw funds
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
