pragma solidity ^0.5.17;

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract ERC20Mock is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20() public {
        _mint(msg.sender, supply);
    }
}