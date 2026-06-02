// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Hiberbulltoken.sol";
import "../src/Stakeholders.sol";

contract StakeholdersTest is Test {
    Hiberbulltoken  token;
    Stakeholders    staking;

    address owner          = address(this);
    address user1          = makeAddr("user1");
    address user2          = makeAddr("user2");
    address user3          = makeAddr("user3");
    address airdrop        = makeAddr("airdrop");
    address marketing      = makeAddr("marketing");
    address unauthorized   = makeAddr("unauthorized");

    uint16  constant TAX      = 3;
    uint256 constant DECIMALS = 1e18;
    uint256 constant STAKE_AMOUNT = 1000 * DECIMALS;

    function setUp() public {
        token   = new Hiberbulltoken(TAX, address(this), airdrop);
        staking = new Stakeholders(address(token), address(token), marketing);

        token.setAuthorizedCaller(address(staking));
        token.settaxfreeaddress(address(staking));

        token.transfer(user1, 100_000 * DECIMALS);
        token.transfer(user2, 100_000 * DECIMALS);
        token.transfer(user3, 100_000 * DECIMALS);
        token.transfer(address(staking), 50_000 * DECIMALS);
    }

    function test_StakeTokens() public {
        vm.startPrank(user1);
        token.approve(address(staking), STAKE_AMOUNT);
        staking.staketokenonemonth(STAKE_AMOUNT);
        vm.stopPrank();

        assertEq(staking.getStakedBalance(), 0);

        vm.prank(user1);
        assertEq(staking.getStakedBalance(), STAKE_AMOUNT);
    }

    function test_StakeRequiresEnoughBalance() public {
        vm.startPrank(user1);
        token.approve(address(staking), 200_000 * DECIMALS);
        vm.expectRevert(abi.encodeWithSelector(Stakeholders.NotEnoughTokens.selector, user1));
        staking.staketokenonemonth(200_000 * DECIMALS);
        vm.stopPrank();
    }

    function test_CannotUnstakeBeforeOneMonth() public {
        vm.startPrank(user1);
        token.approve(address(staking), STAKE_AMOUNT);
        staking.staketokenonemonth(STAKE_AMOUNT);

        vm.expectRevert(abi.encodeWithSelector(Stakeholders.StakingTimeNotEnded.selector, user1));
        staking.unstaketoken();
        vm.stopPrank();
    }

    function test_UnstakeAfterOneMonth() public {
        vm.startPrank(user1);
        token.approve(address(staking), STAKE_AMOUNT);
        staking.staketokenonemonth(STAKE_AMOUNT);
        vm.stopPrank();

        uint256 balanceBefore = token.balanceOf(user1);

        vm.warp(block.timestamp + 31 days);

        vm.prank(user1);
        staking.unstaketoken();

        assertEq(token.balanceOf(user1), balanceBefore + STAKE_AMOUNT);
    }

    function test_NotStakeholderCannotUnstake() public {
        vm.prank(unauthorized);
        vm.expectRevert(abi.encodeWithSelector(Stakeholders.NotAStakeholder.selector, unauthorized));
        staking.unstaketoken();
    }

    function test_RewardDistribution() public {
        vm.startPrank(user1);
        token.approve(address(staking), STAKE_AMOUNT);
        staking.staketokenonemonth(STAKE_AMOUNT);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(staking), STAKE_AMOUNT * 3);
        staking.staketokenonemonth(STAKE_AMOUNT * 3);
        vm.stopPrank();

        vm.warp(block.timestamp + 31 days);

        uint256 totalTax = 10_000 * DECIMALS;
        staking.rewardholders(totalTax);

        uint256 holderReward = totalTax / 2;
        uint256 user1Reward  = (holderReward * STAKE_AMOUNT) / (STAKE_AMOUNT * 4);
        uint256 user2Reward  = (holderReward * STAKE_AMOUNT * 3) / (STAKE_AMOUNT * 4);

        assertApproxEqAbs(staking.getPendingReward(), 0, 1);

        vm.prank(user1);
        assertApproxEqAbs(staking.getPendingReward(), user1Reward, 1);

        vm.prank(user2);
        assertApproxEqAbs(staking.getPendingReward(), user2Reward, 1);
    }

    function test_MarketingWalletGetsHalf() public {
        vm.startPrank(user1);
        token.approve(address(staking), STAKE_AMOUNT);
        staking.staketokenonemonth(STAKE_AMOUNT);
        vm.stopPrank();

        vm.warp(block.timestamp + 31 days);

        uint256 totalTax = 10_000 * DECIMALS;
        uint256 mktBefore = token.balanceOf(marketing);

        staking.rewardholders(totalTax);

        assertEq(token.balanceOf(marketing), mktBefore + totalTax / 2);
    }

    function test_ClaimRewards() public {
        vm.startPrank(user1);
        token.approve(address(staking), STAKE_AMOUNT);
        staking.staketokenonemonth(STAKE_AMOUNT);
        vm.stopPrank();

        vm.warp(block.timestamp + 31 days);
        staking.rewardholders(10_000 * DECIMALS);

        uint256 balanceBefore = token.balanceOf(user1);

        vm.prank(user1);
        uint256 pending = staking.getPendingReward();
        vm.prank(user1);
        staking.claimRewards();

        assertEq(token.balanceOf(user1), balanceBefore + pending);
    }

    function test_ClaimRewardsWithUnstake() public {
        vm.startPrank(user1);
        token.approve(address(staking), STAKE_AMOUNT);
        staking.staketokenonemonth(STAKE_AMOUNT);
        vm.stopPrank();

        vm.warp(block.timestamp + 31 days);
        staking.rewardholders(10_000 * DECIMALS);

        vm.prank(user1);
        uint256 pending = staking.getPendingReward();

        uint256 balanceBefore = token.balanceOf(user1);

        vm.prank(user1);
        staking.unstaketoken();

        assertEq(token.balanceOf(user1), balanceBefore + STAKE_AMOUNT + pending);
    }

    function test_RewardCooldown() public {
        vm.startPrank(user1);
        token.approve(address(staking), STAKE_AMOUNT);
        staking.staketokenonemonth(STAKE_AMOUNT);
        vm.stopPrank();

        vm.warp(block.timestamp + 31 days);
        staking.rewardholders(5_000 * DECIMALS);

        vm.expectRevert(Stakeholders.RewardCooldownNotMet.selector);
        staking.rewardholders(5_000 * DECIMALS);
    }

    function test_OnlyOwnerCanReward() public {
        vm.startPrank(user1);
        token.approve(address(staking), STAKE_AMOUNT);
        staking.staketokenonemonth(STAKE_AMOUNT);
        vm.stopPrank();

        vm.warp(block.timestamp + 31 days);

        vm.prank(unauthorized);
        vm.expectRevert();
        staking.rewardholders(5_000 * DECIMALS);
    }

    function test_MultipleStakesAccumulateCorrectly() public {
        vm.startPrank(user1);
        token.approve(address(staking), STAKE_AMOUNT * 2);
        staking.staketokenonemonth(STAKE_AMOUNT);
        staking.staketokenonemonth(STAKE_AMOUNT);
        vm.stopPrank();

        vm.prank(user1);
        assertEq(staking.getStakedBalance(), STAKE_AMOUNT * 2);
    }

    function test_GetTotalStaked() public {
        vm.startPrank(user1);
        token.approve(address(staking), STAKE_AMOUNT);
        staking.staketokenonemonth(STAKE_AMOUNT);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(staking), STAKE_AMOUNT * 2);
        staking.staketokenonemonth(STAKE_AMOUNT * 2);
        vm.stopPrank();

        assertEq(staking.getTotalStaked(), STAKE_AMOUNT * 3);
    }
}