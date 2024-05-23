// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {PriceFeed} from "../src/priceFeed/PriceFeed.sol";
import {PriceFeedReceiver} from "../src/priceFeed/PriceFeedReceiver.sol";

contract DeployOsTokenPriceFeed is Script {
    struct PriceFeedReceiverParams {
        address wormholeRelayer;
        address sender;
        uint16 senderChainId;
    }

    function _readEnvVariables() internal view returns (PriceFeedReceiverParams memory params) {
        params.wormholeRelayer = vm.envAddress("PRICE_FEED_RECEIVER_WORMHOLE_RELAYER");
        params.sender = vm.envAddress("PRICE_FEED_SENDER");
        params.senderChainId = uint16(vm.envUint("PRICE_FEED_SENDER_CHAIN_ID"));
    }

    function run() external {
        vm.startBroadcast();
        console2.log("Deploying from: ", msg.sender);

        // Deploy PriceFeed.
        PriceFeed priceFeed = new PriceFeed(msg.sender, "osETH/ETH");
        console2.log("PriceFeed deployed at: ", address(priceFeed));

        // Deploy PriceFeedReceiver.
        PriceFeedReceiverParams memory params = _readEnvVariables();
        PriceFeedReceiver priceFeedReceiver =
            new PriceFeedReceiver(address(priceFeed), params.wormholeRelayer, params.senderChainId, params.sender);
        console2.log("PriceFeedReceiver deployed at: ", address(priceFeedReceiver));

        // Set PriceFeedReceiver for the PriceFeed.
        priceFeed.setRateReceiver(address(priceFeedReceiver));
        console2.log("The price feed receiver is set to: ", address(priceFeedReceiver));

        vm.stopBroadcast();
    }

    // excludes this contract from coverage report
    function test() public {}
}
