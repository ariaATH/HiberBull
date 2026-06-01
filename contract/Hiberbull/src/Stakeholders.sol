// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IHiberbulltoken.sol";

contract Stakeholders is Ownable {
    IERC20 private immutable token;
    IHiberbullToken private immutable hiberbullToken;
    address private immutable marketingWallet;

    uint256 private totalStaked;
    uint256 private lastRewardTime;
    uint256 private accRewardPerShare;

    uint256 private constant PRECISION = 1e18;

    mapping(address => uint256) private stakedBalances;
    mapping(address => uint256) private stakingStartTimes;
    mapping(address => uint256) private rewardDebt;
    mapping(address => bool) private isStakeholder;

    error NotEnoughTokens(address user);
    error StakingTimeNotEnded(address user);
    error NotAStakeholder(address user);
    error NoRewardsAvailable();
    error RewardCooldownNotMet();

    modifier timerewardpass() {
        if (block.timestamp < lastRewardTime + 30 days) revert RewardCooldownNotMet();
        _;
    }

    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 holderReward, uint256 marketingReward);

    constructor(address tokenAddress, address hiberbullTokenAddress, address _marketingWallet)
        Ownable(msg.sender)
    {
        token           = IERC20(tokenAddress);
        hiberbullToken  = IHiberbullToken(hiberbullTokenAddress);
        marketingWallet = _marketingWallet;
        lastRewardTime  = block.timestamp;
    }

    function pendingReward(address user) public view returns (uint256) {
        if (stakedBalances[user] == 0) return 0;
        return (stakedBalances[user] * accRewardPerShare / PRECISION) - rewardDebt[user];
    }

    function staketokenonemonth(uint256 amount) external {
        if (token.balanceOf(msg.sender) < amount) revert NotEnoughTokens(msg.sender);

        uint256 pending = pendingReward(msg.sender);
        if (pending > 0) {
            rewardDebt[msg.sender] = stakedBalances[msg.sender] * accRewardPerShare / PRECISION;
            token.transfer(msg.sender, pending);
            emit RewardsClaimed(msg.sender, pending);
        }

        hiberbullToken.settaxfreeaddress(msg.sender);
        token.transferFrom(msg.sender, address(this), amount);
        hiberbullToken.settaxNotfreeaddress(msg.sender);

        isStakeholder[msg.sender]       = true;
        totalStaked                     += amount;
        stakedBalances[msg.sender]      += amount;
        stakingStartTimes[msg.sender]   = block.timestamp;
        rewardDebt[msg.sender]          = stakedBalances[msg.sender] * accRewardPerShare / PRECISION;

        emit TokensStaked(msg.sender, amount);
    }

    function unstaketoken() external {
        if (!isStakeholder[msg.sender]) revert NotAStakeholder(msg.sender);
        if (block.timestamp < stakingStartTimes[msg.sender] + 30 days) {
            revert StakingTimeNotEnded(msg.sender);
        }

        uint256 pending = pendingReward(msg.sender);
        uint256 staked  = stakedBalances[msg.sender];

        totalStaked                   -= staked;
        stakedBalances[msg.sender]    = 0;
        rewardDebt[msg.sender]        = 0;
        isStakeholder[msg.sender]     = false;
        stakingStartTimes[msg.sender] = 0;

        uint256 totalOut = staked + pending;
        token.transfer(msg.sender, totalOut);

        if (pending > 0) emit RewardsClaimed(msg.sender, pending);
        emit TokensUnstaked(msg.sender, staked);
    }

    function claimRewards() external {
        if (!isStakeholder[msg.sender]) revert NotAStakeholder(msg.sender);

        uint256 pending = pendingReward(msg.sender);
        if (pending == 0) revert NoRewardsAvailable();

        rewardDebt[msg.sender] = stakedBalances[msg.sender] * accRewardPerShare / PRECISION;
        token.transfer(msg.sender, pending);

        emit RewardsClaimed(msg.sender, pending);
    }

    function rewardholders(uint256 totalTax) external onlyOwner timerewardpass {
        if (totalStaked == 0) revert NoRewardsAvailable();
        if (token.balanceOf(address(this)) < totalTax) revert NotEnoughTokens(address(this));

        uint256 holderReward    = totalTax / 2;
        uint256 marketingReward = totalTax - holderReward;

        accRewardPerShare += (holderReward * PRECISION) / totalStaked;
        token.transfer(marketingWallet, marketingReward);

        lastRewardTime = block.timestamp;

        emit RewardsDistributed(holderReward, marketingReward);
    }

    function getStakedBalance() external view returns (uint256) {
        return stakedBalances[msg.sender];
    }

    function getPendingReward() external view returns (uint256) {
        return pendingReward(msg.sender);
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    function getLastRewardTime() external view returns (uint256) {
        return lastRewardTime;
    }

    function getstakingWallet() external view returns (address) {
        return address(this);
    }
}