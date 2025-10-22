// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "lib/openzeppelin-contracts-5.4.0/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts-5.4.0/contracts/access/Ownable.sol";

contract Hiberbulltoken is ERC20, Ownable {
    // Tax fee and wallet address
    uint16 private taxfee;
    // Tax wallet address
    address private taxWallet;
    // Wallet tax-free status
    mapping(address => bool) private wallettaxfree;

    constructor(
        address _taxWallet,
        uint16 _taxfee
    ) ERC20("Hiberbull", "HIBER") Ownable(msg.sender) {
        taxWallet = _taxWallet;
        taxfee = _taxfee;
        wallettaxfree[msg.sender] = true;
        wallettaxfree[taxWallet] = true;
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    // Override transfer function to include tax
    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (!wallettaxfree[msg.sender]) {
            _transfer(msg.sender, to, amount - ((amount * taxfee) / 100));
            _transfer(msg.sender, taxWallet, (amount * taxfee) / 100);
        } else {
            _transfer(msg.sender, to, amount);
        }
        return true;
    }
}
