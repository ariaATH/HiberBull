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
    uint256 totalSupply = 10000000000 * 10 ** decimals();
    
    constructor(address liquiditywallet , address marketingwallet)ERC20("HiberBull" , "HBLX"){
        
        __mint(address(this), totalSupply); // mint all to contract first
        _burn(burnAddress , (20 * totalSupply) / 100 ) 
        _transfer(address(this), _liquidityWallet, liquidityAmount); // send 70% to liquidity wallet
        _transfer(address(this), _marketingWallet, marketingAmount); // send 10% to marketing wallet
    
    }
