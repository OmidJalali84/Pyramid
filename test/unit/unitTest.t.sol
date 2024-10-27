// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Ponzi} from "../../src/Ponzi.sol";
import {Tether} from "../mock/Token.sol";

contract PonziUnitTest is Test {
    Ponzi ponzi;
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
        ponzi = new Ponzi(address(tether), owner);
    }

    function register(address user) public {
        tether.transfer(user, ENTRY_AMOUNT);
        vm.startPrank(user);
        tether.approve(address(ponzi), ENTRY_AMOUNT);
        ponzi.register(owner);
        vm.stopPrank();
    }

    function register(address user, address uplineAddress) public {
        tether.transfer(user, ENTRY_AMOUNT);
        vm.startPrank(user);
        tether.approve(address(ponzi), ENTRY_AMOUNT);
        ponzi.register(uplineAddress);
        vm.stopPrank();
    }

    function testRegistersUsers() public {
        register(user1);
        vm.assertEq(ponzi.getTodayInvites(owner), 0);
        vm.assertEq(ponzi.getUserId(user1), 1);
        register(user2, user1);
        vm.assertEq(ponzi.getTodayInvites(user1), 1);
        vm.assertEq(ponzi.getUserId(user2), 2);
        vm.assertEq(ponzi.getUserNode(user1).todayInvites, 1);
        vm.assertEq(ponzi.getUserNode(user1).totalInvites, 1);
        vm.assertEq(ponzi.getUserUpline(user2), user1);
        vm.assertEq(ponzi.getTotalRegistersCount(), 2);
        vm.assertEq(ponzi.getUsers()[0], user1);
        vm.assertEq(ponzi.getUsers()[1], user2);
        vm.assertEq(ponzi.getContractBalance(), 200e18);
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

        ponzi.reward_24();
        vm.assertEq(tether.balanceOf(user1), 60e18);
        vm.assertEq(ponzi.getTodayInvites(user1), 0);
        vm.assertEq(ponzi.getTodayInvites(user2), 0);
        vm.assertEq(ponzi.getTodayInvites(user3), 0);
        vm.assertEq(ponzi.getUserNode(user1).todayInvites, 0);
        vm.assertEq(ponzi.getUserNode(user1).totalInvites, 3);
        vm.assertEq(ponzi.getLastDonateTime(), block.timestamp);
        vm.assertEq(ponzi.getLastDonateAmount(), 60e18);

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

        ponzi.reward_24();
        vm.assertEq(tether.balanceOf(user1), 60e18);
        vm.assertEq(tether.balanceOf(user2), 60e18);
        vm.assertEq(ponzi.getLastWinners()[0], user1);
        vm.assertEq(ponzi.getLastWinners()[1], user2);
        vm.assertEq(ponzi.getTotalWinners()[0], user1);
        vm.assertEq(ponzi.getTotalWinners()[1], user2);

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
        ponzi.changeToken(address(20));
        vm.assertEq(address(20), ponzi.token());
    }

    function testTransferOwnership() public {
        vm.prank(owner);
        ponzi.transferOwnership(user1);
        vm.expectRevert();
        vm.prank(owner);
        ponzi.transferOwnership(owner);
        vm.prank(user1);
        ponzi.transferOwnership(owner);
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
        ponzi.emergency_24();
        vm.assertEq(tether.balanceOf(user1), 100e18);
        vm.assertEq(tether.balanceOf(user2), 100e18);
        vm.assertEq(tether.balanceOf(user3), 100e18);
        vm.assertEq(tether.balanceOf(user4), 100e18);
        vm.assertEq(tether.balanceOf(user5), 100e18);
        vm.assertEq(tether.balanceOf(user6), 100e18);
        vm.assertEq(tether.balanceOf(user7), 100e18);
    }
}
