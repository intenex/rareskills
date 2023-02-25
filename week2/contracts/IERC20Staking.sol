// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IERC20Staking token receiver interface
 */
interface IERC20Staking is IERC20 {
    /**
     * @notice Function to mint tokens
     * @param _to Address to mint tokens to
     * @param _amount Amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @notice Function to set the mint address
     * @param _mintAddress Address to set as the mint address
     */
    function setMintAddress(address _mintAddress) external;
}
