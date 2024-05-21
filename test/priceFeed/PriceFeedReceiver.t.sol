// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {toWormholeFormat} from "@wormhole-solidity-sdk/Utils.sol";
import {PriceFeedReceiver} from "../../src/priceFeed/PriceFeedReceiver.sol";
import {PriceFeed} from "../../src/priceFeed/PriceFeed.sol";

contract PriceFeedReceiverTest is Test {
    PriceFeed priceFeed;

    function setUp() public {
        priceFeed = new PriceFeed(address(this), "test");
    }

    function test_receiveWormholeMessages() public {
        PriceFeedReceiver priceFeedReceiver =
            new PriceFeedReceiver(address(priceFeed), address(this), 2, address(0xABCD));
        priceFeed.setRateReceiver(address(priceFeedReceiver));

        uint128 newRate = 123;
        bytes32 sourceAddress = toWormholeFormat(address(0xABCD));
        bytes memory payload = abi.encode(uint128(block.timestamp), newRate);

        vm.expectRevert(PriceFeedReceiver.AccessDenied.selector);
        vm.prank(address(0xBEEF));
        priceFeedReceiver.receiveWormholeMessages(payload, new bytes[](0), sourceAddress, 2, bytes32(0));

        vm.expectRevert(PriceFeedReceiver.InvalidSource.selector);
        priceFeedReceiver.receiveWormholeMessages(payload, new bytes[](0), sourceAddress, 3, bytes32(0));

        vm.expectRevert(PriceFeedReceiver.InvalidSource.selector);
        priceFeedReceiver.receiveWormholeMessages(
            payload, new bytes[](0), toWormholeFormat(address(0xABCE)), 2, bytes32(0)
        );

        priceFeedReceiver.receiveWormholeMessages(payload, new bytes[](0), sourceAddress, 2, bytes32(0));
        assertEq(priceFeed.getRate(), newRate);
        assertEq(priceFeed.latestTimestamp(), block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(PriceFeedReceiver.MessageAlreadyParsed.selector, bytes32(0)));
        priceFeedReceiver.receiveWormholeMessages(payload, new bytes[](0), sourceAddress, 2, bytes32(0));
    }
}
