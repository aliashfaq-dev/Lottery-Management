// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CallTarget {
    uint256 public storedNumber;
    event NumberSet(uint256 value, address caller);
    function setNumber(uint256 value) external payable {
        storedNumber = value;
        emit NumberSet(value, msg.sender);
    }
    function fail() external pure { revert("Target reverted"); }
}

/// @notice Demonstrates address.call: executes target code in target storage/context.
contract LowLevelCallDemo {
    event CallResult(bool success, bytes returnData);

    function setTargetNumber(address target, uint256 value) external payable returns (bool, bytes memory) {
        (bool success, bytes memory result) =
            target.call{value: msg.value}(abi.encodeWithSignature("setNumber(uint256)", value));
        emit CallResult(success, result);
        return (success, result);
    }

    function rawCall(address target, bytes calldata data) external payable returns (bool, bytes memory) {
        (bool success, bytes memory result) = target.call{value: msg.value}(data);
        emit CallResult(success, result);
        return (success, result);
    }
}
