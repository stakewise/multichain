// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

/**
 * @title IPriceFeedSender
 * @author StakeWise
 * @notice Interface for the PriceFeedSender contract
 */
interface IPriceFeedSender {
    /**
     * @notice Function for calculating the cost of the rate sync
     * @param targetChain The Wormhole chain ID of the target chain
     * @return cost The cost of the rate sync
     */
    function quoteRateSync(uint16 targetChain) external view returns (uint256 cost);

    /**
     * @notice Function for syncing the rate to the target chain. Must be called with the exact cost of the rate sync.
     * @param targetChain The Wormhole chain ID of the target chain
     * @param targetAddress The address of the rate receiver on the target chain
     */
    function syncRate(uint16 targetChain, address targetAddress) external payable;
}
