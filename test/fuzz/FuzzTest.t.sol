// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Ponzi} from "../../src/Ponzi.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Tether} from "../mock/Token.sol";

contract FuzzTest is Test {
    Tether tether;
    Ponzi ponzi;
    address owner;
    uint256 ENTRY_AMOUNT = 100e18;

    function setUp() public {
        tether = new Tether();
        owner = address(1);
        ponzi = new Ponzi(address(tether), owner);
    }

    function test_fuzz_register(address user) public {
        vm.assume(
            user != address(0) &&
                user != owner &&
                user != address(this) &&
                user != address(ponzi)
        );
        tether.transfer(user, ENTRY_AMOUNT);
        vm.startPrank(user);
        tether.approve(address(ponzi), ENTRY_AMOUNT);
        ponzi.register(owner);
        vm.stopPrank();
    }
}
