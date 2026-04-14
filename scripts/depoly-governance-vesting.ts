///<reference types="@nomicfoundation/hardhat-viem" />
import { network } from "hardhat";

async function main() {
    const { viem } = await network.connect();
    const [owner1, owner2, owner3, beneficiary] = await viem.getWalletClients();
}