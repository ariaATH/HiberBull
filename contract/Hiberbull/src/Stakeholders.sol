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
    // The last time rewards were distributed by owner
    uint256 private lastRewardTime;
    // Mapping of user addresses to their staked token balances
    mapping(address => uint256) private stakedBalances;
    // Mapping of user addresses to their staking start times
    mapping(address => uint256) private stakingStartTimes;

    mapping(address => bool) private rewardClaimed;

    mapping(address => bool) private isstakeholder;

    address[] private stakeholderswallet;

    error NotEnoughTokens(address user);

    error StakingtimeNotEnded(address user);

    modifier timerewardpass() {
        require(lastRewardTime + 30 days <= block.timestamp, "Staking period not ended");
        _;
    }

    modifier checkholder() {
        require(isstakeholder[msg.sender], "Not a stakeholder");
        _;
    }

    event TokensStaked(address indexed user, uint256 amount);

    event ClaimedStakingRewards(address indexed user, uint256 amount);


    constructor(address tokenAddress , address HiberbulltokenAddress) Ownable(msg.sender) {
        stakingWallet = address(this);
        Hiberbulltoken = IHiberbullToken(HiberbulltokenAddress);
        token = IERC20(tokenAddress);
        Hiberbulltoken.settaxfreeaddress(address(this));
        lastRewardTime = block.timestamp;
    }
    // Stake tokens for one month
    function staketokenonemonth(uint256 amount) external{
        if(token.balanceOf(msg.sender) < amount) {
            revert NotEnoughTokens(msg.sender);
        }
        Hiberbulltoken.settaxfreeaddress(msg.sender);
        token.transferFrom(msg.sender, stakingWallet, amount);
        if(!isstakeholder[msg.sender]) {
            stakeholderswallet.push(msg.sender);
        }
        totalStaked += amount;
        rewardClaimed[msg.sender] = false;
        Hiberbulltoken.settaxNotfreeaddress(msg.sender);
        stakedBalances[msg.sender] += amount;
        stakingStartTimes[msg.sender] = block.timestamp;
        emit TokensStaked(msg.sender, amount);

    }

    function unstaketoken() external checkholder{
            if (rewardClaimed[msg.sender] == true || block.timestamp >= stakingStartTimes[msg.sender] + 30 days) {
                uint256 _stakedtoken = (stakedBalances[msg.sender]);
                stakedBalances[msg.sender] = 0 ;
                totalStaked -= _stakedtoken;
                rewardClaimed[msg.sender] = false;
                isstakeholder[msg.sender] = false;
                token.transfer(msg.sender, _stakedtoken);
                emit ClaimedStakingRewards(msg.sender, _stakedtoken);
            }
            else {
                revert StakingtimeNotEnded(msg.sender);
            }
    }
    // this function owner should call every month and distribute rewards for stakers 1/2 of tax and 1/2 of tax should send to marketing wallet
    function rewardholders(uint256 totaltax) external onlyOwner timerewardpass {
        uint256 _totalstaket = totalStaked;
        lastRewardTime = block.timestamp;
        if (token.balanceOf(address(this)) >= totaltax) {

            uint256 totalrewardforholders = totaltax / 2 ;
            for(uint256 i = 0 ; i < stakeholderswallet.length; i++) {
                address person = stakeholderswallet[i];
                token.transfer(person, (stakedBalances[person] * totalrewardforholders) / _totalstaket);
                rewardClaimed[person] = true;
            }
            stakeholderswallet = new address[](0);
        }
        else {
            revert NotEnoughTokens(address(this));
        }
    }
    // Get the staked balance of each user
    function getStakedBalance() external view returns (uint256) {
        return stakedBalances[msg.sender];
    }

}
