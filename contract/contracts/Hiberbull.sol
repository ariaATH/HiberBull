pragma solidity ^0.8.20;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router.sol";
/**
 * @title Hiberbull Token
 * @dev ERC20 Token with a fixed supply, owned by the deployer.
 */
contract Hiberbull is ERC20, Ownable {
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public burnFee = 1;  // 1%
    int256 public liquidityFee = 4; // 4%
