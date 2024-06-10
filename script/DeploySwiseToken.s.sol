// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {SwiseToken} from "../src/tokens/SwiseToken.sol";

contract DeploySwiseToken is Script {
    function run() external {
        vm.startBroadcast();
        console2.log("Deploying from: ", msg.sender);

        // Deploy SwiseToken.
        SwiseToken swiseToken = new SwiseToken(msg.sender, "StakeWise", "SWISE");
        console2.log("SwiseToken deployed at: ", address(swiseToken));

        vm.stopBroadcast();
    }

    // excludes this contract from coverage report
    function test() public {}
}
