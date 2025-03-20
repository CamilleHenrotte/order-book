// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
contract OrderBook {
    using ECDSA for bytes32;

    mapping(bytes32 => bool) public messageProcessed;

    struct Message {
        uint256 expiryTime;
        address signer;
        address user;
        address tokenSignerGives;
        address tokenSignerGets;
        uint256 amountSignerGives;
        uint256 amountSignerGets;
        uint256 blockChainId;
        address contractAddress;
    }

    function executeOrder(
        uint256 expiryTime,
        address user1,
        address user2,
        address tokenUser1Gives,
        address tokenUser1Gets,
        uint256 amountUser1Gives,
        uint256 amountUser1Gets,
        bytes calldata signatureUser1,
        bytes calldata signatureUser2
    ) external {
        require(block.timestamp < expiryTime, "Order expired");

        Message memory message1 = Message({
            expiryTime: expiryTime,
            signer: user1,
            user: user2,
            tokenSignerGives: tokenUser1Gives,
            tokenSignerGets: tokenUser1Gets,
            amountSignerGives: amountUser1Gives,
            amountSignerGets: amountUser1Gets,
            blockChainId: block.chainid,
            contractAddress: address(this)
        });

        Message memory message2 = Message({
            expiryTime: expiryTime,
            signer: user2,
            user: user1,
            tokenSignerGives: tokenUser1Gets,
            tokenSignerGets: tokenUser1Gives,
            amountSignerGives: amountUser1Gets,
            amountSignerGets: amountUser1Gives,
            blockChainId: block.chainid,
            contractAddress: address(this)
        });

        bytes32 messageHash1 = getMessageHash(message1);
        bytes32 messageHash2 = getMessageHash(message2);

        require(
            verify(messageHash1, signatureUser1, user1),
            "Invalid signature for user1"
        );
        require(
            verify(messageHash2, signatureUser2, user2),
            "Invalid signature for user2"
        );

        require(
            !messageProcessed[messageHash1],
            "Order already processed for user1"
        );
        require(
            !messageProcessed[messageHash2],
            "Order already processed for user2"
        );

        require(
            IERC20(tokenUser1Gives).transferFrom(
                user1,
                user2,
                amountUser1Gives
            ),
            "Transfer from user1 failed"
        );
        require(
            IERC20(tokenUser1Gets).transferFrom(user2, user1, amountUser1Gets),
            "Transfer from user2 failed"
        );

        messageProcessed[messageHash1] = true;
        messageProcessed[messageHash2] = true;
    }

    function verify(
        bytes32 signedMessageHash,
        bytes calldata signature,
        address verifyingAddress
    ) public pure returns (bool) {
        return ECDSA.recover(signedMessageHash, signature) == verifyingAddress;
    }

    function getMessageHash(
        Message memory message
    ) public pure returns (bytes32) {
        return
            MessageHashUtils.toEthSignedMessageHash(
                keccak256(
                    abi.encode(
                        message.expiryTime,
                        message.signer,
                        message.user,
                        message.tokenSignerGives,
                        message.tokenSignerGets,
                        message.amountSignerGives,
                        message.amountSignerGets,
                        message.blockChainId,
                        message.contractAddress
                    )
                )
            );
    }
}
