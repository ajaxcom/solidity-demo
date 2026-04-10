import { network } from "hardhat";

async function main() {
    const { viem } = await network.connect();
    const [ownerClient, otherClient] = await viem.getWalletClients();
    const publicClient = await viem.getPublicClient();

    console.log("Owner address:", ownerClient.account.address);
    console.log("Other address:", otherClient.account.address);

    // 部署合约，使用 logContract 避免与 console.log 冲突
    const logContract = await viem.deployContract("Log");
    console.log("Log contract deployed to:", logContract.address);

    console.log("\n=== 1. 添加日志 ===");
    await logContract.write.addRecord(["First entry from owner"]);
    await logContract.write.addRecord(["Second entry from owner"]);
    console.log("Current total:", (await logContract.read.totalRecords() as bigint).toString());

    console.log("\n=== 2. 其他地址添加日志 ===");
    // 修复：account 作为第二个参数（选项对象）
    await logContract.write.addRecord(
        ["Hello from other wallet"],
        { account: otherClient.account }
    );
    console.log("Total records:", (await logContract.read.totalRecords() as bigint).toString());

    console.log("\n=== 3. 查询第一个日志 ===");
    const entry = await logContract.read.getRecord([0n]);
    console.log("Entry 0:", entry);

    console.log("\n=== 4. 删除第一个日志 (仅 owner) ===");
    await logContract.write.deleteRecord([0n]);
    console.log("Total records:", (await logContract.read.totalRecords() as bigint).toString());

    console.log("\n=== 5. 事件监听示例 ===");
    const fromBlock = await publicClient.getBlockNumber();
    await logContract.write.addRecord(["Event demo"]);

    const events = await publicClient.getContractEvents({
        address: logContract.address,
        abi: logContract.abi,
        eventName: "RecordCreated",
        fromBlock: fromBlock,
        strict: true,
    });

    console.log("RecordCreated events since deployment:");
    for (const event of events) {
        const { id, author, message, timestamp } = event.args as {
            id: bigint;
            author: `0x${string}`;
            message: string;
            timestamp: bigint;
        };
        console.log(`  ID: ${id}, Author: ${author}, Message: ${message}, Time: ${timestamp}`);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});