// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IWormholeRelayer} from "@wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import {IChainlinkV3Aggregator} from "@stakewise-core/interfaces/IChainlinkV3Aggregator.sol";
import {IPriceFeedSender} from "./interfaces/IPriceFeedSender.sol";

/**
 * @title PriceFeedSender
 * @author StakeWise
 * @notice Sends the new rate to the Wormhole Relayer
 */
contract PriceFeedSender is IPriceFeedSender {
    error InsufficientFunds();

    IChainlinkV3Aggregator private immutable _priceFeed;
    IWormholeRelayer private immutable _wormholeRelayer;
    uint256 private immutable _gasLimit;
    uint16 private immutable _chainId;

    /**
     * @dev Constructor
     * @param priceFeed The address of the PriceFeed contract
     * @param wormholeRelayer The address of the Wormhole Relayer contract
     * @param gasLimit The gas limit for the Wormhole Relayer call
     * @param chainId The Wormhole chain ID
     */
    constructor(address priceFeed, address wormholeRelayer, uint256 gasLimit, uint16 chainId) {
        _priceFeed = IChainlinkV3Aggregator(priceFeed);
        _wormholeRelayer = IWormholeRelayer(wormholeRelayer);
        _gasLimit = gasLimit;
        _chainId = chainId;
    }

    /// @inheritdoc IPriceFeedSender
    function quoteRateSync(uint16 targetChain) public view override returns (uint256 cost) {
        (cost,) = _wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0, // pass zero as receiver value is not used
            _gasLimit
        );
    }

    /// @inheritdoc IPriceFeedSender
    function syncRate(uint16 targetChain, address targetAddress) external payable override {
        // check sufficient funds
        uint256 cost = quoteRateSync(targetChain);
        if (msg.value != cost) {
            revert InsufficientFunds();
        }

        // fetch latest rate
        (, int256 answer,, uint256 updatedAt,) = _priceFeed.latestRoundData();
        uint128 timestamp = SafeCast.toUint128(updatedAt);
        uint128 newRate = SafeCast.toUint128(SafeCast.toUint256(answer));

        // send the rate to the Wormhole Relayer
        _wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            targetAddress,
            abi.encode(timestamp, newRate), // encode payload
            0, // pass zero as receiver value is not used
            _gasLimit,
            _chainId, // use the current chain ID as the refund chain
            msg.sender // use the sender as the refund address
        );
    }
}
