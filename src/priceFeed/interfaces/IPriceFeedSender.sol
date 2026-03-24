// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

/**
 * @title IPriceFeedSender
 * @author StakeWise
 * @notice Interface for the PriceFeedSender contract
 */
interface IPriceFeedSender {
    /**
     * @notice Emitted when a peer is updated
     * @param chainId The Wormhole chain ID
     * @param peerAddress The peer address in universal format
     */
    event PeerUpdated(uint16 indexed chainId, bytes32 peerAddress);

    /**
     * @notice The gas limit for the relay execution on the target chain
     * @return The gas limit value
     */
    function gasLimit() external view returns (uint128);

    /**
     * @notice Function for syncing the rate to the target chain via Wormhole Executor Relay.
     * @param targetChain The Wormhole chain ID of the target chain
     * @param refundAddress The address to receive any relay refunds
     * @param totalCost The total cost of the relay (msg.value must cover this + message fee)
     * @param signedQuote The signed quote from the relay provider
     */
    function syncRate(uint16 targetChain, address refundAddress, uint256 totalCost, bytes calldata signedQuote)
        external
        payable;
}
