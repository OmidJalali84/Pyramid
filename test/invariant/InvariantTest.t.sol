// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {Handler} from "./Handler.sol";
import {Tether} from "../mock/Token.sol";
import {Ponzi} from "../../src/Ponzi.sol";

contract Invariant is StdInvariant, Test {
    Tether tether;
    Handler handler;
    Ponzi ponzi;
    address owner = address(1);

    function setUp() public {
        tether = new Tether();
        ponzi = new Ponzi(address(tether), owner);
        handler = new Handler(ponzi, address(tether), owner);
        tether.transfer(address(handler), type(uint256).max);
        targetContract(address(handler));
    }

    function invariant_registersAndChoosesBestInviter() public {
        if (ponzi.getTotalRegistersCount() > 100) {
            vm.warp(block.timestamp + 24 hours);

            ponzi.reward_24();
            address[] memory winners = ponzi.getLastWinners();
            for (uint256 i; i < winners.length; i++) {
                vm.assertEq(
                    tether.balanceOf(winners[i]),
                    ponzi.getLastDonateAmount()
                );
            }
        }
    }

    function invariant_emergency() public {
        if (ponzi.getTotalRegistersCount() > 50) {
            address[] memory users = ponzi.getTodayEntries();

            for (uint256 i; i < users.length; i++) {
                vm.assertEq(tether.balanceOf(users[i]), 0);
            }
            vm.prank(owner);
            ponzi.emergency_24();
            for (uint256 i; i < users.length; i++) {
                vm.assertEq(tether.balanceOf(users[i]), 100e18);
            }
        } else {}
    }
}
