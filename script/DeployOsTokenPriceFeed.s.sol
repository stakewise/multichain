// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {PriceFeed} from "../src/priceFeed/PriceFeed.sol";

contract DeployOsTokenPriceFeed is Script {
    function run() external {
        vm.startBroadcast();
        console2.log("Deploying from: ", msg.sender);

        // Deploy PriceFeed.
        PriceFeed priceFeed = new PriceFeed(msg.sender, "osETH/ETH");
        console2.log("PriceFeed deployed at: ", address(priceFeed));

        vm.stopBroadcast();
    }

    // excludes this contract from coverage report
    function test() public {}
}
