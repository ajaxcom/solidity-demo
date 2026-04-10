/// <reference types="@nomicfoundation/hardhat-viem" />

import { network } from "hardhat";

async function main() {
    const { viem } = await network.connect();
    const [wallet] = await viem.getWalletClients();
    
    console.log("Deploying Log contract...");
    console.log("Deployer:", wallet.account.address);

    const log = await viem.deployContract("Log");
    console.log("Log deployed to:", log.address);

    const owner = await log.read.owner() as `0x${string}`;
    console.log("Owner (showld match deployer):", owner);
    console.log("Deploy match:", owner.toLowerCase() === wallet.account.address.toLowerCase());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});