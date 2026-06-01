// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Hiberbulltoken.sol";
import "../src/Stakeholders.sol";

contract DeployHiberbull is Script {
    function run() external {
        uint256 deployerKey      = vm.envUint("PRIVATE_KEY");
        address airdropWallet    = vm.envAddress("AIRDROP_WALLET");
        address marketingWallet  = vm.envAddress("MARKETING_WALLET");
        uint16  taxFee           = uint16(vm.envUint("TAX_FEE"));
        address deployer         = vm.addr(deployerKey);

        address predictedStaking = vm.computeCreateAddress(deployer, vm.getNonce(deployer) + 1);

        vm.startBroadcast(deployerKey);

        Hiberbulltoken token = new Hiberbulltoken(taxFee, predictedStaking, airdropWallet);

        Stakeholders staking = new Stakeholders(address(token), address(token), marketingWallet);

        token.setAuthorizedCaller(address(staking)); 

        vm.stopBroadcast();

        require(address(staking) == predictedStaking, "Address prediction failed");

        console.log("Token deployed:    ", address(token));
        console.log("Staking deployed:  ", address(staking));
        console.log("Total Supply:      ", token.totalSupply() / 1e18, "HIBER");
        console.log("Airdrop Balance:   ", token.balanceOf(airdropWallet) / 1e18, "HIBER");
    }
}