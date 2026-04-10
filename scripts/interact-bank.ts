import { network } from "hardhat";

async function main() {
    const { viem } = await network.connect();
    const [wallet] = await viem.getWalletClients();
    const publicClient = await viem.getPublicClient();

    console.log("Wallet address:", wallet.account.address);

    // 部署 bank
    console.log("\nDeploying Bank contract...");
    const bank = await viem.deployContract("Bank");
    console.log("Bank deployed to:", bank.address);

    const deploymentBlockNumber = await publicClient.getBlockNumber();

    const depositAmount = 100000000000000000n; // 0.1 ETH
    console.log("\nDepositing 0.1 ETH...");

    const depositTx = await bank.write.deposit({
        value: depositAmount,
    });

    // 等待确认
    await publicClient.waitForTransactionReceipt({ hash: depositTx });

    // 查询事件
    const depositEvents = await publicClient.getContractEvents({
        address: bank.address,
        abi: bank.abi,
        eventName: "Deposit",
        fromBlock: deploymentBlockNumber,
        strict: true,
    });

    console.log("\n=== Deposit Events ===");
    for (const event of depositEvents) {
        const { sender, amount } = event.args as { sender: `0x${string}`; amount: bigint };
        console.log(`Account: ${sender}`);
        console.log(`Amount: ${amount.toString()} wei`);
    }

    const balance = await bank.read.getBalance([wallet.account.address]);
    console.log(`Your balance: ${balance.toString()} wei`);

    const withdrawAmount = 50000000000000000n; // 0.05 ETH
    console.log("\nWithdrawing 0.05 ETH...");

    const withdrawTx = await bank.write.withdraw([withdrawAmount]);
    await publicClient.waitForTransactionReceipt({ hash: withdrawTx });

    // 查询事件
    const withdrawEvents = await publicClient.getContractEvents({
        address: bank.address,
        abi: bank.abi,
        eventName: "Withdraw",
        fromBlock: deploymentBlockNumber,
        strict: true,
    });

    console.log("\n=== Withdraw Events ===");
    for (const event of withdrawEvents) {
        const { sender, amount } = event.args as { sender: `0x${string}`; amount: bigint };
        console.log(`Account: ${sender}`);
        console.log(`Amount: ${amount.toString()} wei`);
    }

    const newBalance = await bank.read.getBalance([wallet.account.address]);
    console.log("\nBalance in Bank contract after withdraw:", newBalance.toString(), "wei");
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});