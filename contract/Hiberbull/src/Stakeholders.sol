// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IHiberbulltoken.sol";

// The interface for the staking rewards contract
// stakeholders get 1/3 of the tax of transactions that monthly get from the users
// The contract allows users to stake their tokens and earn rewards they stake token for 1 month and
// they can claim their rewards after the staking period ends

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

    error NotEnoughTokens();

    constructor(address tokenAddress , address stakeholdersAddress) Ownable(msg.sender) {
        stakingWallet = address(this);
        token = IERC20(tokenAddress);
        Hiberbulltoken = IHiberbullToken(stakeholdersAddress);
    }

    function staketokenonemonth(uint256 amount) external{
        if(token.balanceOf(msg.sender) < amount) {
            revert NotEnoughTokens();
        }
        Hiberbulltoken.Settaxfreeaddress(msg.sender);
        token.transferFrom(msg.sender, stakingWallet, amount);


        
    }


}
