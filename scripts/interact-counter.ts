import { network } from "hardhat";

async function main() {
    const { viem } = await network.connect();
    const [wallet] = await viem.getWalletClients();

    console.log("Wallet address:", wallet.account.address);

    // 部署合约
    console.log("\n=== Deploying SimpleCounter ===");
    const counter = await viem.deployContract("SimpleCounter");
    console.log("Contract deployed to:", counter.address);

    // 查看初始值
    let count = await counter.read.count();
    console.log("Initial count:", count.toString());

    // 增加计数
    console.log("\n=== Incrementing count ===");
    await counter.write.increment();
    count = await counter.read.count();
    console.log("Count after increment:", count.toString());

    // 再次增加
    await counter.write.increment();
    count = await counter.read.count();
    console.log("Count after second increment:", count.toString());

    // Owner 重置
    console.log("\n=== Owner resets count ===");
    await counter.write.reset();
    count = await counter.read.count();
    console.log("Count after reset:", count.toString());

    // Owner 设置值
    console.log("\n=== Owner sets count to 50 ===");
    await counter.write.setCount([50n]);
    count = await counter.read.count();
    console.log("Count after setCount(50):", count.toString());

    // 测试错误：尝试设置超过 100 的值
    console.log("\n=== Testing error: setCount(200) ===");
    try {
        await counter.write.setCount([200n]);
    } catch (error: any) {
        console.log("✓ Error caught:", error.message);
        console.log("✓ This is expected - count cannot exceed 100");
    }
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});