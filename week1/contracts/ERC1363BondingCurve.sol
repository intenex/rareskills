// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC1363} from "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";
import {IERC1363Receiver} from "erc-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol";
import {ERC20Capped, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

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
    uint256 public constant INITIAL_PRICE_PER_TOKEN = 0;
    uint256 public constant PRICE_INCREASE_PER_TOKEN = 0.0001 ether;

    mapping(address => bool) public bannedAddresses;

    uint256 public withdrawableBalance;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) ERC20Capped(MAX_SUPPLY) {}

    function _mint(
        address _account,
        uint256 _amount
    ) internal override(ERC20, ERC20Capped) {
        ERC20Capped._mint(_account, _amount);
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
     * @param _from Address sending tokens
     * @param _to Address receiving tokens
     * @param _amount Amount of tokens being transferred
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        require(!bannedAddresses[_from], "Transfer from banned address");
        require(!bannedAddresses[_to], "Transfer to banned address");
        super._beforeTokenTransfer(_from, _to, _amount);
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

    // for echidna testing of the balance
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Returns the current price of purchasing a token
     */
    function getCurrentPrice() public view returns (uint256) {
        return (totalSupply() * PRICE_INCREASE_PER_TOKEN) / oneToken();
    }

    /**
     * @notice Function to mint tokens at a bonding curve price
     * @param _amount Amount of tokens to mint in smallest unit of account (18 decimal places)
     */
    function mintBondingCurve(uint256 _amount) internal {
        require(
            totalSupply() + _amount <= MAX_SUPPLY,
            "Cannot mint more than max supply"
        );

        // Finding the price to pay is finding the area of a trapezoid - (base 1 + base 2) * height / 2
        // Height == # of tokens, base 1 is the current price, base 2 is the final price after all the tokens are purchased
        uint256 currentPrice = getCurrentPrice(); // 0
        uint256 endingPrice = currentPrice +
            ((_amount * PRICE_INCREASE_PER_TOKEN) / oneToken());
        uint256 priceToPay = ((currentPrice + endingPrice) * _amount) /
            oneToken() /
            2;
        require(msg.value >= priceToPay, "Incorrect ETH amount paid");
        // refund any extra ETH sent
        if (msg.value > priceToPay) {
            (bool success, ) = msg.sender.call{value: msg.value - priceToPay}(
                ""
            );
            require(success, "Transfer failed.");
        }

        _mint(msg.sender, _amount);
    }

    /**
     * @notice Allows for tokens to be sent to this contract and then refunded at a 10% loss at current market rate
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param _spender address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param _amount uint256 The amount of tokens transferred
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))` unless throwing
     */
    function onTransferReceived(
        address _spender,
        address,
        uint256 _amount,
        bytes calldata
    ) external override returns (bytes4) {
        uint256 currentPrice = getCurrentPrice();
        uint256 endingPrice = currentPrice -
            ((_amount * PRICE_INCREASE_PER_TOKEN) / oneToken());
        uint256 priceToRefund = ((currentPrice + endingPrice) * _amount) /
            oneToken() /
            2;

        _burn(msg.sender, _amount);

        (bool success, ) = _spender.call{value: priceToRefund}("");
        require(success, "Transfer failed.");
        return
            bytes4(
                keccak256("onTransferReceived(address,address,uint256,bytes)")
            );
    }
}
