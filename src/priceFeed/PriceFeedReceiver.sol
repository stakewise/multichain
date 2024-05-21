// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {IWormholeReceiver} from "@wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";
import {toWormholeFormat} from "@wormhole-solidity-sdk/Utils.sol";
import {IPriceFeed} from "./interfaces/IPriceFeed.sol";

/**
 * @title PriceFeedReceiver
 * @author StakeWise
 * @notice Receives messages from the Wormhole and updates the PriceFeed contract rate.
 */
contract PriceFeedReceiver is IWormholeReceiver {
    error AccessDenied();
    error InvalidSource();
    error MessageAlreadyParsed(bytes32 vaaHash);

    IPriceFeed private immutable _priceFeed;
    address private immutable _wormholeRelayer;
    uint16 private immutable _sourceChain;
    bytes32 private immutable _sourceAddress;

    mapping(bytes32 vaa => bool isConsumed) private _consumedVAAs;

    /**
     * @dev Constructor
     * @param priceFeed The address of the PriceFeed contract
     * @param wormholeRelayer The address of the Wormhole Relayer contract
     * @param sourceChain The Wormhole ID of the source chain
     * @param sourceAddress The source address of the messages
     */
    constructor(address priceFeed, address wormholeRelayer, uint16 sourceChain, address sourceAddress) {
        _priceFeed = IPriceFeed(priceFeed);
        _wormholeRelayer = wormholeRelayer;
        _sourceChain = sourceChain;
        _sourceAddress = toWormholeFormat(sourceAddress);
    }

    /// @inheritdoc IWormholeReceiver
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable override {
        // check the sender
        if (msg.sender != _wormholeRelayer) {
            revert AccessDenied();
        }
        // only single source can be accepted
        if (sourceChain != _sourceChain || sourceAddress != _sourceAddress) {
            revert InvalidSource();
        }

        // VAA replay protection
        if (_consumedVAAs[deliveryHash]) {
            revert MessageAlreadyParsed(deliveryHash);
        }
        _consumedVAAs[deliveryHash] = true;

        // parse the received payload
        (uint128 timestamp, uint128 newRate) = abi.decode(payload, (uint128, uint128));
        _priceFeed.setRate(timestamp, newRate);
    }
}
