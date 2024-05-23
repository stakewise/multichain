// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {PriceFeedSender} from "../../src/priceFeed/PriceFeedSender.sol";
import {PriceFeed} from "../../src/priceFeed/PriceFeed.sol";

contract PriceFeedSenderTest is Test, GasSnapshot {
    address priceFeed;
    address wormholeRelayer = address(1);
    uint256 gasLimit = 1000000;
    uint16 chainId = 2;

    function setUp() public {
        PriceFeed _priceFeed = new PriceFeed(address(this), "test");
        _priceFeed.setRateReceiver(address(this));
        _priceFeed.setRate(uint128(block.timestamp), 123);
        priceFeed = address(_priceFeed);
    }

    function test_quoteRateSync() public {
        PriceFeedSender priceFeedSender = new PriceFeedSender(priceFeed, wormholeRelayer, gasLimit, chainId);

        uint16 targetChain = 2;
        uint256 cost = 10;
        vm.mockCall(
            wormholeRelayer,
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("quoteEVMDeliveryPrice(uint16,uint256,uint256)"))), targetChain, 0, gasLimit
            ),
            abi.encode(cost, 0)
        );
        assertEq(priceFeedSender.quoteRateSync(targetChain), cost);
    }

    function test_syncRate() public {
        PriceFeedSender priceFeedSender = new PriceFeedSender(priceFeed, wormholeRelayer, gasLimit, chainId);

        uint16 targetChain = 2;
        address targetAddress = address(3);
        uint256 cost = 10;
        vm.mockCall(
            wormholeRelayer,
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("quoteEVMDeliveryPrice(uint16,uint256,uint256)"))), targetChain, 0, gasLimit
            ),
            abi.encode(cost, 0)
        );
        vm.expectRevert(PriceFeedSender.InsufficientFunds.selector);
        priceFeedSender.syncRate(targetChain, targetAddress);

        vm.expectRevert(PriceFeedSender.InsufficientFunds.selector);
        priceFeedSender.syncRate{value: cost - 1}(targetChain, targetAddress);

        vm.mockCall(
            wormholeRelayer,
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("sendPayloadToEvm(uint16,address,bytes,uint256,uint256,uint16,address)"))),
                targetChain,
                targetAddress,
                abi.encode(uint128(block.timestamp), 123),
                0,
                gasLimit,
                chainId,
                address(this)
            ),
            abi.encode(1)
        );
        snapStart("PriceFeedReceiver_syncRate");
        priceFeedSender.syncRate{value: cost}(targetChain, targetAddress);
        snapEnd();
    }
}
