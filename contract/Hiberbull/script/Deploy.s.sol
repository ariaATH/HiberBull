// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Hiberbulltoken.sol";
import "../src/Stakeholders.sol";

contract DeployHiberbull is Script {
    function run() external {
        uint256 deployerKey     = vm.envUint("PRIVATE_KEY");
        address airdropWallet   = vm.envAddress("AIRDROP_WALLET");
        address marketingWallet = vm.envAddress("MARKETING_WALLET");
        uint16  taxFee          = uint16(vm.envUint("TAX_FEE"));
        address deployer        = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        uint64 currentNonce = vm.getNonce(deployer);

        address predictedStaking = vm.computeCreateAddress(deployer, currentNonce + 1);

        Hiberbulltoken token = new Hiberbulltoken(taxFee, predictedStaking, airdropWallet);

        Stakeholders staking = new Stakeholders(
            address(token),
            address(token),
            marketingWallet
        );

    
        require(address(staking) == predictedStaking, "Address prediction failed");

        token.setAuthorizedCaller(address(staking));

        vm.stopBroadcast();

        console.log("Token:   ", address(token));
        console.log("Staking: ", address(staking));
    }
}