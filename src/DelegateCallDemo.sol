// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev Storage layout must match between caller and delegated implementation.
contract NumberLogic {
    uint256 public number;
    address public lastCaller;
    function setNumber(uint256 value) external {
        number = value;
        lastCaller = msg.sender;
    }
}

/// @notice Demonstrates delegatecall: implementation code runs using this contract's storage.
contract DelegateCallDemo {
    uint256 public number;
    address public lastCaller;
    address public immutable logic;

    constructor(address _logic) {
        require(_logic.code.length > 0, "Logic has no code");
        logic = _logic;
    }

    function setNumberViaDelegateCall(uint256 value) external {
        (bool success, bytes memory result) =
            logic.delegatecall(abi.encodeWithSignature("setNumber(uint256)", value));
        if (!success) assembly { revert(add(result, 32), mload(result)) }
    }
}
