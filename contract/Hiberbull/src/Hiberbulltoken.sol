// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "lib/openzeppelin-contracts-5.4.0/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts-5.4.0/contracts/access/Ownable.sol";

contract Hiberbulltoken is ERC20, Ownable {
    constructor() ERC20("Hiberbull", "HIBER") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
