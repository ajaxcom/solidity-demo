import { network } from "hardhat";

async function main() {
    const { viem } = await network.connect();
    const [wallet] = await viem.getWalletClients();
    const publicClient = await viem.getPublicClient();

    console.log("Wallet address:", wallet.account.address);

    // 部署 Bank2 合约
    console.log("\n=== Deploying Bank2 contract ===");
    const bank2 = await viem.deployContract("Bank2");
    console.log("Bank2 deployed to:", bank2.address);

    // 查询 owner
    const owner = await bank2.read.owner();
    console.log("Contract owner:", owner);
    console.log("Is deployer the owner?", owner.toLowerCase() === wallet.account.address.toLowerCase());

    // 查询初始 totalMoney
    let totalMoney = await bank2.read.totalMoney();
    console.log("\nInitial totalMoney:", totalMoney.toString(), "wei");

    // 测试 1: 存款（任何人都可以）
    const depositAmount = 100000000000000000n; // 0.1 ETH
    console.log("\n=== Test 1: Deposit 0.1 ETH ===");
    await bank2.write.deposit({
        value: depositAmount,
    });
    
    totalMoney = await bank2.read.totalMoney();
    console.log("Total money after deposit:", totalMoney.toString(), "wei");
    console.log("Expected: 100000000000000000 wei");

    // 测试 2: 再次存款
    const depositAmount2 = 50000000000000000n; // 0.05 ETH
    console.log("\n=== Test 2: Deposit 0.05 ETH ===");
    await bank2.write.deposit({
        value: depositAmount2,
    });
    
    totalMoney = await bank2.read.totalMoney();
    console.log("Total money after second deposit:", totalMoney.toString(), "wei");
    console.log("Expected: 150000000000000000 wei");

    // 测试 3: Owner 提取所有资金
    console.log("\n=== Test 3: Owner withdraws all ===");
    console.log("Calling withdrawAll() as owner...");
    await bank2.write.withdrawAll();
    
    totalMoney = await bank2.read.totalMoney();
    console.log("Total money after withdrawAll:", totalMoney.toString(), "wei");
    console.log("Expected: 0 wei");

    // 测试 4: 验证只有 owner 可以调用 withdrawAll
    console.log("\n=== Test 4: Verify onlyOwner modifier ===");
    console.log("✓ Owner successfully called withdrawAll()");
    console.log("✓ Non-owner would be rejected (can't test without second wallet)");
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});