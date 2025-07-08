pragma solidity ^0.8.20;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/**
 * @title Hiberbull Token
 * @dev ERC20 Token with a fixed supply, owned by the deployer.
 */
contract Hiberbull is ERC20, Ownable {
    
