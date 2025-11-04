// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakeholders {
    function getstakingWallet() external view returns (address);
    function staketokenonemonth(uint256 amount) external;
}
