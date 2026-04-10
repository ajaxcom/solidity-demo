import assert from "node:assert/strict";
import { network } from "hardhat";

async function main() {
    const { viem } = await network.connect();
    const [wallet] = await viem.getWalletClients();

    console.log("钱包地址：", wallet.account.address);

    // 部署
    console.log("\n=== 开始部署 ===");
    const library = await viem.deployContract("Library");
    console.log("库合约地址:", library.address);

    // 部署调用合约，传入库合约地址
    console.log("\n=== 部署调用者合约 ===");
    const caller = await viem.deployContract("DelegateCallExample", [
        library.address
    ]);
    console.log("调用者合约地址:", caller.address);

    // 验证初始值
    let value = await caller.read.getValue();
    assert.equal(value, 0n, "初始值应该是 0");
    
    // 设置值
    console.log("")
}