// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal educational ERC-1967 proxy + UUPS implementation.
/// Use OpenZeppelin's audited upgradeable contracts for production deployments.
contract UUPSExample {
    // keccak256("eip1967.proxy.implementation") - 1
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address private immutable SELF = address(this);
    address public owner;
    uint256 public value;

    modifier onlyProxy() {
        require(address(this) != SELF, "Must be called through proxy");
        require(_implementation() == SELF, "Invalid proxy context");
        _;
    }
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    function initialize(address initialOwner, uint256 initialValue) external {
        require(owner == address(0), "Already initialized");
        require(initialOwner != address(0), "Zero owner");
        owner = initialOwner;
        value = initialValue;
    }

    function setValue(uint256 newValue) external onlyOwner { value = newValue; }

    function proxiableUUID() external view returns (bytes32) {
        require(address(this) == SELF, "Not direct call");
        return IMPLEMENTATION_SLOT;
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external payable onlyProxy onlyOwner
    {
        require(newImplementation.code.length > 0, "Implementation has no code");
        (bool ok, bytes memory result) = newImplementation.staticcall(
            abi.encodeWithSignature("proxiableUUID()"));
        require(ok && result.length == 32 && abi.decode(result, (bytes32)) == IMPLEMENTATION_SLOT,
            "Unsupported proxiable UUID");
        assembly { sstore(IMPLEMENTATION_SLOT, newImplementation) }
        if (data.length > 0) {
            (bool success, bytes memory returnData) = address(this).delegatecall(data);
            if (!success) assembly { revert(add(returnData, 32), mload(returnData)) }
        } else {
            require(msg.value == 0, "ETH sent without call data");
        }
    }

    function _implementation() internal view returns (address impl) {
        assembly { impl := sload(IMPLEMENTATION_SLOT) }
    }
}

/// @notice Proxy stores implementation in the ERC-1967 slot and delegates all calls.
contract ERC1967ProxyExample {
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address implementation, bytes memory initData) payable {
        require(implementation.code.length > 0, "Implementation has no code");
        assembly { sstore(IMPLEMENTATION_SLOT, implementation) }
        if (initData.length > 0) {
            (bool ok, bytes memory result) = implementation.delegatecall(initData);
            if (!ok) assembly { revert(add(result, 32), mload(result)) }
        }
    }

    fallback() external payable { _delegate(); }
    receive() external payable { _delegate(); }
    function _delegate() private {
        assembly {
            let impl := sload(IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

/// @notice V2 keeps the same storage layout and adds a function.
contract UUPSExampleV2 is UUPSExample {
    function increment() external onlyOwner { value += 1; }
}
