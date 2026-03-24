// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {PriceFeed} from "../src/priceFeed/PriceFeed.sol";
import {PriceFeedReceiver} from "../src/priceFeed/PriceFeedReceiver.sol";

contract DeployOsTokenPriceFeedReceiver is Script {
    struct ConfigParams {
        address priceFeed;
        address coreBridge;
        address sender;
        uint16 senderChainId;
    }

    function _readEnvVariables() internal view returns (ConfigParams memory params) {
        params.priceFeed = vm.envAddress("PRICE_FEED");
        params.coreBridge = vm.envAddress("PRICE_FEED_RECEIVER_CORE_BRIDGE");
        params.sender = vm.envAddress("PRICE_FEED_SENDER");
        params.senderChainId = uint16(vm.envUint("PRICE_FEED_SENDER_CHAIN_ID"));
    }

    function run() external {
        vm.startBroadcast();
        console2.log("Deploying from: ", msg.sender);

        // Read environment variables.
        ConfigParams memory params = _readEnvVariables();

        // Deploy PriceFeedReceiver.
        PriceFeedReceiver priceFeedReceiver =
            new PriceFeedReceiver(params.priceFeed, params.coreBridge, params.senderChainId, params.sender);
        console2.log("PriceFeedReceiver deployed at: ", address(priceFeedReceiver));

        // Set PriceFeedReceiver for the PriceFeed.
        PriceFeed(params.priceFeed).setRateReceiver(address(priceFeedReceiver));
        console2.log("The price feed receiver is set to: ", address(priceFeedReceiver));

        vm.stopBroadcast();
    }

    // excludes this contract from coverage report
    function test() public {}
}
