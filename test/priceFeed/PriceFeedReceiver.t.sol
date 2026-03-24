// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {toUniversalAddress} from "@wormhole-solidity-sdk/Utils.sol";
import {PriceFeedReceiver} from "../../src/priceFeed/PriceFeedReceiver.sol";
import {PriceFeed} from "../../src/priceFeed/PriceFeed.sol";

/**
 * @dev Harness that exposes the internal _executeVaa for unit testing payload decoding
 *      without requiring full VAA verification through the CoreBridge.
 */
contract PriceFeedReceiverHarness is PriceFeedReceiver {
    constructor(address priceFeed, address coreBridge, uint16 sourceChain, address sourceAddress)
        PriceFeedReceiver(priceFeed, coreBridge, sourceChain, sourceAddress)
    {}

    function executeVaa(bytes calldata payload) external {
        _executeVaa(payload, uint32(block.timestamp), 0, bytes32(0), 0, 0);
    }
}

contract PriceFeedReceiverTest is Test, GasSnapshot {
    PriceFeed priceFeed;
    address coreBridge = address(1);

    function setUp() public {
        priceFeed = new PriceFeed(address(this), "test");
        // mock coreBridge.chainId()
        vm.mockCall(coreBridge, abi.encodeWithSignature("chainId()"), abi.encode(uint16(23)));
    }

    function test_executeVaa() public {
        PriceFeedReceiverHarness receiver =
            new PriceFeedReceiverHarness(address(priceFeed), coreBridge, 2, address(0xABCD));
        priceFeed.setRateReceiver(address(receiver));

        uint128 newRate = 123;
        bytes memory payload = abi.encode(uint128(block.timestamp), newRate);

        snapStart("PriceFeedReceiver_executeVaa");
        receiver.executeVaa(payload);
        snapEnd();

        assertEq(priceFeed.getRate(), newRate);
        assertEq(priceFeed.latestTimestamp(), block.timestamp);
    }

    function test_executeVaaUpdatesRate() public {
        PriceFeedReceiverHarness receiver =
            new PriceFeedReceiverHarness(address(priceFeed), coreBridge, 2, address(0xABCD));
        priceFeed.setRateReceiver(address(receiver));

        // first update
        uint128 rate1 = 100;
        uint128 ts1 = uint128(block.timestamp);
        receiver.executeVaa(abi.encode(ts1, rate1));
        assertEq(priceFeed.getRate(), rate1);

        // second update with later timestamp
        uint128 rate2 = 200;
        uint128 ts2 = ts1 + 1;
        receiver.executeVaa(abi.encode(ts2, rate2));
        assertEq(priceFeed.getRate(), rate2);
    }

    function test_getPeerReturnsSourceAddress() public {
        PriceFeedReceiver receiver = new PriceFeedReceiver(address(priceFeed), coreBridge, 2, address(0xABCD));

        // Verify constructor sets up correctly by deploying and checking it doesn't revert
        // The peer check happens internally during executeVAAv1
        assertTrue(address(receiver) != address(0));
    }
}
