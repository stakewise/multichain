// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {PriceFeed, IPriceFeed} from "../../src/priceFeed/PriceFeed.sol";

contract PriceFeedTest is Test {
    PriceFeed priceFeed;

    function setUp() public {
        priceFeed = new PriceFeed(address(this), "test");
    }

    function test_setRateReceiver() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(1)));
        vm.prank(address(1));
        priceFeed.setRateReceiver(address(1));

        vm.expectEmit(false, false, false, true);
        emit IPriceFeed.RateReceiverUpdated(address(1));
        address newRateReceiver = address(1);
        priceFeed.setRateReceiver(newRateReceiver);
        assertEq(priceFeed.rateReceiver(), newRateReceiver);
    }

    function test_setRate() public {
        priceFeed.setRateReceiver(address(this));
        uint128 rate = 123;
        uint128 timestamp = uint128(block.timestamp);

        vm.expectRevert(PriceFeed.AccessDenied.selector);
        vm.prank(address(1));
        priceFeed.setRate(timestamp, rate);

        vm.expectEmit(true, false, false, true);
        emit IPriceFeed.RateUpdated(address(this), rate, timestamp);
        priceFeed.setRate(timestamp, rate);
        assertEq(priceFeed.getRate(), 123);
        assertEq(priceFeed.latestTimestamp(), timestamp);
        assertEq(priceFeed.latestAnswer(), int256(uint256(rate)));
        assertEq(priceFeed.decimals(), 18);
        assertEq(priceFeed.description(), "test");

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            priceFeed.latestRoundData();
        assertEq(roundId, 0);
        assertEq(answer, int256(uint256(rate)));
        assertEq(startedAt, timestamp);
        assertEq(updatedAt, timestamp);
        assertEq(answeredInRound, 0);

        vm.expectRevert(PriceFeed.InvalidTimestamp.selector);
        priceFeed.setRate(timestamp - 1, rate);
    }
}
