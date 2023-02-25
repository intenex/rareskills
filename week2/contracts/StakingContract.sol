// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20Staking} from "./IERC20Staking.sol";

/**
 * @title RareSkills Week 2 Staking ERC-721 Contract
 * @author Ben Yu
 * @notice An contract for staking NFTs and claiming ERC-20 tokens
 */
contract StakingContract is IERC721Receiver, Ownable {
    address public erc20Contract;
    address public erc721Contract;
    mapping(uint256 => address) public nftToOwner;
    mapping(uint256 => uint256) public nftToTimeStakedSinceLastClaim;

    /**
     * @notice Set the address of the ERC-20 contract of the tokens to be claimed
     * @param _erc20Contract Address of the ERC-20 contract
     */
    function setERC20Contract(address _erc20Contract) external onlyOwner {
        erc20Contract = _erc20Contract;
    }

    /**
     * @notice Set the address of the ERC-721 contract of the NFTs to be staked
     * @param _erc721Contract Address of the ERC-721 contract
     */
    function setERC721Contract(address _erc721Contract) external onlyOwner {
        erc721Contract = _erc721Contract;
    }

    /**
     * @notice Function to receive NFTs and record the owner and time staked
     * @param _from Address of the original NFT owner
     * @param _tokenId ID of the NFT
     */
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        nftToOwner[_tokenId] = _from;
        nftToTimeStakedSinceLastClaim[_tokenId] = block.timestamp;
        return this.onERC721Received.selector;
    }

    /**
     * @notice Function to determine how many ERC-20 tokens can be claimed. 10 tokens per day staked
     * @param _tokenId ID of the NFT
     */
    function getClaimableTokens(
        uint256 _tokenId
    ) public view returns (uint256) {
        uint256 timeStaked = nftToTimeStakedSinceLastClaim[_tokenId];
        uint256 timeSinceLastClaim = block.timestamp - timeStaked;
        // seconds since last claim * 10 tokens per day * 10 ** 18 (decimals) / 86400 (seconds in a day)
        return (timeSinceLastClaim * 10 * 10 ** 18) / 86400;
    }

    /**
     * @notice Function to withdraw NFTs and claim any remaining unclaimed ERC-20 tokens
     * @param _tokenId ID of the NFT
     */
    function withdrawNFT(uint256 _tokenId) external {
        require(nftToOwner[_tokenId] == msg.sender, "Only owner can withdraw");
        IERC20Staking(erc20Contract).mint(
            msg.sender,
            getClaimableTokens(_tokenId)
        );
        IERC721(erc721Contract).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
        delete nftToOwner[_tokenId];
        delete nftToTimeStakedSinceLastClaim[_tokenId];
    }

    /**
     * @notice Function to claim ERC-20 tokens
     * @param _tokenId ID of the NFT
     */
    function claimTokens(uint256 _tokenId) external {
        require(nftToOwner[_tokenId] == msg.sender, "Only owner can claim");
        IERC20Staking(erc20Contract).mint(
            msg.sender,
            getClaimableTokens(_tokenId)
        );
        nftToTimeStakedSinceLastClaim[_tokenId] = block.timestamp;
    }
}
