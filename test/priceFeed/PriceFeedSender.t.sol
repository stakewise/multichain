// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {PriceFeedSender} from "../../src/priceFeed/PriceFeedSender.sol";
import {PriceFeed} from "../../src/priceFeed/PriceFeed.sol";

contract PriceFeedSenderTest is Test, GasSnapshot {
    address priceFeed;
    address coreBridge = address(1);
    address executor = address(2);
    uint128 gasLimitVal = 150_000;

    function setUp() public {
        PriceFeed _priceFeed = new PriceFeed(address(this), "test");
        _priceFeed.setRateReceiver(address(this));
        _priceFeed.setRate(uint128(block.timestamp), 123);
        priceFeed = address(_priceFeed);

        // mock coreBridge.chainId()
        vm.mockCall(coreBridge, abi.encodeWithSignature("chainId()"), abi.encode(uint16(2)));
    }

    function test_gasLimit() public {
        PriceFeedSender priceFeedSender =
            new PriceFeedSender(address(this), priceFeed, coreBridge, executor, gasLimitVal);
        assertEq(priceFeedSender.gasLimit(), gasLimitVal);
    }

    function test_setPeer() public {
        PriceFeedSender priceFeedSender =
            new PriceFeedSender(address(this), priceFeed, coreBridge, executor, gasLimitVal);

        address peerAddress = address(0xABCD);
        uint16 targetChain = 23;

        priceFeedSender.setPeer(targetChain, peerAddress);
        assertNotEq(priceFeedSender.peers(targetChain), bytes32(0));
    }

    function test_setPeerRevertsForNonOwner() public {
        PriceFeedSender priceFeedSender =
            new PriceFeedSender(address(this), priceFeed, coreBridge, executor, gasLimitVal);

        vm.prank(address(0xBEEF));
        vm.expectRevert();
        priceFeedSender.setPeer(23, address(0xABCD));
    }

    function test_syncRate() public {
        PriceFeedSender priceFeedSender =
            new PriceFeedSender(address(this), priceFeed, coreBridge, executor, gasLimitVal);

        uint16 targetChain = 23;
        address refundAddress = address(this);
        uint256 totalCost = 0.01 ether;
        bytes memory signedQuote = hex"deadbeef";

        // set peer for target chain
        priceFeedSender.setPeer(targetChain, address(0xABCD));

        // mock coreBridge.messageFee()
        vm.mockCall(coreBridge, abi.encodeWithSignature("messageFee()"), abi.encode(uint256(0)));

        // mock coreBridge.publishMessage()
        vm.mockCall(coreBridge, abi.encodeWithSignature("publishMessage(uint32,bytes,uint8)"), abi.encode(uint64(1)));

        // mock executor.requestExecution()
        vm.mockCall(
            executor,
            abi.encodeWithSignature("requestExecution(uint16,bytes32,address,bytes,bytes,bytes)"),
            abi.encode()
        );

        snapStart("PriceFeedSender_syncRate");
        priceFeedSender.syncRate{value: totalCost}(targetChain, refundAddress, totalCost, signedQuote);
        snapEnd();
    }
}
