// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Educational multisig: a transaction executes only after threshold confirmations.
contract MultisigWallet {
    struct Transaction { address to; uint256 value; bytes data; bool executed; }
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public immutable requiredConfirmations;
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    event Submit(uint256 indexed txId, address indexed proposer, address to, uint256 value);
    event Confirm(uint256 indexed txId, address indexed owner);
    event Revoke(uint256 indexed txId, address indexed owner);
    event Execute(uint256 indexed txId);

    modifier onlyOwner() { require(isOwner[msg.sender], "Not owner"); _; }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid threshold");
        for (uint256 i; i < _owners.length; ++i) {
            address account = _owners[i];
            require(account != address(0) && !isOwner[account], "Invalid/duplicate owner");
            isOwner[account] = true;
            owners.push(account);
        }
        requiredConfirmations = _required;
    }

    function submit(address to, uint256 value, bytes calldata data) external onlyOwner returns (uint256 txId) {
        require(to != address(0), "Invalid target");
        txId = transactions.length;
        transactions.push(Transaction(to, value, data, false));
        emit Submit(txId, msg.sender, to, value);
        _confirm(txId);
    }

    function confirm(uint256 txId) external onlyOwner { _confirm(txId); }
    function _confirm(uint256 txId) private {
        require(txId < transactions.length, "Unknown transaction");
        require(!transactions[txId].executed, "Already executed");
        require(!isConfirmed[txId][msg.sender], "Already confirmed");
        isConfirmed[txId][msg.sender] = true;
        emit Confirm(txId, msg.sender);
    }

    function revoke(uint256 txId) external onlyOwner {
        require(txId < transactions.length, "Unknown transaction");
        require(!transactions[txId].executed, "Already executed");
        require(isConfirmed[txId][msg.sender], "Not confirmed");
        isConfirmed[txId][msg.sender] = false;
        emit Revoke(txId, msg.sender);
    }

    function execute(uint256 txId) external onlyOwner {
        require(txId < transactions.length, "Unknown transaction");
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "Already executed");
        uint256 confirmations;
        for (uint256 i; i < owners.length; ++i) {
            if (isConfirmed[txId][owners[i]]) ++confirmations;
        }
        require(confirmations >= requiredConfirmations, "Not enough confirmations");
        txn.executed = true;
        (bool success, bytes memory result) = txn.to.call{value: txn.value}(txn.data);
        if (!success) {
            assembly { revert(add(result, 32), mload(result)) }
        }
        emit Execute(txId);
    }

    receive() external payable {}
}
