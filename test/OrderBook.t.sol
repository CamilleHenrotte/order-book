// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OrderBook} from "../src/OrderBook.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract OrderBookTest is Test {
    OrderBook orderBook;
    uint256 user1PrivateKey = 1;
    uint256 user2PrivateKey = 2;
    address user1;
    address user2;
    MockERC20 tokenUser1Gives;
    MockERC20 tokenUser1Gets;
    uint256 amountUser1Gives = 10 ether;
    uint256 amountUser1Gets = 20 ether;

    function setUp() public {
        // Derive addresses from known private keys
        user1 = vm.addr(user1PrivateKey);
        user2 = vm.addr(user2PrivateKey);

        orderBook = new OrderBook();
        tokenUser1Gives = new MockERC20();
        tokenUser1Gets = new MockERC20();

        // Mint tokens to users
        tokenUser1Gives.mint(user1, amountUser1Gives);
        tokenUser1Gets.mint(user2, amountUser1Gets);

        // Approve the OrderBook contract to spend tokens on behalf of users
        vm.prank(user1);
        tokenUser1Gives.approve(address(orderBook), amountUser1Gives);
        vm.prank(user2);
        tokenUser1Gets.approve(address(orderBook), amountUser1Gets);
    }

    function testSetup() public {
        assertEq(tokenUser1Gives.balanceOf(user1), amountUser1Gives);
        assertEq(tokenUser1Gets.balanceOf(user2), amountUser1Gets);
    }

    function testExecuteOrder() public {
        // Set expiry time to be in the future
        uint256 expiryTime = block.timestamp + 100;

        // Construct the message for user1
        OrderBook.Message memory message1 = OrderBook.Message({
            expiryTime: expiryTime,
            signer: user1,
            user: user2,
            tokenSignerGives: address(tokenUser1Gives),
            tokenSignerGets: address(tokenUser1Gets),
            amountSignerGives: amountUser1Gives,
            amountSignerGets: amountUser1Gets,
            blockChainId: block.chainid,
            contractAddress: address(orderBook)
        });

        // Construct the counter message for user2 (with inverted token and amount details)
        OrderBook.Message memory message2 = OrderBook.Message({
            expiryTime: expiryTime,
            signer: user2,
            user: user1,
            tokenSignerGives: address(tokenUser1Gets),
            tokenSignerGets: address(tokenUser1Gives),
            amountSignerGives: amountUser1Gets,
            amountSignerGets: amountUser1Gives,
            blockChainId: block.chainid,
            contractAddress: address(orderBook)
        });

        // Get the message hashes from the contract's helper function
        bytes32 messageHash1 = orderBook.getMessageHash(message1);
        bytes32 messageHash2 = orderBook.getMessageHash(message2);

        // Sign the messages using cheat codes
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(
            user1PrivateKey,
            messageHash1
        );
        bytes memory sig1 = abi.encodePacked(r1, s1, v1);

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(
            user2PrivateKey,
            messageHash2
        );
        bytes memory sig2 = abi.encodePacked(r2, s2, v2);

        // Execute the order using the signed messages
        orderBook.executeOrder(
            expiryTime,
            user1,
            user2,
            address(tokenUser1Gives),
            address(tokenUser1Gets),
            amountUser1Gives,
            amountUser1Gets,
            sig1,
            sig2
        );

        // Verify the token balances after the trade
        assertEq(tokenUser1Gives.balanceOf(user1), 0);
        assertEq(tokenUser1Gets.balanceOf(user2), 0);
        assertEq(tokenUser1Gives.balanceOf(user2), amountUser1Gives);
        assertEq(tokenUser1Gets.balanceOf(user1), amountUser1Gets);
    }
}
