/// <reference types="@nomicfoundation/hardhat-viem" />
import { network } from "hardhat";

async function main() {
    const { viem } = await network.connect();
    const [wallet] = await viem.getWalletClients();

    // 部署前打印一下地址
    console.log("Deploying EventExample contract...");
    console.log("Deploying address:", wallet.account.address);

    // 部署
    const eventExample = await viem.deployContract("EventExample");
    console.log("EventExample deployed to:", eventExample.address); // sol地址

    // 验证 owner
    const owner = await eventExample.read.owner() as `0x${string}`;
    console.log("Contract owner:", owner);
    console.log("Owner matches deployer:", owner.toLowerCase() === wallet.account.address.toLowerCase());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});