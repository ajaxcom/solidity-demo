/// <reference types="@nomicfoundation/hardhat-viem" />
import { network } from "hardhat";

async function main() {
  const { viem } = await network.connect();
  const bank = await viem.deployContract("Bank");
  console.log("Bank deployed to:", bank.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});