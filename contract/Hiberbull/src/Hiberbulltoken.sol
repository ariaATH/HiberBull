// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Hiberbulltoken is ERC20, Ownable {
    uint16 private taxfee;
    address private immutable taxWallet;
    address private immutable airdropWallet;
    address private authorizedCaller;
    uint256 private totalMonthlyTax;

    mapping(address => bool) private taxFreeWallets;

    event TokensBurned(address indexed from, uint256 amount);
    event AirdropCompleted(address indexed to, uint256 amount);
    event TransferCompleted(address indexed from, address indexed to, uint256 value);

    constructor(uint16 _taxfee, address _stakeholders, address _airdropWallet)
        ERC20("Hiberbull", "HIBER")
        Ownable(msg.sender)
    {
        taxWallet    = _stakeholders;
        taxfee       = _taxfee;
        airdropWallet = _airdropWallet;

        taxFreeWallets[_airdropWallet]  = true;
        taxFreeWallets[msg.sender]      = true;
        taxFreeWallets[_stakeholders]   = true;

        _mint(msg.sender, 1_000_000_000 * 10 ** decimals());

        uint256 burnAmount = (totalSupply() * 20) / 100;
        _burn(msg.sender, burnAmount);
        emit TokensBurned(msg.sender, burnAmount);

        uint256 airdropAmount = (totalSupply() * 10) / 100;
        _transfer(msg.sender, _airdropWallet, airdropAmount);
        emit AirdropCompleted(_airdropWallet, airdropAmount);
    }

    modifier onlyAuthorized() {
        require(msg.sender == owner() || msg.sender == authorizedCaller, "Not authorized");
        _;
    }

    function setAuthorizedCaller(address caller) external onlyOwner {
        authorizedCaller = caller;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (!taxFreeWallets[msg.sender]) {
            uint256 totalTax     = (amount * taxfee) / 100;
            uint256 taxToWallet  = (totalTax * 2) / 3;
            uint256 taxToBurn    = totalTax - taxToWallet;
            uint256 netAmount    = amount - totalTax;

            _transfer(msg.sender, to, netAmount);
            _transfer(msg.sender, taxWallet, taxToWallet);
            _burn(msg.sender, taxToBurn);

            totalMonthlyTax += taxToWallet;
            emit TransferCompleted(msg.sender, to, netAmount);
        } else {
            _transfer(msg.sender, to, amount);
            emit TransferCompleted(msg.sender, to, amount);
        }
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _spendAllowance(from, msg.sender, amount);

        if (!taxFreeWallets[from]) {
            uint256 totalTax    = (amount * taxfee) / 100;
            uint256 taxToWallet = (totalTax * 2) / 3;
            uint256 taxToBurn   = totalTax - taxToWallet;
            uint256 netAmount   = amount - totalTax;

            _transfer(from, to, netAmount);
            _transfer(from, taxWallet, taxToWallet);
            _burn(from, taxToBurn);

            totalMonthlyTax += taxToWallet;
        } else {
            _transfer(from, to, amount);
        }
        return true;
    }

    function getTotalTaxCollected() external onlyOwner returns (uint256) {
        uint256 total = totalMonthlyTax;
        totalMonthlyTax = 0;
        return total;
    }

    function settaxfreeaddress(address wallet) external onlyAuthorized {
        taxFreeWallets[wallet] = true;
    }

    function settaxNotfreeaddress(address wallet) external onlyAuthorized {
        taxFreeWallets[wallet] = false;
    }

    function getTaxFee() external view returns (uint16) {
        return taxfee;
    }

    function getTaxWallet() external view returns (address) {
        return taxWallet;
    }

    function isWalletTaxFree(address wallet) external view returns (bool) {
        return taxFreeWallets[wallet];
    }
}