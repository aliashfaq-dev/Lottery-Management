// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal EIP-712 typed-data hashing and signature verification example.
contract EIP712Mail {
    bytes32 private constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant MAIL_TYPEHASH =
        keccak256("Mail(address from,address to,string contents)");
    bytes32 private immutable NAME_HASH;
    bytes32 private immutable VERSION_HASH;

    constructor() {
        NAME_HASH = keccak256(bytes("LotteryAssignments"));
        VERSION_HASH = keccak256(bytes("1"));
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, NAME_HASH, VERSION_HASH,
            block.chainid, address(this)));
    }

    function hashMail(address from, address to, string calldata contents) public view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(MAIL_TYPEHASH, from, to, keccak256(bytes(contents))));
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator(), structHash));
    }

    function verifyMail(address signer, address from, address to, string calldata contents,
        uint8 v, bytes32 r, bytes32 s) external view returns (bool)
    {
        require(uint256(s) <= 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0, "High-s");
        require(v == 27 || v == 28, "Invalid-v");
        return signer != address(0) && ecrecover(hashMail(from, to, contents), v, r, s) == signer;
    }
}
