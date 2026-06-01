// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Hiberbulltoken.sol";

contract HiberbullTokenTest is Test {
    Hiberbulltoken token;

    address owner       = address(this);
    address user1       = makeAddr("user1");
    address user2       = makeAddr("user2");
    address stakeholders = makeAddr("stakeholders");
    address airdrop     = makeAddr("airdrop");
    address unauthorized = makeAddr("unauthorized");

    uint16  constant TAX = 3;
    uint256 constant DECIMALS = 1e18;
    uint256 constant INITIAL_MINT = 1_000_000_000 * DECIMALS;

    function setUp() public {
        token = new Hiberbulltoken(TAX, stakeholders, airdrop);
    }

    function test_TotalSupplyAfterBurn() public {
        uint256 expected = INITIAL_MINT - (INITIAL_MINT * 20) / 100;
        assertEq(token.totalSupply(), expected);
    }

    function test_AirdropWalletBalance() public {
        uint256 supplyAfterBurn = INITIAL_MINT - (INITIAL_MINT * 20) / 100;
        uint256 expectedAirdrop = (supplyAfterBurn * 10) / 100;
        assertEq(token.balanceOf(airdrop), expectedAirdrop);
    }

    function test_OwnerBalanceAfterDeploy() public {
        uint256 supplyAfterBurn = INITIAL_MINT - (INITIAL_MINT * 20) / 100;
        uint256 airdropAmount   = (supplyAfterBurn * 10) / 100;
        uint256 expectedOwner   = supplyAfterBurn - airdropAmount;
        assertEq(token.balanceOf(owner), expectedOwner);
    }

    function test_TaxFreeWalletsOnDeploy() public {
        assertTrue(token.isWalletTaxFree(owner));
        assertTrue(token.isWalletTaxFree(airdrop));
        assertTrue(token.isWalletTaxFree(stakeholders));
    }

    function test_TransferWithTax() public {
        uint256 amount      = 1000 * DECIMALS;
        uint256 totalTax    = (amount * TAX) / 100;
        uint256 taxToWallet = (totalTax * 2) / 3;
        uint256 taxToBurn   = totalTax - taxToWallet;
        uint256 netAmount   = amount - totalTax;

        token.transfer(user1, amount * 10);

        vm.startPrank(user1);
        uint256 supplyBefore   = token.totalSupply();
        uint256 stakeholderBefore = token.balanceOf(stakeholders);

        token.transfer(user2, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(user2), netAmount);
        assertEq(token.balanceOf(stakeholders), stakeholderBefore + taxToWallet);
        assertEq(token.totalSupply(), supplyBefore - taxToBurn);
    }

    function test_TransferTaxFreeOwner() public {
        uint256 amount = 1000 * DECIMALS;
        uint256 supplyBefore = token.totalSupply();

        token.transfer(user1, amount);

        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), supplyBefore);
    }

    function test_TransferFromWithTax() public {
        uint256 amount      = 1000 * DECIMALS;
        uint256 totalTax    = (amount * TAX) / 100;
        uint256 taxToWallet = (totalTax * 2) / 3;
        uint256 taxToBurn   = totalTax - taxToWallet;
        uint256 netAmount   = amount - totalTax;

        token.transfer(user1, amount * 10);

        vm.prank(user1);
        token.approve(user2, amount);

        uint256 supplyBefore      = token.totalSupply();
        uint256 stakeholderBefore = token.balanceOf(stakeholders);

        vm.prank(user2);
        token.transferFrom(user1, user2, amount);

        assertEq(token.balanceOf(user2), netAmount);
        assertEq(token.balanceOf(stakeholders), stakeholderBefore + taxToWallet);
        assertEq(token.totalSupply(), supplyBefore - taxToBurn);
    }

    function test_GetTotalTaxCollected() public {
        uint256 amount   = 1000 * DECIMALS;
        token.transfer(user1, amount * 10);

        vm.prank(user1);
        token.transfer(user2, amount);

        uint256 totalTax    = (amount * TAX) / 100;
        uint256 taxToWallet = (totalTax * 2) / 3;

        uint256 collected = token.getTotalTaxCollected();
        assertEq(collected, taxToWallet);
    }

    function test_GetTotalTaxCollectedResetsCounter() public {
        uint256 amount = 1000 * DECIMALS;
        token.transfer(user1, amount * 10);

        vm.prank(user1);
        token.transfer(user2, amount);

        token.getTotalTaxCollected();
        assertEq(token.getTotalTaxCollected(), 0);
    }

    function test_OnlyOwnerCanGetTax() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        token.getTotalTaxCollected();
    }

    function test_SetTaxFreeAddress() public {
        token.settaxfreeaddress(user1);
        assertTrue(token.isWalletTaxFree(user1));
    }

    function test_SetTaxNotFreeAddress() public {
        token.settaxfreeaddress(user1);
        token.settaxNotfreeaddress(user1);
        assertFalse(token.isWalletTaxFree(user1));
    }

    function test_OnlyOwnerCanSetTaxFree() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        token.settaxfreeaddress(user1);
    }

    function test_SetAuthorizedCaller() public {
        token.setAuthorizedCaller(user1);

        vm.prank(user1);
        token.settaxfreeaddress(user2);
        assertTrue(token.isWalletTaxFree(user2));
    }

    function test_OnlyOwnerCanSetAuthorizedCaller() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        token.setAuthorizedCaller(user1);
    }

    function test_AuthorizedCallerCanSetTaxNotFree() public {
        token.setAuthorizedCaller(user1);

        vm.prank(user1);
        token.settaxNotfreeaddress(owner);
        assertFalse(token.isWalletTaxFree(owner));
    }

    function test_TaxMathIntegrity() public {
        uint256 amount = 1000 * DECIMALS;
        token.transfer(user1, amount * 10);

        uint256 user1Before       = token.balanceOf(user1);
        uint256 user2Before       = token.balanceOf(user2);
        uint256 stakeholderBefore = token.balanceOf(stakeholders);
        uint256 supplyBefore      = token.totalSupply();

        vm.prank(user1);
        token.transfer(user2, amount);

        uint256 user1After       = token.balanceOf(user1);
        uint256 user2After       = token.balanceOf(user2);
        uint256 stakeholderAfter = token.balanceOf(stakeholders);
        uint256 supplyAfter      = token.totalSupply();

        uint256 senderLoss    = user1Before - user1After;
        uint256 receiverGain  = user2After - user2Before;
        uint256 taxWalletGain = stakeholderAfter - stakeholderBefore;
        uint256 burned        = supplyBefore - supplyAfter;

        assertEq(senderLoss, receiverGain + taxWalletGain + burned);
        assertEq(senderLoss, amount);
    }

    function test_GetTaxFee() public {
        assertEq(token.getTaxFee(), TAX);
    }

    function test_GetTaxWallet() public {
        assertEq(token.getTaxWallet(), stakeholders);
    }
}