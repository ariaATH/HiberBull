// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Stakeholders is Ownable {
    address private immutable stakingWallet;

    constructor() Ownable(msg.sender) {
        stakingWallet = address(this);
    }

    function getstakingWallet() external view returns (address) {
        return stakingWallet;
    }
}
