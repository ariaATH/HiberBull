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
    uint256 public liquidityFee = 3; // 3%
    uint256 public marketingfee = 1; // 1%
    address _liquiditywallet;
    address _marketingwallet;
    mapping(address => bool) internal tax_free;

    constructor(
        address _liquiditywallett,
        address _marketingwallett
    ) ERC20("Hiberbull", "HBLX") Ownable(msg.sender) {
        _liquiditywallet = _liquiditywallett;
        _marketingwallet = _marketingwallett;
        uint256 totalSupply = 10000000000 * 10 ** decimals();
        _mint(address(this), totalSupply); // mint all to contract first
        _transfer(address(this), burnAddress, (20 * totalSupply) / 100); // send 20% to burn address
        _transfer(address(this), _liquiditywallet, (totalSupply * 70) / 100); // send 70% to liquidity wallet
        _transfer(address(this), _marketingwallet, (totalSupply * 10) / 100); // send 10% to marketing wallet
    }

    // Override the _update function to implement tax logic , if your address is not tax free
    // you will pay 1% burn, 2% liquidity and 1% marketing fee
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        if (tax_free[from] || from == address(0) || to == address(0)) {
            super._update(from, to, value);
        } else {
            uint256 amount_liquidity = (liquidityFee * value) / 100; // 2% for holders and 2% for marketing
            uint256 amount_burn = (burnFee * value) / 100; // 1% for burn
            uint256 amount_marketing = (marketingfee * value) / 100; // 1% for marketing
            value -= (amount_burn + amount_liquidity);
            super._update(from, _liquiditywallet, amount_liquidity);
            super._burn(from, amount_burn);
            super._update(from, _marketingwallet, amount_marketing);
            super._update(from, to, value);
        }
    }

    function isTaxFree(address _address) external view returns (bool) {
        return tax_free[_address];
    }

    function setTaxFree(address _address, bool _status) external onlyOwner {
        tax_free[_address] = _status;
    }

    function setBurnFee(uint256 _burnFee) external onlyOwner {
        burnFee = _burnFee;
    }

    function setLiquidityFee(uint256 _liquidityFee) external onlyOwner {
        liquidityFee = _liquidityFee;
    }

    function setMarketingFee(uint256 _marketingFee) external onlyOwner {
        marketingfee = _marketingFee;
    }

    function setLiquidityWallet(address liquiditywallet) external onlyOwner {
        _liquiditywallet = liquiditywallet;
    }

    function setMarketingWallet(address marketingwallet) external onlyOwner {
        _marketingwallet = marketingwallet;
    }

    function getLiquidityWallet() external view returns (address) {
        return _liquiditywallet;
    }

    function getMarketingWallet() external view returns (address) {
        return _marketingwallet;
    }
}
