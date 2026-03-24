// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {ExecutorReceive} from "@wormhole-solidity-sdk/Executor/Integration.sol";
import {SequenceReplayProtectionLib} from "@wormhole-solidity-sdk/libraries/ReplayProtection.sol";
import {toUniversalAddress} from "@wormhole-solidity-sdk/Utils.sol";
import {IPriceFeed} from "./interfaces/IPriceFeed.sol";

/**
 * @title PriceFeedReceiver
 * @author StakeWise
 * @notice Receives VAAs from the Wormhole Executor and updates the PriceFeed contract rate.
 */
contract PriceFeedReceiver is ExecutorReceive {
    IPriceFeed private immutable _priceFeed;
    uint16 private immutable _sourceChain;
    bytes32 private immutable _sourceAddress;

    /**
     * @dev Constructor
     * @param priceFeed The address of the PriceFeed contract
     * @param coreBridge The address of the Wormhole Core Bridge contract
     * @param sourceChain The Wormhole ID of the source chain
     * @param sourceAddress The source address of the messages (PriceFeedSender)
     */
    constructor(address priceFeed, address coreBridge, uint16 sourceChain, address sourceAddress)
        ExecutorReceive(coreBridge)
    {
        _priceFeed = IPriceFeed(priceFeed);
        _sourceChain = sourceChain;
        _sourceAddress = toUniversalAddress(sourceAddress);
    }

    function _getPeer(uint16 chainId) internal view override returns (bytes32) {
        if (chainId == _sourceChain) {
            return _sourceAddress;
        }
        return bytes32(0);
    }

    function _replayProtect(uint16 emitterChainId, bytes32 emitterAddress, uint64 sequence, bytes calldata)
        internal
        override
    {
        SequenceReplayProtectionLib.replayProtect(emitterChainId, emitterAddress, sequence);
    }

    function _executeVaa(bytes calldata payload, uint32, uint16, bytes32, uint64, uint8) internal override {
        (uint128 timestamp, uint128 newRate) = abi.decode(payload, (uint128, uint128));
        _priceFeed.setRate(timestamp, newRate);
    }
}
