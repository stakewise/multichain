// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ExecutorSendQuoteOffChain} from "@wormhole-solidity-sdk/Executor/Integration.sol";
import {toUniversalAddress} from "@wormhole-solidity-sdk/Utils.sol";
import {IChainlinkV3Aggregator} from "@stakewise-core/interfaces/IChainlinkV3Aggregator.sol";
import {CONSISTENCY_LEVEL_FINALIZED} from "@wormhole-solidity-sdk/constants/ConsistencyLevel.sol";
import {IPriceFeedSender} from "./interfaces/IPriceFeedSender.sol";

/**
 * @title PriceFeedSender
 * @author StakeWise
 * @notice Sends the new rate to the target chain via Wormhole Executor Relay
 */
contract PriceFeedSender is Ownable2Step, ExecutorSendQuoteOffChain, IPriceFeedSender {
    IChainlinkV3Aggregator private immutable _priceFeed;
    uint128 public immutable gasLimit;

    mapping(uint16 chainId => bytes32 peerAddress) public peers;

    /**
     * @dev Constructor
     * @param initialOwner The address of the contract owner
     * @param priceFeed The address of the PriceFeed contract
     * @param coreBridge The address of the Wormhole Core Bridge contract
     * @param executor The address of the Wormhole Executor contract
     * @param _gasLimit The gas limit for the relay execution
     */
    constructor(address initialOwner, address priceFeed, address coreBridge, address executor, uint128 _gasLimit)
        Ownable(initialOwner)
        ExecutorSendQuoteOffChain(coreBridge, executor)
    {
        _priceFeed = IChainlinkV3Aggregator(priceFeed);
        gasLimit = _gasLimit;
    }

    /**
     * @notice Sets the peer address for a target chain. Can only be called by the owner.
     * @param chainId The Wormhole chain ID
     * @param peerAddress The peer address on the target chain
     */
    function setPeer(uint16 chainId, address peerAddress) external onlyOwner {
        peers[chainId] = toUniversalAddress(peerAddress);
        emit PeerUpdated(chainId, peers[chainId]);
    }

    /// @inheritdoc IPriceFeedSender
    function syncRate(uint16 targetChain, address refundAddress, uint256 totalCost, bytes calldata signedQuote)
        external
        payable
        override
    {
        // fetch latest rate
        (, int256 answer,, uint256 updatedAt,) = _priceFeed.latestRoundData();
        uint128 timestamp = SafeCast.toUint128(updatedAt);
        uint128 newRate = SafeCast.toUint128(SafeCast.toUint256(answer));

        // publish message and request execution via Executor
        _publishAndRelay(
            abi.encode(timestamp, newRate),
            CONSISTENCY_LEVEL_FINALIZED,
            totalCost,
            targetChain,
            refundAddress,
            signedQuote,
            gasLimit,
            0, // no msg.value to receiver
            "" // no extra relay instructions
        );
    }

    function _getPeer(uint16 chainId) internal view override returns (bytes32) {
        return peers[chainId];
    }
}
