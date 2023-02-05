// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC20Capped, ERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RareSkills Week1 ERC-20 Bonding Curve Mint Contract
 * @author Ben Yu
 * @notice An ERC-20 contract that implements sanctioning addresses, admin transfers, and linear bonding curve minting
 */
contract ERC20BondingCurve is ERC20Capped, Ownable {
    uint256 public constant MAX_SUPPLY = 100_000_000 ether; // 100 million tokens; ether is shorthand for 18 decimal places
    uint256 public constant INITIAL_PRICE = 0.001 ether;
    uint256 public constant PRICE_INCREASE_PER_TOKEN = 0.0001 ether;

    mapping (address => uint256) public totalPaidPerAddress;
    mapping (address => bool) public bannedAddresses;

    uint256 public withdrawableBalance;

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
        require(!bannedAddresses[from], "Transfer from banned address");
        require(!bannedAddresses[to], "Transfer to banned address");
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
     * @notice Function to mint tokens at a bonding curve price
     * @param _amount Amount of tokens to mint
     */
    function mintBondingCurve(uint256 _amount) external payable {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Cannot mint more than max supply");
        // First calculate the current price if buying 1 token
        uint256 currentPrice = INITIAL_PRICE + PRICE_INCREASE_PER_TOKEN * totalSupply();
        // Add the extra price for buying more than 1 token
        uint256 extraPriceForMultipleTokens = PRICE_INCREASE_PER_TOKEN * _amount - PRICE_INCREASE_PER_TOKEN;
        require(msg.value == _amount * currentPrice + extraPriceForMultipleTokens, "Incorrect ETH amount paid");

        // Update the total paid per address
        totalPaidPerAddress[msg.sender] += msg.value;

        _mint(msg.sender, _amount);
    }
    
    /**
     * @notice Function to refund tokens at a 10% loss at current market rate
     * @param _amount Amount of tokens to refund
     */
    function buyBackMarketRate(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Cannot refund more tokens than owned");
        // First calculate the current price
        uint256 currentPrice = INITIAL_PRICE + PRICE_INCREASE_PER_TOKEN * totalSupply();
        // Reduce the refund price for refunding multiple tokens; reduce always by 1 for first token
        // since currentPrice is the future price that has not yet been paid
        uint256 reducedPrice = PRICE_INCREASE_PER_TOKEN * _amount;
        uint256 refundAmount = _amount * currentPrice - reducedPrice;
        // Refund 10% less
        uint256 reducedRefundAmount = refundAmount / 10;
        refundAmount -= reducedRefundAmount;
        // Update the withdrawable balance
        withdrawableBalance += reducedRefundAmount;
        // Burn the tokens
        _burn(msg.sender, _amount);
        // Send the refund
        payable(msg.sender).transfer(refundAmount);
    }

    // Because of the inherent limitations as mentioned below, my assumption is this is not the intention of the
    // function as described in the prompt; however, included in just in case this was the intention, despite the limitations
    /**
     * @notice Function to refund tokens at a 10% loss to the average price paid by the user
     * Note - this function fails to take into transfers/secondary sales so it is only accurate for original minters
     * @param _amount Amount of tokens to refund
     */
    function buyBackAverageRate(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Cannot refund more tokens than owned");
        // First calculate the average price paid by the user
        uint256 averagePrice = totalPaidPerAddress[msg.sender] / balanceOf(msg.sender);
        uint256 refundAmount = _amount * averagePrice;
        totalPaidPerAddress[msg.sender] -= refundAmount;
        // Refund 10% less
        uint256 reducedRefundAmount = refundAmount / 10;
        refundAmount -= reducedRefundAmount;
        // Update the withdrawable balance
        withdrawableBalance += reducedRefundAmount;
        // Burn the tokens
        _burn(msg.sender, _amount);
        // Send the refund
        payable(msg.sender).transfer(refundAmount);
    }

    /**
     * @notice Admin function to withdraw the 10% remainder of ETH from buybacks
     * @param _amount Amount of ETH to withdraw
     */
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount <= withdrawableBalance, "Cannot withdraw more than withdrawable balance");
        withdrawableBalance -= _amount;
        payable(msg.sender).transfer(_amount);
    }
}