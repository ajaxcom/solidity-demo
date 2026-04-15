///<reference types="@nomicfoundation/hardhat-viem" />
import { network } from "hardhat";

async function main() {
    const { viem } = await network.connect();
    const [owner1, owner2, owner3, beneficiary] = await viem.getWalletClients();

    // 部署多签
    const multiSig = await viem.deployContract("SimpleMultiSig", [
        [owner1.account.address, owner2.account.address, owner3.account.address],
        2n,
    ]);

    // 部署时间锁(admin=多签，最小延迟 1 小时)
    const minDelay = 3600n;
    const timeLock = await viem.deployContract("TimeLock", [multiSig.address, minDelay]);

    // 部署代币
    const totalAmount = 1_000_000n * 10n ** 18n;
    const token = await viem.deployContract("MyToken", ["Demo Token", "DMT", totalAmount]);

    // 链接ETH网络，获取最新区块
    const publicClient = await viem.getPublicClient();
    const latestBlock = await publicClient.getBlock();

    const start = BigInt(latestBlock.timestamp) + 120n; // 2分钟后开始
    const duration = daysToSeconds(180n); // 180天

    // 部署线性锁仓
    const vestingVault = await viem.deployContract("LinearVesting", [
        token.address,
        beneficiary.account.address,
        timeLock.address,
        start,
        duration,
        totalAmount,
    ])

    // 把锁仓总额转入金库
    await token.write.transfer([vestingVault.address, totalAmount]);

    console.log("SimpleMultiSig:", multiSig.address);
    console.log("SimpleTimeLock:", timeLock.address);
    console.log("MyToken:", token.address);
    console.log("LinearVestingVault:", vestingVault.address);
    console.log("beneficiary:", beneficiary.account.address);
    console.log("start:", start.toString());
    console.log("duration(seconds):", duration.toString());
    console.log("latestBlockNumber:", latestBlock.number?.toString?.() ?? String(latestBlock.number));
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

function daysToSeconds(days: bigint): bigint {
    return days * 24n * 60n *60n;
}