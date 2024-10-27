// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {Handler} from "./Handler.sol";
import {Tether} from "../mock/Token.sol";
import {Pyramid} from "../../src/Pyramid.sol";

contract Invariant is StdInvariant, Test {
    Tether tether;
    Handler handler;
    Pyramid pyramid;
    address owner = address(1);

    function setUp() public {
        tether = new Tether();
        pyramid = new Pyramid(address(tether), owner);
        handler = new Handler(pyramid, address(tether), owner);
        tether.transfer(address(handler), type(uint256).max);
        targetContract(address(handler));
    }

    function invariant_registersAndChoosesBestInviter() public {
        if (pyramid.getTotalRegistersCount() > 100) {
            vm.warp(block.timestamp + 24 hours);

            pyramid.reward_24();
            address[] memory winners = pyramid.getLastWinners();
            for (uint256 i; i < winners.length; i++) {
                vm.assertEq(
                    tether.balanceOf(winners[i]),
                    pyramid.getLastDonateAmount()
                );
            }
        }
    }

    function invariant_emergency() public {
        if (pyramid.getTotalRegistersCount() > 50) {
            address[] memory users = pyramid.getTodayEntries();

            for (uint256 i; i < users.length; i++) {
                vm.assertEq(tether.balanceOf(users[i]), 0);
            }
            vm.prank(owner);
            pyramid.emergency_24();
            for (uint256 i; i < users.length; i++) {
                vm.assertEq(tether.balanceOf(users[i]), 100e18);
            }
        } else {}
    }
}
