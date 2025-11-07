// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IHiberbulltoken.sol";

// The interface for the staking rewards contract
// stakeholders get 1/3 of the tax of transactions that monthly get from the users
// The contract allows users to stake their tokens and earn rewards they stake token for 1 month and
// they can claim their rewards after the staking period ends
/// @notice 2/3 of tax we send to this contract 

contract Stakeholders is Ownable {
    // The wallet where staked tokens are held
    address private immutable stakingWallet;
    // The ERC20 token being staked
    IERC20 private immutable token;
    // The stakeholders contract
    IHiberbullToken private immutable Hiberbulltoken;
    // Total amount of tokens staked
    uint256 private totalStaked;
    // Mapping of user addresses to their staked token balances
    mapping(address => uint256) private stakedBalances;
    // Mapping of user addresses to their staking start times
    mapping(address => uint256) private stakingStartTimes;

    error NotEnoughTokens(address user);

    error StakingNotActive(address user);

    error StakingtimeNotEnded(address user);

    event TokensStaked(address indexed user, uint256 amount);

    event ClaimedStakingRewards(address indexed user, uint256 amount);

    constructor(address tokenAddress , address HiberbulltokenAddress) Ownable(msg.sender) {
        stakingWallet = address(this);
        Hiberbulltoken = IHiberbullToken(HiberbulltokenAddress);
        token = IERC20(tokenAddress);
        Hiberbulltoken.settaxfreeaddress(address(this));
    }
    // Stake tokens for one month
    function staketokenonemonth(uint256 amount) external{
        if(token.balanceOf(msg.sender) < amount) {
            revert NotEnoughTokens(msg.sender);
        }
        Hiberbulltoken.settaxfreeaddress(msg.sender);
        token.transferFrom(msg.sender, stakingWallet, amount);
        Hiberbulltoken.settaxNotfreeaddress(msg.sender);
        stakedBalances[msg.sender] += amount;
        stakingStartTimes[msg.sender] = block.timestamp;
        emit TokensStaked(msg.sender, amount);

    }

    function unstaketoken() external {
        if (stakedBalances[msg.sender] == 0) {
            revert StakingNotActive(msg.sender);
        }
        else {
            if (block.timestamp >= stakingStartTimes[msg.sender] + 30 days) {
                uint256 reward = (stakedBalances[msg.sender]);
                stakedBalances[msg.sender] = 0 ;
                token.transfer(msg.sender, reward);
                emit ClaimedStakingRewards(msg.sender, reward);
            }
            else {
                revert StakingtimeNotEnded(msg.sender);
            }
        }
    }
}
