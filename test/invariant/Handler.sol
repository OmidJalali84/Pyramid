// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Ponzi} from "../../src/Ponzi.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Handler is Test {
    IERC20 tether;
    Ponzi ponzi;
    address owner;
    uint256 ENTRY_AMOUNT = 100e18;

    constructor(Ponzi _ponzi, address _tether, address _owner) {
        ponzi = _ponzi;
        tether = IERC20(_tether);
        owner = _owner;
    }

    function register(address user) public {
        vm.assume(
            user != address(0) &&
                user != address(this) &&
                user != address(ponzi)
        );

        if (user == owner) {
            return;
        }

        address[] memory users = ponzi.getUsers();
        for (uint256 i; i < users.length; i++) {
            if (user == users[i]) {
                return;
            }
        }
        tether.transfer(user, ENTRY_AMOUNT);
        vm.startPrank(user);
        tether.approve(address(ponzi), ENTRY_AMOUNT);
        ponzi.register(owner);
        vm.stopPrank();
    }
}
