// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Errors} from "@stakewise-core/libraries/Errors.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {SwiseToken} from "../../src/tokens/SwiseToken.sol";
import {SigUtils} from "../helpers/SigUtils.sol";

contract SwiseTokenTest is Test, GasSnapshot {
    SwiseToken swiseToken;

    function setUp() public {
        swiseToken = new SwiseToken(address(this), "test", "test");
    }

    function test_setController() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(1)));
        vm.prank(address(1));
        swiseToken.setController(address(1));

        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddress.selector));
        swiseToken.setController(address(0));

        vm.expectEmit(false, false, false, true);
        emit SwiseToken.ControllerUpdated(address(1));

        snapStart("SwiseToken_setController");
        swiseToken.setController(address(1));
        snapEnd();

        assertEq(swiseToken.controller(), address(1));
    }

    function test_mint() public {
        vm.expectRevert(Errors.AccessDenied.selector);
        vm.prank(address(1));
        swiseToken.mint(address(1), 1);

        swiseToken.setController(address(this));

        snapStart("SwiseToken_mint");
        swiseToken.mint(address(1), 1);
        snapEnd();

        assertEq(swiseToken.balanceOf(address(1)), 1);
    }

    function test_burn() public {
        vm.expectRevert(Errors.AccessDenied.selector);
        vm.prank(address(1));
        swiseToken.burn(address(1), 1);

        swiseToken.setController(address(this));
        swiseToken.mint(address(1), 1);

        snapStart("SwiseToken_burn");
        swiseToken.burn(address(1), 1);
        snapEnd();

        assertEq(swiseToken.balanceOf(address(1)), 0);
    }

    function test_Permit() public {
        uint256 ownerPrivateKey = 0xA11CE;
        address owner = vm.addr(ownerPrivateKey);
        address spender = address(1);

        SigUtils sigUtils = new SigUtils(swiseToken.DOMAIN_SEPARATOR());
        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: owner, spender: spender, value: 1e18, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        snapStart("SwiseToken_permit");
        swiseToken.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
        snapEnd();

        assertEq(swiseToken.allowance(owner, spender), 1e18);
        assertEq(swiseToken.nonces(owner), 1);
    }
}
