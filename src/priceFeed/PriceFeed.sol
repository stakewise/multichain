// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IChainlinkAggregator} from "@stakewise-core/interfaces/IChainlinkAggregator.sol";
import {IChainlinkV3Aggregator} from "@stakewise-core/interfaces/IChainlinkV3Aggregator.sol";
import {IBalancerRateProvider} from "@stakewise-core/interfaces/IBalancerRateProvider.sol";
import {IPriceFeed} from "./interfaces/IPriceFeed.sol";

/**
 * @title PriceFeed
 * @author StakeWise
 * @notice The feed that receives the price from the canonical chain (e.g. mainnet)
 */
contract PriceFeed is Ownable2Step, IPriceFeed {
    error AccessDenied();
    error InvalidTimestamp();

    /// @inheritdoc IChainlinkV3Aggregator
    uint256 public constant override version = 0;

    /// @inheritdoc IChainlinkV3Aggregator
    string public override description;

    /// @inheritdoc IPriceFeed
    address public override rateReceiver;

    uint128 private _rate;
    uint128 private _updateTimestamp;

    /**
     * @dev Constructor
     * @param initialOwner The address of the contract owner
     * @param _description The description of the price feed
     */
    constructor(address initialOwner, string memory _description) Ownable(initialOwner) {
        description = _description;
    }

    /// @inheritdoc IBalancerRateProvider
    function getRate() public view override returns (uint256) {
        return _rate;
    }

    /// @inheritdoc IPriceFeed
    function setRate(uint128 timestamp, uint128 newRate) external override {
        if (msg.sender != rateReceiver) revert AccessDenied();
        if (timestamp <= _updateTimestamp) revert InvalidTimestamp();

        // update state
        _rate = newRate;
        _updateTimestamp = timestamp;
        emit RateUpdated(msg.sender, newRate, timestamp);
    }

    /// @inheritdoc IPriceFeed
    function setRateReceiver(address newRateReceiver) external override onlyOwner {
        rateReceiver = newRateReceiver;
        emit RateReceiverUpdated(newRateReceiver);
    }

    /// @inheritdoc IChainlinkAggregator
    function latestAnswer() public view override returns (int256) {
        // cannot overflow as _rate is uint128
        return int256(getRate());
    }

    /// @inheritdoc IChainlinkAggregator
    function latestTimestamp() external view returns (uint256) {
        return _updateTimestamp;
    }

    /// @inheritdoc IChainlinkV3Aggregator
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /// @inheritdoc IChainlinkV3Aggregator
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        // SLOAD to memory
        uint256 updateTimestamp = _updateTimestamp;
        return (0, latestAnswer(), updateTimestamp, updateTimestamp, 0);
    }
}
