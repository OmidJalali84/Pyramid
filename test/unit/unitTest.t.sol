// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Pyramid} from "../../src/Pyramid.sol";
import {Tether} from "../mock/Token.sol";

contract PyramidUnitTest is Test {
    Pyramid pyramid;
    Tether tether;

    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);
    address user3 = address(4);
    address user4 = address(5);
    address user5 = address(6);
    address user6 = address(7);
    address user7 = address(8);

    uint256 ENTRY_AMOUNT = 1e20;

    function setUp() public {
        tether = new Tether();
        pyramid = new Pyramid(address(tether), owner);
    }

    function register(address user) public {
        tether.transfer(user, ENTRY_AMOUNT);
        vm.startPrank(user);
        tether.approve(address(pyramid), ENTRY_AMOUNT);
        pyramid.register(owner);
        vm.stopPrank();
    }

    function register(address user, address uplineAddress) public {
        tether.transfer(user, ENTRY_AMOUNT);
        vm.startPrank(user);
        tether.approve(address(pyramid), ENTRY_AMOUNT);
        pyramid.register(uplineAddress);
        vm.stopPrank();
    }

    function testRegistersUsers() public {
        register(user1);
        vm.assertEq(pyramid.getTodayInvites(owner), 0);
        vm.assertEq(pyramid.getUserId(user1), 1);
        register(user2, user1);
        vm.assertEq(pyramid.getTodayInvites(user1), 1);
        vm.assertEq(pyramid.getUserId(user2), 2);
        vm.assertEq(pyramid.getUserNode(user1).todayInvites, 1);
        vm.assertEq(pyramid.getUserNode(user1).totalInvites, 1);
        vm.assertEq(pyramid.getUserUpline(user2), user1);
        vm.assertEq(pyramid.getTotalRegistersCount(), 2);
        vm.assertEq(pyramid.getUsers()[0], user1);
        vm.assertEq(pyramid.getUsers()[1], user2);
        vm.assertEq(pyramid.getContractBalance(), 200e18);
    }

    function testChoosesBestInviter() public {
        register(user1);
        register(user2, user1);
        register(user3, user1);
        register(user4, user1);
        register(user5, user2);
        register(user6, user2);
        register(user7, user3);

        vm.warp(block.timestamp + 24 hours);

        pyramid.reward_24();
        vm.assertEq(tether.balanceOf(user1), 60e18);
        vm.assertEq(pyramid.getTodayInvites(user1), 0);
        vm.assertEq(pyramid.getTodayInvites(user2), 0);
        vm.assertEq(pyramid.getTodayInvites(user3), 0);
        vm.assertEq(pyramid.getUserNode(user1).todayInvites, 0);
        vm.assertEq(pyramid.getUserNode(user1).totalInvites, 3);
        vm.assertEq(pyramid.getLastDonateTime(), block.timestamp);
        vm.assertEq(pyramid.getLastDonateAmount(), 60e18);

        vm.assertEq(tether.balanceOf(owner), 640e18);
    }

    function testChoosesBestInviters() public {
        register(user1);
        register(user2, user1);
        register(user3, user1);
        register(user4, user1);
        register(user5, user2);
        register(user6, user2);
        register(user7, user2);

        vm.warp(block.timestamp + 24 hours);

        pyramid.reward_24();
        vm.assertEq(tether.balanceOf(user1), 60e18);
        vm.assertEq(tether.balanceOf(user2), 60e18);
        vm.assertEq(pyramid.getLastWinners()[0], user1);
        vm.assertEq(pyramid.getLastWinners()[1], user2);
        vm.assertEq(pyramid.getTotalWinners()[0], user1);
        vm.assertEq(pyramid.getTotalWinners()[1], user2);

        vm.assertEq(tether.balanceOf(owner), 580e18);
    }

    function testFailsIfNotValidUplines() public {
        vm.expectRevert();
        register(user1, user2);

        register(user1);
        vm.expectRevert();
        register(user1, user1);

        register(user2);
        vm.expectRevert();
        register(user2);
    }

    function testChangesToken() public {
        vm.prank(owner);
        pyramid.changeToken(address(20));
        vm.assertEq(address(20), pyramid.token());
    }

    function testTransferOwnership() public {
        vm.prank(owner);
        pyramid.transferOwnership(user1);
        vm.expectRevert();
        vm.prank(owner);
        pyramid.transferOwnership(owner);
        vm.prank(user1);
        pyramid.transferOwnership(owner);
    }

    function testEmergency() public {
        register(user1);
        register(user2, user1);
        register(user3, user1);
        register(user4, user1);
        register(user5, user2);
        register(user6, user2);
        register(user7, user3);

        vm.assertEq(tether.balanceOf(user1), 0);

        vm.prank(owner);
        pyramid.emergency_24();
        vm.assertEq(tether.balanceOf(user1), 100e18);
        vm.assertEq(tether.balanceOf(user2), 100e18);
        vm.assertEq(tether.balanceOf(user3), 100e18);
        vm.assertEq(tether.balanceOf(user4), 100e18);
        vm.assertEq(tether.balanceOf(user5), 100e18);
        vm.assertEq(tether.balanceOf(user6), 100e18);
        vm.assertEq(tether.balanceOf(user7), 100e18);
    }
}
