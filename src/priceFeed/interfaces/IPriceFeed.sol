// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {IChainlinkAggregator} from "@stakewise-core/interfaces/IChainlinkAggregator.sol";
import {IBalancerRateProvider} from "@stakewise-core/interfaces/IBalancerRateProvider.sol";
import {IChainlinkV3Aggregator} from "@stakewise-core/interfaces/IChainlinkV3Aggregator.sol";

/**
 * @title IPriceFeed
 * @author StakeWise
 * @notice Interface for the PriceFeed contract
 */
interface IPriceFeed is IChainlinkAggregator, IChainlinkV3Aggregator, IBalancerRateProvider {
    /**
     * @notice Emitted when the rate of the price feed is updated
     * @param caller The address of the caller who updated the rate
     * @param newRate The new rate of the price feed
     * @param newTimestamp The timestamp of the rate update
     */
    event RateUpdated(address indexed caller, uint128 newRate, uint128 newTimestamp);

    /**
     * @notice Emitted when the rate receiver address is updated
     * @param newRateReceiver The new rate receiver address
     */
    event RateReceiverUpdated(address newRateReceiver);

    /**
     * @notice Function to get the rate receiver address
     * @return The rate receiver address
     */
    function rateReceiver() external view returns (address);

    /**
     * @notice Updates the rate of the price feed. Can only be called by the owner.
     * @param timestamp The timestamp of the rate update
     * @param newRate The new rate of the price feed
     */
    function setRate(uint128 timestamp, uint128 newRate) external;

    /**
     * @notice Function to set the rate receiver address
     * @param newRateReceiver The new rate receiver address
     */
    function setRateReceiver(address newRateReceiver) external;
}
