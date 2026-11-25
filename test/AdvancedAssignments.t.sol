// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MultisigWallet} from "../src/MultisigWallet.sol";
import {EIP191Verifier} from "../src/EIP191Verifier.sol";
import {EIP712Mail} from "../src/EIP712Mail.sol";
import {EIP3009Token} from "../src/EIP3009Token.sol";
import {CallTarget, LowLevelCallDemo} from "../src/LowLevelCallDemo.sol";
import {NumberLogic, DelegateCallDemo} from "../src/DelegateCallDemo.sol";
import {UUPSExample, UUPSExampleV2, ERC1967ProxyExample} from "../src/UUPSExample.sol";

contract AdvancedAssignmentsTest is Test {
    uint256 private ownerKey = 0xA11CE;
    address private owner = vm.addr(ownerKey);

    function testMultisigNeedsThresholdAndExecutes() public {
        address[] memory owners = new address[](3);
        owners[0] = address(this); owners[1] = address(0xBEEF); owners[2] = address(0xCAFE);
        MultisigWallet wallet = new MultisigWallet(owners, 2);
        CallTarget target = new CallTarget();
        uint256 id = wallet.submit(address(target), 0, abi.encodeCall(target.setNumber, (42)));
        vm.prank(owners[1]); wallet.confirm(id);
        wallet.execute(id);
        assertEq(target.storedNumber(), 42);
    }

    function testMultisigCannotExecuteBelowThreshold() public {
        address[] memory owners = new address[](2);
        owners[0] = address(this); owners[1] = address(0xBEEF);
        MultisigWallet wallet = new MultisigWallet(owners, 2);
        CallTarget target = new CallTarget();
        uint256 id = wallet.submit(address(target), 0, abi.encodeCall(target.setNumber, (7)));
        vm.expectRevert("Not enough confirmations");
        wallet.execute(id);
    }

    function testEIP191PersonalSignVerification() public {
        EIP191Verifier verifier = new EIP191Verifier();
        bytes32 messageHash = verifier.getMessageHash(address(0x1234), 99, "hello");
        bytes32 digest = verifier.getEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, digest);
        assertTrue(verifier.verify(owner, address(0x1234), 99, "hello", v, r, s));
        assertFalse(verifier.verify(address(0xBAD), address(0x1234), 99, "hello", v, r, s));
    }

    function testEIP712TypedMailVerification() public {
        EIP712Mail mail = new EIP712Mail();
        bytes32 digest = mail.hashMail(owner, address(0xBEEF), "Assignment");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, digest);
        assertTrue(mail.verifyMail(owner, owner, address(0xBEEF), "Assignment", v, r, s));
        assertFalse(mail.verifyMail(owner, owner, address(0xBEEF), "Changed", v, r, s));
    }

    function testEIP3009TransferWithAuthorization() public {
        EIP3009Token token = new EIP3009Token(1_000_000e6);
        address recipient = address(0xBEEF);
        uint256 amount = 25e6;
        uint256 validAfter = block.timestamp - 1;
        uint256 validBefore = block.timestamp + 1 days;
        bytes32 nonce = keccak256("unique nonce");
        bytes32 domainTypehash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        bytes32 transferTypehash = keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)");
        bytes32 domain = keccak256(abi.encode(domainTypehash, keccak256("Authorization USD"), keccak256("1"), block.chainid, address(token)));
        bytes32 structHash = keccak256(abi.encode(transferTypehash, owner, recipient, amount, validAfter, validBefore, nonce));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domain, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, digest);
        token.transferWithAuthorization(owner, recipient, amount, validAfter, validBefore, nonce, v, r, s);
        assertEq(token.balanceOf(recipient), amount);
        assertTrue(token.authorizationState(owner, nonce));
        vm.expectRevert("Authorization already used");
        token.transferWithAuthorization(owner, recipient, amount, validAfter, validBefore, nonce, v, r, s);
    }

    function testLowLevelCallUpdatesTargetStorage() public {
        CallTarget target = new CallTarget();
        LowLevelCallDemo caller = new LowLevelCallDemo();
        (bool success,) = caller.setTargetNumber(address(target), 123);
        assertTrue(success);
        assertEq(target.storedNumber(), 123);
    }

    function testDelegatecallUpdatesCallerStorage() public {
        NumberLogic logic = new NumberLogic();
        DelegateCallDemo caller = new DelegateCallDemo(address(logic));
        caller.setNumberViaDelegateCall(456);
        assertEq(caller.number(), 456);
        assertEq(caller.lastCaller(), address(this));
        assertEq(logic.number(), 0);
    }

    function testUUPSUpgradePreservesStorageAndAddsFunction() public {
        UUPSExample implementationV1 = new UUPSExample();
        bytes memory init = abi.encodeCall(UUPSExample.initialize, (address(this), 10));
        ERC1967ProxyExample proxy = new ERC1967ProxyExample(address(implementationV1), init);
        UUPSExample proxiedV1 = UUPSExample(address(proxy));
        assertEq(proxiedV1.value(), 10);
        proxiedV1.setValue(77);

        UUPSExampleV2 implementationV2 = new UUPSExampleV2();
        proxiedV1.upgradeToAndCall(address(implementationV2), "");
        UUPSExampleV2 proxiedV2 = UUPSExampleV2(address(proxy));
        proxiedV2.increment();
        assertEq(proxiedV2.value(), 78);
        assertEq(proxiedV2.owner(), address(this));
    }
}
