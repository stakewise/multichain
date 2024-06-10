// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ERC20Permit, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Errors} from "@stakewise-core/libraries/Errors.sol";

/**
 * @title SwiseToken
 * @author StakeWise
 * @notice SwiseToken is an ERC20 token with permit and minting functionality
 */
contract SwiseToken is Ownable2Step, ERC20Permit {
    /**
     * @notice Emitted when the controller is updated
     * @param newController The address of the new controller
     */
    event ControllerUpdated(address newController);

    address public controller;

    /**
     * @dev Constructor
     * @param _owner The address of the contract owner
     * @param _name The name of the ERC20 token
     * @param _symbol The symbol of the ERC20 token
     */
    constructor(address _owner, string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
        Ownable(_owner)
    {}

    /**
     * @dev Throws if called by any account other than the controller.
     */
    modifier onlyController() {
        if (msg.sender != controller) revert Errors.AccessDenied();
        _;
    }

    /**
     * @notice Mint SwiseToken. Can only be called by the controller.
     * @param account The address of the account to mint SwiseToken for
     * @param value The amount of SwiseToken to mint
     */
    function mint(address account, uint256 value) external onlyController {
        _mint(account, value);
    }

    /**
     * @notice Burn SwiseToken. Can only be called by the controller.
     * @param account The address of the account to burn SwiseToken for
     * @param value The amount of SwiseToken to burn
     */
    function burn(address account, uint256 value) external onlyController {
        _burn(account, value);
    }

    /**
     * @notice Set the controller address. Can only be called by the owner.
     * @param newController The address of the new controller
     */
    function setController(address newController) external onlyOwner {
        if (newController == address(0)) revert Errors.ZeroAddress();
        controller = newController;
        emit ControllerUpdated(newController);
    }
}
