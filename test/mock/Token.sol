// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Tether is ERC20 {
    uint256 constant TOTAL_SUPPLY = type(uint256).max;

    constructor() ERC20("Tether","USDT") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}
