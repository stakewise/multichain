// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Errors} from "@stakewise-core/libraries/Errors.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {OsToken, IOsToken} from "../src/OsToken.sol";
import {SigUtils} from "./helpers/SigUtils.sol";

contract OsTokenTest is Test, GasSnapshot {
    OsToken osToken;

    function setUp() public {
        osToken = new OsToken(address(this), "test", "test");
    }

    function test_setController() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(1)));
        vm.prank(address(1));
        osToken.setController(address(1), true);

        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddress.selector));
        osToken.setController(address(0), true);

        vm.expectEmit(true, false, false, true);
        emit IOsToken.ControllerUpdated(address(1), true);

        snapStart("OsToken_setController");
        osToken.setController(address(1), true);
        snapEnd();

        assertEq(osToken.controllers(address(1)), true);
    }

    function test_mint() public {
        vm.expectRevert(Errors.AccessDenied.selector);
        vm.prank(address(1));
        osToken.mint(address(1), 1);

        osToken.setController(address(this), true);

        snapStart("OsToken_mint");
        osToken.mint(address(1), 1);
        snapEnd();

        assertEq(osToken.balanceOf(address(1)), 1);
    }

    function test_burn() public {
        vm.expectRevert(Errors.AccessDenied.selector);
        vm.prank(address(1));
        osToken.burn(address(1), 1);

        osToken.setController(address(this), true);
        osToken.mint(address(1), 1);

        snapStart("OsToken_burn");
        osToken.burn(address(1), 1);
        snapEnd();

        assertEq(osToken.balanceOf(address(1)), 0);
    }

    function test_Permit() public {
        uint256 ownerPrivateKey = 0xA11CE;
        address owner = vm.addr(ownerPrivateKey);
        address spender = address(1);

        SigUtils sigUtils = new SigUtils(osToken.DOMAIN_SEPARATOR());
        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: owner, spender: spender, value: 1e18, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        snapStart("OsToken_permit");
        osToken.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
        snapEnd();

        assertEq(osToken.allowance(owner, spender), 1e18);
        assertEq(osToken.nonces(owner), 1);
    }
}
