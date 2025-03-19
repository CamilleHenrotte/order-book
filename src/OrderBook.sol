// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
contract OrderBook {
    using ECDSA for bytes32;
    function executeOrder() public {}

    function verify(
        string calldata message,
        bytes calldata signature,
        address verifyingAddress
    ) public view {
        bytes32 signedMessageHash = keccak256(abi.encode(message))
            .toEthSignedMessageHash();
        require(
            signedMessageHash.recover(signature) == verifyingAddress,
            "signature not valid v2"
        );
    }
}
