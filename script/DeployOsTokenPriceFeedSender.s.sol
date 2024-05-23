// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {PriceFeedSender} from "../src/priceFeed/PriceFeedSender.sol";

contract DeployOsTokenPriceFeedSender is Script {
    struct ConfigParams {
        address sourceFeed;
        address wormholeRelayer;
        uint16 chainId;
    }

    function _readEnvVariables() internal view returns (ConfigParams memory params) {
        params.sourceFeed = vm.envAddress("PRICE_FEED_SENDER_SOURCE_FEED");
        params.wormholeRelayer = vm.envAddress("PRICE_FEED_SENDER_WORMHOLE_RELAYER");
        params.chainId = uint16(vm.envUint("PRICE_FEED_SENDER_CHAIN_ID"));
    }

    function run() external {
        vm.startBroadcast();

        console2.log("Deploying from: ", msg.sender);

        // Read environment variables.
        ConfigParams memory params = _readEnvVariables();

        // Deploy PriceFeedSender.
        PriceFeedSender priceFeedSender =
            new PriceFeedSender(params.sourceFeed, params.wormholeRelayer, 150_000, params.chainId);
        console2.log("PriceFeedSender deployed at: ", address(priceFeedSender));

        vm.stopBroadcast();
    }

    // excludes this contract from coverage report
    function test() public {}
}
