// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IStakeholders {
    function getstakingWallet() external view returns (address);
    function staketokenonemonth(uint256 amount) external;
    function unstaketoken() external;
    function claimRewards() external;
    function getPendingReward() external view returns (uint256);
    function getStakedBalance() external view returns (uint256);
    function getTotalStaked() external view returns (uint256);
}