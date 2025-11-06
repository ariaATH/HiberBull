// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IStakeholders.sol";

contract Hiberbulltoken is ERC20, Ownable {
    IStakeholders private stakeholders;
    // Tax fee and wallet address
    uint16 private taxfee;
    // Tax wallet address
    address private immutable taxWallet ;
    // Airdrop wallet address
    address private immutable AirdropWallet;
    // Wallet tax-free status
    mapping(address => bool) private wallettaxfree;

    constructor(
        uint16 _taxfee , address _stakeholders , address _airdropWallet
    ) ERC20("Hiberbull", "HIBER") Ownable(msg.sender) {
        taxWallet = _stakeholders; 
        taxfee = _taxfee;
        AirdropWallet = _airdropWallet;
        wallettaxfree[AirdropWallet] = true;
        wallettaxfree[msg.sender] = true;
        wallettaxfree[taxWallet] = true;
        _mint(msg.sender, 1000000000 * 10 ** decimals());
        uint256 burnamount  = (totalSupply()* 20)/100;
        _burn(msg.sender, burnamount);
        emit TokensBurned(msg.sender, burnamount);
        transfer(AirdropWallet, (totalSupply() * 10) / 100); // Airdrop 10% of total supply
        emit AirdropCompleted(AirdropWallet, (totalSupply() * 10) / 100);
        
    }
    // Events for burntoken
    event TokensBurned(address indexed from, uint256 amount);
    // Events for airdrop
    event AirdropCompleted(address indexed to, uint256 amount);

    // Events for transfer
    event Transfercompleted(
        address indexed from,
        address indexed to,
        uint256 value
    );

    // Override transfer function to include tax
    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (!wallettaxfree[msg.sender]) {
            _transfer(msg.sender, to, amount - (((amount * taxfee) / 100)*2)/3); // brun 1 % of each txn
            emit Transfercompleted(
                msg.sender,
                to,
                amount - ((amount * taxfee) / 100)
            );
            _transfer(msg.sender, taxWallet, (amount * taxfee) / 100);
        } else {
            _transfer(msg.sender, to, amount);
            emit Transfercompleted(msg.sender, to, amount);
        }
        return true;
    }

    // Override transferFrom function to include tax
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        if (!wallettaxfree[from]) {
            _transfer(from, to, amount - ((amount * taxfee) / 100));
            _transfer(from, taxWallet, (((amount * taxfee) / 100)*2)/3); // burn 1% of each txn
        } else {
            _transfer(from, to, amount);
        }
        return true;
    }

    // Set wallet tax-free status
    function Settaxfreeaddress(address wallet) external onlyOwner {
        wallettaxfree[wallet] = true;
    }

    // Set wallet tax-not-free status
    function SettaxNotfreeaddress(address wallet) external onlyOwner {
        wallettaxfree[wallet] = false;
    }
}
