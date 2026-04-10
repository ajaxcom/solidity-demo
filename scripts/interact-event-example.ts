import { network } from "hardhat";

async function main() {
    const { viem } = await network.connect();
    const [wallet1, wallet2] = await viem.getWalletClients();
    const publicClient = await viem.getPublicClient();

    console.log("Wallet 1 address:", wallet1.account.address);
    console.log("Wallet 2 address:", wallet2.account.address);

    // 部署合约
    console.log("\n=== Deploying EventExample contract ===");
    const eventExample = await viem.deployContract("EventExample");
    console.log("Contract deployed to:", eventExample.address);

    const deploymentBlockNumber = await publicClient.getBlockNumber();

    // 测试 1: Deposit 事件（带 indexed）
    console.log("\n=== Test 1: Deposit Event (with indexed) ===");
    
    console.log("Wallet1 depositing 1 ETH...");
    await eventExample.write.deposit({
        value: 1000000000000000000n, // 1 ETH
    });

    console.log("Wallet2 depositing 0.5 ETH...");
    // 直接使用 eventExample，在 write 时指定 account
    await eventExample.write.deposit({
        value: 500000000000000000n, // 0.5 ETH
        account: wallet2.account,   // 使用 wallet2 的账户
    });

    // 查询所有 Deposit 事件
    console.log("\n--- All Deposit Events ---");
    const allDepositEvents = await publicClient.getContractEvents({
        address: eventExample.address,
        abi: eventExample.abi,
        eventName: "Deposit",
        fromBlock: deploymentBlockNumber,
        strict: true,
    });

    for (const event of allDepositEvents) {
        const { account, amount, timestamp } = event.args as {
            account: `0x${string}`;
            amount: bigint;
            timestamp: bigint;
        };
        console.log(`  Account: ${account}`);
        console.log(`  Amount: ${amount.toString()} wei`);
        console.log(`  Timestamp: ${timestamp.toString()}`);
    }

    // 查询特定账户的 Deposit 事件（使用 indexed 过滤）
    console.log("\n--- Deposit Events for Wallet1 (filtered by indexed account) ---");
    const wallet1Deposits = await publicClient.getContractEvents({
        address: eventExample.address,
        abi: eventExample.abi,
        eventName: "Deposit",
        args: {
            account: wallet1.account.address,  // ✅ 可以按 indexed 参数过滤
        },
        fromBlock: deploymentBlockNumber,
        strict: true,
    });

    console.log(`Wallet1 的存款次数: ${wallet1Deposits.length}`);
    for (const event of wallet1Deposits) {
        const { account, amount } = event.args as {
            account: `0x${string}`;
            amount: bigint;
        };
        console.log(`  ${account}: ${amount.toString()} wei`);
    }

    // 测试 2: Transfer 事件对比（SimpleTransfer vs IndexedTransfer）
    console.log("\n=== Test 2: Transfer Events Comparison ===");
    
    // 先给 wallet2 一些余额用于转账
    await eventExample.write.deposit({
        value: 200000000000000000n, // 0.2 ETH
        account: wallet2.account,   // 使用 wallet2 的账户
    });

    console.log("Transferring 0.1 ETH from wallet1 to wallet2...");
    await eventExample.write.transfer([wallet2.account.address, 100000000000000000n]);

    // 查询 IndexedTransfer 事件（可以过滤）
    console.log("\n--- IndexedTransfer Events (can filter) ---");
    const indexedTransfers = await publicClient.getContractEvents({
        address: eventExample.address,
        abi: eventExample.abi,
        eventName: "IndexedTransfer",
        args: {
            from: wallet1.account.address,  // ✅ 可以按 indexed from 过滤
        },
        fromBlock: deploymentBlockNumber,
        strict: true,
    });

    console.log(`Wallet1 发起的转账次数: ${indexedTransfers.length}`);
    for (const event of indexedTransfers) {
        const { from, to, amount } = event.args as {
            from: `0x${string}`;
            to: `0x${string}`;
            amount: bigint;
        };
        console.log(`  From: ${from}`);
        console.log(`  To: ${to}`);
        console.log(`  Amount: ${amount.toString()} wei`);
    }

    // 查询 SimpleTransfer 事件（无法过滤）
    console.log("\n--- SimpleTransfer Events (cannot filter) ---");
    const simpleTransfers = await publicClient.getContractEvents({
        address: eventExample.address,
        abi: eventExample.abi,
        eventName: "SimpleTransfer",
        // ❌ 不能按 from/to 过滤，因为没有 indexed
        fromBlock: deploymentBlockNumber,
        strict: true,
    });

    console.log(`所有 SimpleTransfer 事件数量: ${simpleTransfers.length}`);
    for (const event of simpleTransfers) {
        const { from, to, amount } = event.args as {
            from: `0x${string}`;
            to: `0x${string}`;
            amount: bigint;
        };
        console.log(`  From: ${from}`);
        console.log(`  To: ${to}`);
        console.log(`  Amount: ${amount.toString()} wei`);
    }

    // 测试 3: 按接收地址过滤转账
    console.log("\n=== Test 3: Filter Transfers by 'to' address ===");
    const receivedTransfers = await publicClient.getContractEvents({
        address: eventExample.address,
        abi: eventExample.abi,
        eventName: "IndexedTransfer",
        args: {
            to: wallet2.account.address,  // ✅ 可以按 indexed to 过滤
        },
        fromBlock: deploymentBlockNumber,
        strict: true,
    });

    console.log(`Wallet2 收到的转账次数: ${receivedTransfers.length}`);
    for (const event of receivedTransfers) {
        const { from, to, amount } = event.args as {
            from: `0x${string}`;
            to: `0x${string}`;
            amount: bigint;
        };
        console.log(`  收到 ${amount.toString()} wei from ${from}`);
    }

    // 测试 4: ComplexEvent（多个 indexed 参数）
    console.log("\n=== Test 4: ComplexEvent (multiple indexed parameters) ===");
    
    await eventExample.write.createTask([
        1n,
        "work",
        "Complete the project",
        1000n,
    ]);

    await eventExample.write.createTask([
        2n,
        "personal",
        "Buy groceries",
        500n,
    ]);

    // 查询所有 ComplexEvent
    console.log("\n--- All ComplexEvents ---");
    const allComplexEvents = await publicClient.getContractEvents({
        address: eventExample.address,
        abi: eventExample.abi,
        eventName: "ComplexEvent",
        fromBlock: deploymentBlockNumber,
        strict: true,
    });

    for (const event of allComplexEvents) {
        const { User, taskId, category, description, value } = event.args as {
            User: `0x${string}`;
            taskId: bigint;
            category: string;
            description: string;
            value: bigint;
        };
        console.log(`  User: ${User}`);
        console.log(`  Task ID: ${taskId}`);
        console.log(`  Category: ${category}`);
        console.log(`  Description: ${description}`);
        console.log(`  Value: ${value.toString()}`);
    }

    // 按用户过滤 ComplexEvent
    console.log("\n--- ComplexEvents filtered by User (indexed) ---");
    const userComplexEvents = await publicClient.getContractEvents({
        address: eventExample.address,
        abi: eventExample.abi,
        eventName: "ComplexEvent",
        args: {
            User: wallet1.account.address,  // ✅ 可以按 indexed User 过滤
        },
        fromBlock: deploymentBlockNumber,
        strict: true,
    });

    console.log(`Wallet1 创建的复杂事件数量: ${userComplexEvents.length}`);

    // 按 taskId 过滤
    console.log("\n--- ComplexEvents filtered by taskId (indexed) ---");
    const taskEvents = await publicClient.getContractEvents({
        address: eventExample.address,
        abi: eventExample.abi,
        eventName: "ComplexEvent",
        args: {
            taskId: 1n,  // ✅ 可以按 indexed taskId 过滤
        },
        fromBlock: deploymentBlockNumber,
        strict: true,
    });

    console.log(`Task ID 1 的事件数量: ${taskEvents.length}`);
    for (const event of taskEvents) {
        const { User, taskId, description } = event.args as {
            User: `0x${string}`;
            taskId: bigint;
            description: string;
        };
        console.log(`  Task ${taskId}: "${description}" by ${User}`);
    }

    // 总结
    console.log("\n=== Summary ===");
    console.log("✓ Deposit 事件：可以按 account (indexed) 过滤");
    console.log("✓ IndexedTransfer 事件：可以按 from/to (indexed) 过滤");
    console.log("✓ SimpleTransfer 事件：无法过滤（没有 indexed）");
    console.log("✓ ComplexEvent 事件：可以按 User/taskId/category (indexed) 过滤");
    console.log("\n关键区别：");
    console.log("  - indexed 参数：可以过滤，查询效率高");
    console.log("  - 非 indexed 参数：无法过滤，只能读取所有事件后筛选");
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});