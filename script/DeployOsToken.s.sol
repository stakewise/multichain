// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {OsToken} from "../src/OsToken.sol";

contract DeployOsToken is Script {
    function run() external {
        vm.startBroadcast();
        console2.log("Deploying from: ", msg.sender);

        // Deploy OsToken.
        OsToken osToken = new OsToken(msg.sender, "Staked ETH", "osETH");
        console2.log("OsToken deployed at: ", address(osToken));

        vm.stopBroadcast();
    }

    // excludes this contract from coverage report
    function test() public {}
}
