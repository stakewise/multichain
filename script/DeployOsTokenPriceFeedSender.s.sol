// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {PriceFeedSender} from "../src/priceFeed/PriceFeedSender.sol";

contract DeployOsTokenPriceFeedSender is Script {
    struct ConfigParams {
        address governor;
        address sourceFeed;
        address coreBridge;
        address executor;
    }

    function _readEnvVariables() internal view returns (ConfigParams memory params) {
        params.governor = vm.envAddress("PRICE_FEED_SENDER_GOVERNOR");
        params.sourceFeed = vm.envAddress("PRICE_FEED_SENDER_SOURCE_FEED");
        params.coreBridge = vm.envAddress("PRICE_FEED_SENDER_CORE_BRIDGE");
        params.executor = vm.envAddress("PRICE_FEED_SENDER_EXECUTOR");
    }

    function run() external {
        vm.startBroadcast();

        console2.log("Deploying from: ", msg.sender);

        // Read environment variables.
        ConfigParams memory params = _readEnvVariables();

        // Deploy PriceFeedSender.
        PriceFeedSender priceFeedSender =
            new PriceFeedSender(params.governor, params.sourceFeed, params.coreBridge, params.executor, 150_000);
        console2.log("PriceFeedSender deployed at: ", address(priceFeedSender));

        vm.stopBroadcast();
    }

    // excludes this contract from coverage report
    function test() public {}
}
