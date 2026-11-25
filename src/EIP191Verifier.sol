// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Verifies an Ethereum Signed Message (EIP-191 personal_sign) signature.
contract EIP191Verifier {
    function getMessageHash(address account, uint256 amount, string calldata message)
        public pure returns (bytes32)
    {
        return keccak256(abi.encode(account, amount, message));
    }

    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function recoverSigner(bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        public pure returns (address)
    {
        require(uint256(s) <= 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0, "High-s");
        require(v == 27 || v == 28, "Invalid-v");
        return ecrecover(digest, v, r, s);
    }

    function verify(address signer, address account, uint256 amount, string calldata message,
        uint8 v, bytes32 r, bytes32 s) external pure returns (bool)
    {
        bytes32 digest = getEthSignedMessageHash(getMessageHash(account, amount, message));
        return signer != address(0) && recoverSigner(digest, v, r, s) == signer;
    }
}
