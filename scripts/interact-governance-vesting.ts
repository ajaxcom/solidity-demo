/// <reference types="@nomicfoundation/hardhat-viem" />
import { network } from "hardhat";
import { encodeFunctionData } from "viem";

async function main() {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();
  const testClient = await viem.getTestClient();
  const [owner1, owner2, owner3, beneficiary, newBeneficiary] = await viem.getWalletClients();

  console.log("owner1:", owner1.account.address);
  console.log("owner2:", owner2.account.address);
  console.log("owner3:", owner3.account.address);
  console.log("beneficiary:", beneficiary.account.address);
  console.log("newBeneficiary:", newBeneficiary.account.address);

  // 1) 部署多签和时间锁
  const multiSig = await viem.deployContract("SimpleMultiSig", [
    [owner1.account.address, owner2.account.address, owner3.account.address],
    2n,
  ]);
  const minDelay = 3600n;
  const timeLock = await viem.deployContract("SimpleTimeLock", [multiSig.address, minDelay]);

  // 2) 部署代币与线性锁仓
  const totalAmount = 1_000_000n * 10n ** 18n;
  const token = await viem.deployContract("MyToken", ["Demo Token", "DMT", totalAmount]);
  const now = BigInt((await publicClient.getBlock()).timestamp);
  const start = now + 60n;
  const duration = 30n * 24n * 60n * 60n;

  const vestingVault = await viem.deployContract("LinearVestingVault", [
    token.address,
    beneficiary.account.address,
    start,
    duration,
    totalAmount,
    timeLock.address,
  ]);
  await token.write.transfer([vestingVault.address, totalAmount]);

  console.log("SimpleMultiSig:", multiSig.address);
  console.log("SimpleTimeLock:", timeLock.address);
  console.log("MyToken:", token.address);
  console.log("LinearVestingVault:", vestingVault.address);

  // 3) 多签调用时间锁 queue，排队 setBeneficiary(newBeneficiary)
  const setBeneficiaryData = encodeFunctionData({
    abi: vestingVault.abi,
    functionName: "setBeneficiary",
    args: [newBeneficiary.account.address],
  });
  const eta = BigInt((await publicClient.getBlock()).timestamp) + minDelay + 10n;
  const queueData = encodeFunctionData({
    abi: timeLock.abi,
    functionName: "queue",
    args: [vestingVault.address, 0n, setBeneficiaryData, eta],
  });

  await multiSig.write.submitTx([timeLock.address, 0n, queueData], { account: owner1.account });
  await multiSig.write.confirmTx([0n], { account: owner1.account });
  await multiSig.write.confirmTx([0n], { account: owner2.account });
  await multiSig.write.executeTx([0n], { account: owner1.account });
  console.log("Queued setBeneficiary op through multisig.");

  // 4) 时间推进后执行时间锁
  await testClient.increaseTime({ seconds: Number(minDelay + 20n) });
  await testClient.mine({ blocks: 1 });
  await timeLock.write.execute([vestingVault.address, 0n, setBeneficiaryData, eta], {
    account: owner3.account,
  });
  console.log("Executed timelock op.");
  console.log("Current beneficiary:", await vestingVault.read.beneficiary());

  // 5) 演示线性释放：推进到 start 之后，调用 release
  const current = BigInt((await publicClient.getBlock()).timestamp);
  if (current < start + 1n) {
    await testClient.increaseTime({ seconds: Number(start + 1n - current) });
    await testClient.mine({ blocks: 1 });
  }
  const releasableBefore = await vestingVault.read.releasable();
  console.log("Releasable before release:", releasableBefore.toString());
  if (releasableBefore > 0n) {
    await vestingVault.write.release({ account: owner1.account });
    console.log("Released once.");
  } else {
    console.log("Nothing releasable yet. Try increasing time and run release again.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
