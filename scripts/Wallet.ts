import { network } from "hardhat";

async function main() {
  const { viem } = await network.connect();
  const [wallet] = await viem.getWalletClients();
  const publicClient = await viem.getPublicClient();

  if (!wallet) throw new Error("No wallet client");
  const account = wallet.account.address;

  console.log("当前账户:", account);

  // 部署 Wallet 合约
  console.log("\n=== 部署 Wallet 合约 ===");
  const walletContract = await viem.deployContract("Wallet");
  const fromBlock = await publicClient.getBlockNumber();
  console.log("Wallet 合约地址:", walletContract.address);

  // 初始状态
  let balance = (await walletContract.read.getBalance([account])) as bigint;
  let totalDeposited = (await walletContract.read.totalDeposited()) as bigint;
  console.log("初始余额:", balance.toString(), "wei");
  console.log("合约总存款:", totalDeposited.toString(), "wei");

  // 存款 1
  const deposit1 = 100000000000000000n; // 0.1 ETH
  console.log("\n=== 存款 0.1 ETH ===");
  const tx1 = await walletContract.write.deposit([], { value: deposit1 });
  await publicClient.waitForTransactionReceipt({ hash: tx1 });

  balance = (await walletContract.read.getBalance([account])) as bigint;
  totalDeposited = (await walletContract.read.totalDeposited()) as bigint;
  console.log("存款后余额:", balance.toString(), "wei");
  console.log("合约总存款:", totalDeposited.toString(), "wei");

  // 存款 2
  const deposit2 = 50000000000000000n; // 0.05 ETH
  console.log("\n=== 再存款 0.05 ETH ===");
  const tx2 = await walletContract.write.deposit([], { value: deposit2 });
  await publicClient.waitForTransactionReceipt({ hash: tx2 });

  balance = (await walletContract.read.getBalance([account])) as bigint;
  totalDeposited = (await walletContract.read.totalDeposited()) as bigint;
  console.log("存款后余额:", balance.toString(), "wei");
  console.log("合约总存款:", totalDeposited.toString(), "wei");

  // 取款
  const withdrawAmount = 50000000000000000n; // 0.05 ETH
  console.log("\n=== 取款 0.05 ETH ===");
  const tx3 = await walletContract.write.withdraw([withdrawAmount]);
  await publicClient.waitForTransactionReceipt({ hash: tx3 });

  balance = (await walletContract.read.getBalance([account])) as bigint;
  totalDeposited = (await walletContract.read.totalDeposited()) as bigint;
  console.log("取款后余额:", balance.toString(), "wei");
  console.log("合约总存款:", totalDeposited.toString(), "wei");

  // 查询 Deposit / Withdraw 事件（演示链上事件查询）
  const depositEvents = await publicClient.getContractEvents({
    address: walletContract.address,
    abi: walletContract.abi,
    eventName: "Deposit",
    fromBlock,
  });
  const withdrawEvents = await publicClient.getContractEvents({
    address: walletContract.address,
    abi: walletContract.abi,
    eventName: "Withdraw",
    fromBlock,
  });

  console.log("\n=== 事件记录 ===");
  console.log("Deposit 事件数:", depositEvents.length);
  depositEvents.forEach((e, i) => {
    const args = e.args as { user: string; amount: bigint; newBalance: bigint };
    console.log(
      `  [${i + 1}] user=${args.user} amount=${args.amount} newBalance=${args.newBalance}`
    );
  });
  console.log("Withdraw 事件数:", withdrawEvents.length);
  withdrawEvents.forEach((e, i) => {
    const args = e.args as { user: string; amount: bigint; newBalance: bigint };
    console.log(
      `  [${i + 1}] user=${args.user} amount=${args.amount} newBalance=${args.newBalance}`
    );
  });

  console.log("\n完成");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
