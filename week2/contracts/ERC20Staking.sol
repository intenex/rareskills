// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20Capped, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {IERC20Staking} from "./IERC20Staking.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RareSkills Week 2 Staking ERC-20 Contract
 * @author Ben Yu
 * @notice An ERC-20 contract for staking reward tokens
 */
contract ERC20Staking is ERC20Capped, Ownable, IERC20Staking {
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10 ** 18;

    address public mintAddress;

    /**
     * @notice Constructor for the ERC-20 contract
     * @param _name Name of the ERC-20 token
     * @param _symbol Symbol for the ERC-20 token
     * @param _mintAddress Authorized address to mint tokens
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _mintAddress
    ) ERC20(_name, _symbol) ERC20Capped(MAX_SUPPLY) {
        mintAddress = _mintAddress;
    }

    /**
     * @notice Function to set the mint address
     * @param _mintAddress Address to set as the mint address
     */
    function setMintAddress(address _mintAddress) external onlyOwner {
        mintAddress = _mintAddress;
    }

    /**
     * @notice Function to mint tokens
     * @param _to Address to mint tokens to
     * @param _amount Amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external {
        require(msg.sender == mintAddress, "Only mint address can mint");
        _mint(_to, _amount);
    }
}
