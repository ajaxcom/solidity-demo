/// <reference types="@nomicfoundation/hardhat-viem" />

import { network } from "hardhat";

async function main() {
    const { viem } = await network.connect();
    const [wallet] = await viem.getWalletClients();

    console.log("Deploying Bank2 contract...");
    console.log("Wallet address:", wallet.account.address);

    // 部署
    const bank2 = await viem.deployContract("Bank2");
    console.log("Bank2 deployed to:", bank2.address);

    // 验证
    const owner = await bank2.read.owner();
    console.log("Contract owner:", owner);
    console.log("Owner matches deployer:", owner.toLowerCase() === wallet.account.address.toLowerCase());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});