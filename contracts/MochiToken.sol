pragma solidity ^0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "./libraries/ERC20Governance.sol";

contract MochiToken is 
    ERC20, 
    ERC20Detailed( "MochiSwap Token", "hMOCHI", 18), 
    ERC20Burnable, 
    ERC20Mintable,
    ERC20Capped(100000000 * 1e18),
    ERC20Governance
{}
