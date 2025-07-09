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
    address public constant burnAddress =
        0x000000000000000000000000000000000000dEaD;
    uint256 public burnFee = 1; // 1%
    uint256 public liquidityFee = 4; // 4%

    constructor(
        address _liquiditywallet,
        address _marketingwallet
    ) ERC20("Hiberbull", "HBLX") Ownable(msg.sender) {
        uint256 totalSupply = 10000000000 * 10 ** decimals();
        _mint(address(this), totalSupply); // mint all to contract first
        _transfer(address(this), burnAddress, (20 * totalSupply) / 100); // send 20% to burn address
        _transfer(address(this), _liquiditywallet, (totalSupply * 70) / 100); // send 70% to liquidity wallet
        _transfer(address(this), _marketingwallet, (totalSupply * 10) / 100); // send 10% to marketing wallet
    }
}
