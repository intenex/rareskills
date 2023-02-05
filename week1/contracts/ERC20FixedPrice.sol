// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC20Capped, ERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RareSkills Week1 ERC-20 Fixed Price Mint Contract
 * @author Ben Yu
 * @notice An ERC-20 contract that implements sanctioning addresses, admin transfers, and fixed price minting
 */
contract ERC20FixedPrice is ERC20Capped, Ownable {
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10 ** 18;

    mapping (address => bool) public bannedAddresses;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) ERC20Capped(MAX_SUPPLY) {
    }

    /**
     * @notice Admin function to ban or unban an address
     * @param _bannedAddress Address to ban or unban
     * @param _banned True if address should be banned, false if address should be unbanned
     */
    function adminBanOrUnbanAddress(address _bannedAddress, bool _banned) external onlyOwner {
        bannedAddresses[_bannedAddress] = _banned;
    }

    /**
     * @dev Overrides the default _beforeTokenTransfer function to add ban checks
     * @param from Address sending tokens
     * @param to Address receiving tokens
     * @param amount Amount of tokens being transferred
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!bannedAddresses[from], "ERC20: transfer from banned address");
        require(!bannedAddresses[to], "ERC20: transfer to banned address");
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @notice Admin function to transfer tokens from one address to another
     * @param _from Address to transfer tokens from
     * @param _to Address to transfer tokens to
     * @param _amount Amount of tokens to transfer
     */
    function adminTransfer(address _from, address _to, uint256 _amount) external onlyOwner {
        _transfer(_from, _to, _amount);
    }

    /**
     * @notice Function to mint tokens at a fixed price of 10,000 tokens per ETH
     * @param _amount Amount of tokens to mint
     */
    function mintFixedPrice(uint256 _amount) external payable {
        require(_amount % 10_000 == 0, "ERC20: amount must be a multiple of 10,000");
        require(msg.value == (_amount / 10 ** uint256(decimals())) / 10_000, "ERC20: incorrect ETH amount");
        _mint(msg.sender, _amount);
    }

    /**
     * @notice Admin function to withdraw ETH from the contract
     */
    function adminWithdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}