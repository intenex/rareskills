// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC1363} from "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";
import {IERC1363Receiver} from "erc-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol";
import {ERC20Capped, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/**
 * @title RareSkills Week1 ERC-1363 Bonding Curve Mint Contract
 * @author Ben Yu
 * @notice An ERC-1363 contract that implements sanctioning addresses, admin transfers, and linear bonding curve minting
 */
contract ERC1363BondingCurve is
    ERC1363,
    IERC1363Receiver,
    ERC20Capped,
    Ownable
{
    uint256 public constant MAX_SUPPLY = 100_000_000 ether; // 100 million tokens; ether is shorthand for 18 decimal places
    uint256 public constant INITIAL_PRICE_PER_TOKEN = 0; // first token costs 0.0001 ether
    uint256 public constant PRICE_INCREASE_PER_TOKEN = 0.0001 ether; // 100000000000000 wei payment == 1 token, or 1000000000000000000

    mapping(address => bool) public bannedAddresses;

    uint256 public withdrawableBalance;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) ERC20Capped(MAX_SUPPLY) {}

    function _mint(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Capped) {
        ERC20Capped._mint(account, amount);
    }

    /**
     * @notice Returns the value of one token in wei
     */
    function oneToken() public view returns (uint256) {
        return 10 ** decimals();
    }

    /**
     * @notice Admin function to ban or unban an address
     * @param _bannedAddress Address to ban or unban
     * @param _banned True if address should be banned, false if address should be unbanned
     */
    function adminBanOrUnbanAddress(
        address _bannedAddress,
        bool _banned
    ) external onlyOwner {
        bannedAddresses[_bannedAddress] = _banned;
    }

    /**
     * @dev Overrides the default _beforeTokenTransfer function to add ban checks
     * @param from Address sending tokens
     * @param to Address receiving tokens
     * @param amount Amount of tokens being transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
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
    function adminTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _transfer(_from, _to, _amount);
    }

    /**
     * @notice Returns the current price of purchasing a token
     */
    function getCurrentPrice() public view returns (uint256) {
        return (totalSupply() * PRICE_INCREASE_PER_TOKEN) / oneToken();
    }

    /**
     * @notice Returns the current price of purchasing a token
     */
    function getEndingPrice(uint256 _amount) public view returns (uint256) {
        return
            getCurrentPrice() +
            ((_amount * PRICE_INCREASE_PER_TOKEN) / oneToken());
    }

    /**
     * @notice Returns the smallest unit of price increase
     */
    function smallestUnitOfPriceIncrease() public pure returns (uint256) {
        return PRICE_INCREASE_PER_TOKEN / 100000000000000;
    }

    /**
     * @notice Function to mint tokens at a bonding curve price
     * @param _amount Amount of tokens to mint in smallest unit of account (18 decimal places)
     */
    function mintBondingCurve(uint256 _amount) external payable {
        require(
            totalSupply() + _amount <= MAX_SUPPLY,
            "Cannot mint more than max supply"
        );

        uint256 oneUnit = (PRICE_INCREASE_PER_TOKEN * _amount) / oneToken();
        console.log("oneUnit", oneUnit);

        // NOTE - finding the price to pay is just finding the area of a trapezoid - (base 1 + base 2 + 1) * height / 2
        // In this case height is actually the # of tokens and base 1 is the current price and base 2 is the final price after all the tokens are purchased
        uint256 currentPrice = getCurrentPrice(); // 0
        console.log("currentPrice", currentPrice);
        uint256 endingPrice = currentPrice +
            ((_amount * PRICE_INCREASE_PER_TOKEN) / oneToken()); // 0 + (1000000 * 0.0001 (= 100) * 10 ** 18) / 10 ** 18
        console.log("endingPrice", endingPrice);
        uint256 priceToPay = ((currentPrice + endingPrice) * (_amount)) /
            oneToken() /
            2;
        console.log("Price to pay", priceToPay);
        require(msg.value == priceToPay, "Incorrect ETH amount paid");

        _mint(msg.sender, _amount);
    }

    /**
     * @notice Allows for tokens to be sent to this contract and then refunded at a 10% loss at current market rate
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param spender address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param sender address The address which are token transferred from
     * @param amount uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))` unless throwing
     */
    function onTransferReceived(
        address spender,
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override returns (bytes4) {
        uint256 currentPrice = getCurrentPrice();
        uint256 endingPrice = currentPrice -
            ((amount * PRICE_INCREASE_PER_TOKEN) / oneToken());
        uint256 priceToRefund = ((currentPrice +
            endingPrice +
            PRICE_INCREASE_PER_TOKEN) * amount) / 2;
        _burn(msg.sender, amount);
        (bool success, ) = msg.sender.call{value: priceToRefund}("");
        require(success, "Transfer failed.");
        return
            bytes4(
                keccak256("onTransferReceived(address,address,uint256,bytes)")
            );
    }
}
